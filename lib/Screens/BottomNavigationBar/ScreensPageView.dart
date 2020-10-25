import 'dart:async';

import 'package:app_buscabus/Constants.dart';
import 'package:app_buscabus/Screens/BottomNavigationBar/MuralScreen.dart';
import 'package:app_buscabus/Screens/BottomNavigationBar/ScreenBus.dart';
import 'package:app_buscabus/Screens/BottomNavigationBar/ScreenMap.dart';
import 'package:app_buscabus/models/Bus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter_beacon/flutter_beacon.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// An enum to identify navigation index
enum Navigation { BUS, MAP, MURAL }

List<bool> filterchips = [false, false, false];

class NavigationBloc {
  //BehaviorSubject is from rxdart package
  final BehaviorSubject<Navigation> _navigationController =
      BehaviorSubject.seeded(Navigation.MAP);
  // seeded with inital page value. I'am assuming PAGE_ONE value as initial page.

  //exposing stream that notify us when navigation index has changed
  Stream<Navigation> get currentNavigationIndex => _navigationController.stream;

  // method to change your navigation index
  // when we call this method it sends data to stream and his listener
  // will be notified about it.
  void changeNavigationIndex(final Navigation option) =>
      _navigationController.sink.add(option);

  void dispose() => _navigationController?.close();
}

class PositionBloc {
  final BehaviorSubject<Position> _controller = BehaviorSubject<Position>();
  Sink<Position> get input => _controller.sink;
  Stream<Position> get output => _controller.stream;

  void newPosition(Position position) {
    input.add(position);
  }

  void dispose() => _controller?.close();
}

class FilterBloc {
  final BehaviorSubject<List<bool>> _controller = BehaviorSubject<List<bool>>();
  Sink<List<bool>> get input => _controller.sink;
  Stream<List<bool>> get output => _controller.stream;

  void changeChips(int index, bool value) {
    filterchips[index] = value;
    input.add(filterchips);
  }

  void dispose() => _controller?.close();
}

class BusBloc {
  final BehaviorSubject<Bus> _controller = BehaviorSubject<Bus>();
  Sink<Bus> get input => _controller.sink;
  Stream<Bus> get output => _controller.stream;

  void sendBus(Bus bus) async {
    input.add(bus);
  }

  void dispose() => _controller?.close();
}

class ScreensPageView extends StatefulWidget {
  @override
  _ScreensPageViewState createState() => _ScreensPageViewState();
}

class _ScreensPageViewState extends State<ScreensPageView> {
  _addListenerPersonLocate() {
    getPositionStream(
      desiredAccuracy: LocationAccuracy.high,
      distanceFilter: 10,
      /* forceAndroidLocationManager: true */
    ).listen((Position position) {
      if (position == null) {
        print('Unknown');
      } else {
        blocPosition.newPosition(position);
      }
    });
  }

  final _selectedItemColor = Constants.white_grey;
  final _unselectedItemColor = Constants.accent_blue;
  final _selectedBgColor = Constants.accent_blue;
  final _unselectedBgColor = Constants.white_grey;

  MuralScreen muralScreen;
  ScreenMap mapScreen;
  ScreenBus busScreen;

  int currentIndex = 1;

  final NavigationBloc blocNavigation = new NavigationBloc();
  final FilterBloc blocFilter = new FilterBloc();
  final BusBloc blocBus = new BusBloc();
  final PositionBloc blocPosition = new PositionBloc();
  final regions = <Region>[];
  StreamSubscription<RangingResult> _streamRanging;
  StreamSubscription<MonitoringResult> _streamMonitoring;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      new FlutterLocalNotificationsPlugin();
  bool showNotifcation = true;
  _initializingScanningBeacon() async {
    try {
      // if you want to manage manual checking about the required permissions
      await flutterBeacon.initializeScanning;
      // or if you want to include automatic checking permission
      await flutterBeacon.initializeAndCheckScanning;
    } on PlatformException catch (e) {
      print(e);
      await flutterBeacon.close;
    }
  }

  _rangingBeacon() {
    _streamRanging =
        flutterBeacon.ranging(regions).listen((RangingResult result) {
      if (result.beacons.length > 0) {
        result.beacons.forEach((beacon) {
          if(showNotifcation){
            _showNotification(beacon, result.region.identifier);
          showNotifcation = false;
        }
        });
      }
      // result contains a region, event type and event state
    });
  }

