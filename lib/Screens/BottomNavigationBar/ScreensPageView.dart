import 'dart:async';
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:app_buscabus/Constants.dart';
import 'package:app_buscabus/Screens/BottomNavigationBar/MuralScreen.dart';
import 'package:app_buscabus/Screens/BottomNavigationBar/ScreenBus.dart';
import 'package:app_buscabus/Screens/BottomNavigationBar/ScreenMap.dart';
import 'package:app_buscabus/models/Bus.dart';
import 'package:app_buscabus/models/BusStop.dart';
import 'package:app_buscabus/models/Routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter_beacon/flutter_beacon.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// An enum to identify navigation index
enum Navigation { BUS, MAP, MURAL }

List<bool> filterchips = [false, false, false, false];

class NavigationBloc {
  //BehaviorSubject is from rxdart package
  final BehaviorSubject<Navigation> _controller =
      BehaviorSubject.seeded(Navigation.MAP);
  // seeded with inital page value. I'am assuming PAGE_ONE value as initial page.

  //exposing stream that notify us when navigation index has changed
  Stream<Navigation> get currentNavigationIndex => _controller.stream;

  // method to change your navigation index
  // when we call this method it sends data to stream and his listener
  // will be notified about it.
  void changeNavigationIndex(final Navigation option) =>
      _controller.sink.add(option);

  void dispose() => _controller?.close();
}

class CameraPositionBloc {
  final BehaviorSubject<CameraPosition> _controller =
      BehaviorSubject<CameraPosition>();
  Sink<CameraPosition> get input => _controller.sink;
  Stream<CameraPosition> get output => _controller.stream;

  void sendCameraPosition(CameraPosition cameraPosition) async {
    input.add(cameraPosition);
  }

  void dispose() => _controller?.close();
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

class RouteBloc {
  final BehaviorSubject<Routes> _controller = BehaviorSubject<Routes>();
  Sink<Routes> get input => _controller.sink;
  Stream<Routes> get output => _controller.stream;

  void sendBus(Routes route) async {
    input.add(route);
  }

  void dispose() => _controller?.close();
}

class CoordinatesBloc {
  final BehaviorSubject<Map<int,List<LatLng>>> _controller =
      BehaviorSubject<Map<int,List<LatLng>>>();
  Sink<Map<int,List<LatLng>>> get input => _controller.sink;
  Stream<Map<int,List<LatLng>>> get output => _controller.stream;
  Map<int,List<LatLng>> get currentDate => _controller.value;
  void sendCoordinates(Map<int,List<LatLng>> coordinates) async {
    input.add(coordinates);
  }

  
  void dispose() => _controller?.close();
}

class BusStopBloc {
  final BehaviorSubject<BusStop> _controller = BehaviorSubject<BusStop>();
  Sink<BusStop> get input => _controller.sink;
  Stream<BusStop> get output => _controller.stream;

  void sendBus(BusStop busStop) async {
    input.add(busStop);
  }

  void dispose() => _controller?.close();
}

class ScreensPageView extends StatefulWidget {
  @override
  _ScreensPageViewState createState() => _ScreensPageViewState();
}

class _ScreensPageViewState extends State<ScreensPageView> {
  _addListenerPersonLocate() {
    Geolocator.getPositionStream(
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
  final CameraPositionBloc blocCameraPosition = new CameraPositionBloc();
  final FilterBloc blocFilter = new FilterBloc();
  final BusBloc blocBus = new BusBloc();
  final RouteBloc blocRoute = new RouteBloc();
  final CoordinatesBloc blocCoordinates = new CoordinatesBloc();
  final BusStopBloc blocBusStop = new BusStopBloc();
  final PositionBloc blocPosition = new PositionBloc();
  List<Bus> listBuses = new List<Bus>();
  List<BusStop> listBusStops = new List<BusStop>();
  List<BusStop> listTerminals = new List<BusStop>();
  List<Routes> listRoutes = new List<Routes>();
  final List<BitmapDescriptor> myIconsBusStops = new List<BitmapDescriptor>();
  final List<BitmapDescriptor> myIconsBusTerminals =
      new List<BitmapDescriptor>();
  BitmapDescriptor myIconBus;
  BitmapDescriptor myIconPerson;
  String mapStyle;
  final regions = <Region>[];
  StreamSubscription<RangingResult> _streamRanging;
  //StreamSubscription<MonitoringResult> _streamMonitoring;
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
          if (showNotifcation) {
            _showNotification(beacon, result.region.identifier);
            showNotifcation = false;
          }
        });
      }
      // result contains a region, event type and event state
    });
  }

  _monitoringBeacon() {
    //_streamMonitoring =
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

  _loadLists() {
    Future<List<Bus>> futurelistBuses = Bus.getList();
    futurelistBuses.then((List<Bus> buses) {
      setState(() {
        this.listBuses = buses;
      });
    });
    Future<List<Routes>> futurelistRoutes = Routes.getList();
    futurelistRoutes.then((List<Routes> routes) {
      setState(() {
        this.listRoutes = routes;
      });
    });
    Future<List<BusStop>> futurelistBusStops = BusStop.getList();
    futurelistBusStops.then((List<BusStop> busStops) {
      setState(() {
        busStops.removeWhere((element) => element.adress == null);
        this.listBusStops = busStops;
        _separateTerminalsFromBusStops();
      });
    });
  }

  _separateTerminalsFromBusStops() {
    this.listBusStops.removeWhere((element) => element.adress == null);
    for (int i = 0; i < this.listBusStops.length; i++) {
      if (this.listBusStops[i].isTerminal) {
        this.listTerminals.add(this.listBusStops[i]);
        this.listBusStops.removeAt(i);
        i--;
      }
    }
  }

  static Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))
        .buffer
        .asUint8List();
  }

  _loadBitmapDescriptors() {
    for (int i = 1; i < Constants.num_icons; i++) {
      getBytesFromAsset('assets/markers/busStop' + i.toString() + '.png', 64)
          .then((onValue) {
        myIconsBusStops.add(BitmapDescriptor.fromBytes(onValue));
      });

      getBytesFromAsset('assets/markers/terminal' + i.toString() + '.png', 64)
          .then((onValue) {
        myIconsBusTerminals.add(BitmapDescriptor.fromBytes(onValue));
      });
    }
    getBytesFromAsset('assets/markers/bus.png', 64).then((onValue) {
      myIconBus = BitmapDescriptor.fromBytes(onValue);
    });

    getBytesFromAsset('assets/markers/person.png', 64).then((onValue) {
      myIconPerson = BitmapDescriptor.fromBytes(onValue);
    });
  }

  _defineMapStyle() {
    rootBundle.loadString('assets/map_style.txt').then((string) {
      mapStyle = string;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadBitmapDescriptors();
    _defineMapStyle();
    _loadLists();
    _configurateNotifications();
    _addListenerPersonLocate();
    CameraPosition cameraPosition =
        CameraPosition(target: LatLng(-26.89635815, -48.67252082), zoom: 16);
    blocCameraPosition.sendCameraPosition(cameraPosition);
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
    blocRoute.dispose();
    blocBusStop.dispose();
    blocPosition.dispose();
    blocCameraPosition.dispose();
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
    if (listBuses.isEmpty ||
        listRoutes.isEmpty ||
        listBusStops.isEmpty ||
        listTerminals.isEmpty) {
      return Center(
          child: Scaffold(body: Center(child: CircularProgressIndicator())));
    } else {
      busScreen = ScreenBus(
          blocBus: blocBus,
          blocPosition: blocPosition,
          blocCoordinates: blocCoordinates,
          myIconBus: myIconBus,
          myIconPerson: myIconPerson,
          myIconsBusStops: myIconsBusStops,
          myIconsBusTerminals: myIconsBusTerminals,
          mapStyle: mapStyle);
      mapScreen = ScreenMap(
          blocNavigation: blocNavigation,
          blocCameraPosition: blocCameraPosition,
          blocFilter: blocFilter,
          blocBus: blocBus,
          blocPosition: blocPosition,
          blocRoute: blocRoute,
          blocCoordinates: blocCoordinates,
          blocBusStop: blocBusStop,
          listTerminals: listTerminals,
          listBuses: listBuses,
          listBusStops: listBusStops,
          listRoutes: listRoutes,
          myIconBus: myIconBus,
          myIconPerson: myIconPerson,
          myIconsBusStops: myIconsBusStops,
          myIconsBusTerminals: myIconsBusTerminals,
          mapStyle: mapStyle);
      muralScreen = MuralScreen(
          blocBus: blocBus,
          blocNavigation: blocNavigation,
          blocCameraPosition: blocCameraPosition,
          blocFilter: blocFilter,
          blocRoute: blocRoute,
          blocBusStop: blocBusStop,
          listTerminals: listTerminals,
          listBuses: listBuses,
          listBusStops: listBusStops,
          listRoutes: listRoutes);

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
              default:
                return Center(
                    child: Scaffold(
                        body: Center(child: CircularProgressIndicator())));
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
                          label: 'ÔNIBUS'
                          //title: SizedBox.shrink(),
                          ),
                      BottomNavigationBarItem(
                          icon: _buildIcon(MdiIcons.mapMarker, 'MAPA', 1),
                          label: 'MAPA'
                          //title: SizedBox.shrink(),
                          ),
                      BottomNavigationBarItem(
                          icon: _buildIcon(MdiIcons.table, 'MURAL', 2),
                          label: 'MURAL'
                          //title: SizedBox.shrink(),
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
}