  _monitoringBeacon() {
    _streamMonitoring =
        flutterBeacon.monitoring(regions).listen((MonitoringResult result) {
      flutterLocalNotificationsPlugin.cancel(0);
      // result contains a region, event type and event state
    });
  }

  Future _onSelectNotification(String payload) async {
    this.blocNavigation.changeNavigationIndex(Navigation.BUS);
  }

  Future _showNotification(Beacon beacon, String identifier) async {
    var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
        '0',
        'Ônibus está próximo',
        'A notificação ativa toda vez que um ônibus está a poucos metros de um usuário',
        importance: Importance.max,
        priority: Priority.high);
    var platformChannelSpecifics =
        new NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      '$identifier',
      beacon.accuracy.isInfinite
          ? 'A $identifier está perto de você'
          : 'A $identifier está a ${beacon.accuracy} m de você',
      platformChannelSpecifics,
      payload: 'Default_Sound',
    );
  }

  _configurateNotifications() {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('bus');
    final IOSInitializationSettings initializationSettingsIOS =
        IOSInitializationSettings();
    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: _onSelectNotification);
  }

  @override
  void initState() {
    super.initState();
    _configurateNotifications();
    _addListenerPersonLocate();
    busScreen = ScreenBus(blocBus: blocBus, blocPosition: blocPosition);
    mapScreen = ScreenMap(
      blocNavigation: blocNavigation,
      blocFilter: blocFilter,
      blocBus: blocBus,
      blocPosition: blocPosition,
    );
    muralScreen = MuralScreen(blocFilter: blocFilter);
    _initializingScanningBeacon();
    regions.add(Region(
        identifier: 'Linha 100',
        proximityUUID: Constants.BEACON_UUID,
        major: 1,
        minor: 1));
    _rangingBeacon();
    _monitoringBeacon();
  }

  @override
  void dispose() async {
    super.dispose();
    blocNavigation.dispose();
    blocFilter.dispose();
    blocBus.dispose();
    blocPosition.dispose();
    await flutterBeacon.close;
    _streamRanging.cancel();
  }

  Color _getBgColor(int index) =>
      currentIndex == index ? _selectedBgColor : _unselectedBgColor;

  Color _getItemColor(int index) =>
      currentIndex == index ? _selectedItemColor : _unselectedItemColor;

  Widget _buildIcon(IconData iconData, String text, int index) => Container(
        width: double.infinity,
        height: kBottomNavigationBarHeight,
        child: Material(
          color: _getBgColor(index),
          child: InkWell(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(iconData),
                Text(text,
                    style:
                        TextStyle(fontSize: 12, color: _getItemColor(index))),
              ],
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<Navigation>(
        initialData: Navigation.MAP,
        stream: blocNavigation.currentNavigationIndex,
        builder: (context, snapshot) {
          switch (snapshot.data) {
            case Navigation.BUS:
              return busScreen;
            case Navigation.MAP:
              return mapScreen;
            case Navigation.MURAL:
              return muralScreen;
          }
        },
      ),
      bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                  color: Constants.accent_grey.withOpacity(0.5),
                  spreadRadius: 4,
                  blurRadius: 5,
                  offset: Offset(0, 3))
            ],
          ),
          child: StreamBuilder<Navigation>(
              initialData: Navigation.MAP,
              stream: blocNavigation.currentNavigationIndex,
              builder: (context, snapshot) {
                currentIndex = snapshot.data.index;
                return BottomNavigationBar(
                  onTap: (index) {
                    blocNavigation
                        .changeNavigationIndex(Navigation.values[index]);
                  },
                  selectedFontSize: 0,
                  items: <BottomNavigationBarItem>[
                    BottomNavigationBarItem(
                      icon: _buildIcon(MdiIcons.busSide, 'ÔNIBUS', 0),
                      title: SizedBox.shrink(),
                    ),
                    BottomNavigationBarItem(
                      icon: _buildIcon(MdiIcons.mapMarker, 'MAPA', 1),
                      title: SizedBox.shrink(),
                    ),
                    BottomNavigationBarItem(
                      icon: _buildIcon(MdiIcons.table, 'MURAL', 2),
                      title: SizedBox.shrink(),
                    ),
                  ],
                  currentIndex: currentIndex,
                  selectedItemColor: _selectedItemColor,
                  unselectedItemColor: _unselectedItemColor,
                );
              })),
    );
  }
}
