import 'dart:async';

import 'package:app_buscabus/Constants.dart';
import 'package:app_buscabus/Screens/BottomNavigationBar/ScreensPageView.dart';
import 'package:app_buscabus/models/Bus.dart';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:smooth_star_rating/smooth_star_rating.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:badges/badges.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'dart:convert';

class ScreenBus extends StatefulWidget {
  ScreenBus({this.blocBus, this.notifyStream, this.blocPosition});
  final BusBloc blocBus;
  StreamSubscription<List<int>> notifyStream;
  String jsonBLE = "";
  CameraPosition _cameraPosition =
      CameraPosition(target: LatLng(-26.89635815, -48.67252082), zoom: 16);
  Timer timer;
  PositionBloc blocPosition;
  final FlutterBlue flutterBlue = FlutterBlue.instance;
  final List<BluetoothDevice> devicesList = new List<BluetoothDevice>();
  Position personPositon;
  @override
  _ScreenBusState createState() => _ScreenBusState();
}

class _ScreenBusState extends State<ScreenBus> {
  Completer<GoogleMapController> controllerMap = new Completer();
  GoogleMapController mapStyleController;
  final double averageRate = 2.0;
  String startAdress = "Origem da Linha";
  String endAdress = "Destino da Linha";
  double rating = 2.0;
  String mapStyle;
  String eta;
  bool isBusRecognized = true;
  bool isBusBluetoothConnected = false;
  List<String> lines = ["100"];
  bool dataJSON_OK = false;

  var _services;
  var _connectedDevice;
  _defineMapStyle() {
    rootBundle.loadString('assets/map_style.txt').then((string) {
      mapStyle = string;
    });
  }

  _onMapCreated(GoogleMapController controller) async {
    controller.setMapStyle(mapStyle);
    controllerMap.complete(controller); // definindo o controller do mapa
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _scanBLE();
    _defineMapStyle();
  }

  _addDeviceTolist(final BluetoothDevice device) {
    if (!widget.devicesList.contains(device)) {
      setState(() {
        widget.devicesList.add(device);
      });
    }
  }

  _scanBLE() {
    // Start scanning
    widget.flutterBlue.startScan(timeout: Duration(seconds: 4));
    print("Scan devices.....");
    widget.flutterBlue.connectedDevices
        .asStream()
        .listen((List<BluetoothDevice> devices) {
      for (BluetoothDevice device in devices) {
        print("device found: ${device.name}");
        if (lines.contains(device.name)) _addDeviceTolist(device);
      }
    });
    widget.flutterBlue.scanResults.listen((List<ScanResult> results) {
      for (ScanResult result in results) {
        print("device found: ${result.device.name}");
        if (lines.contains(result.device.name)) _addDeviceTolist(result.device);
      }
    });
    // Stop scanning
    widget.flutterBlue.stopScan();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Constants.white_grey,
          leading: IconButton(
            onPressed: () => {},
            icon: Icon(
              Icons.menu,
              color: Constants.accent_blue,
            ),
          )),
      body: StreamBuilder<Object>(
          stream: widget.blocBus.output,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              Bus bus = snapshot.data;
              String nameBusDriver = "";
              double averageRateBusDriver = 0.0;
              String busStopsFromItinerarys = "";
              String startNeighborhood = "Bairro Indisponível",
                  endNeighborhood = "Bairro Indisponível",
                  startStreet = "Rua Indisponível",
                  endStreet = "Rua Indisponível";
              int startBusStopId = -1, endBusStopId = -1;
              String weeks = "";
              String weekendsHolidays = "";
              int routeLenght;
              String line = bus.line.toString();
              if (bus.busDriver != null) {
                nameBusDriver = bus.busDriver.name;
                averageRateBusDriver = bus.busDriver.averageRate;
              }
              if (bus.itinerary != null) {
                if (bus.itinerary.calendar != null) {
                  if (bus.itinerary.calendar.weeks != null) {
                    for (int i = 0;
                        i < bus.itinerary.calendar.weeks.length;
                        i++) {
                      weeks = weeks +
                          bus.itinerary.calendar.weeks[i]
                              .split(':')
                              .toList()
                              .elementAt(0)
                              .toString() +
                          ":" +
                          bus.itinerary.calendar.weeks[i]
                              .split(':')
                              .toList()
                              .elementAt(1)
                              .toString();
                      if (i != bus.itinerary.calendar.weeks.length - 1)
                        weeks = weeks + ' - ';
                    }
                  }
                  if (bus.itinerary.calendar.weekendsHolidays != null) {
                    for (int i = 0;
                        i < bus.itinerary.calendar.weekendsHolidays.length;
                        i++) {
                      weekendsHolidays = weekendsHolidays +
                          bus.itinerary.calendar.weekendsHolidays[i]
                              .split(':')
                              .toList()
                              .elementAt(0)
                              .toString() +
                          ":" +
                          bus.itinerary.calendar.weekendsHolidays[i]
                              .split(':')
                              .toList()
                              .elementAt(1)
                              .toString();
                      if (i !=
                          bus.itinerary.calendar.weekendsHolidays.length - 1)
                        weekendsHolidays = weekendsHolidays + ' - ';
                    }
                  }
                }
                if (bus.itinerary.route != null) {
                  if (bus.itinerary.route.busStops != null) {
                    routeLenght = bus.itinerary.route.busStops.length;
                    if (bus.itinerary.route.busStops[0].adress != null) {
                      startNeighborhood =
                          bus.itinerary.route.busStops[0].adress.neighborhood;
                      startStreet =
                          bus.itinerary.route.busStops[0].adress.street;
                      startBusStopId = bus.itinerary.route.busStops[0].id;
                    }
                    if (bus.itinerary.route.busStops[routeLenght - 1].adress !=
                        null) {
                      endNeighborhood = bus.itinerary.route
                          .busStops[routeLenght - 1].adress.neighborhood;
                      endStreet = bus.itinerary.route.busStops[routeLenght - 1]
                          .adress.street;
                      endBusStopId =
                          bus.itinerary.route.busStops[routeLenght - 1].id;
                    }
                    bus.itinerary.route.busStops.forEach((busList) {
                      busStopsFromItinerarys = busStopsFromItinerarys +
                          busList.id.toString() +
                          ' - ';
                    });
                  }
                }
              }

              return SingleChildScrollView(
                child: Container(
                  color: Constants.white_grey,
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    clipBehavior: Clip.antiAlias,
                    margin: EdgeInsets.all(18),
                    elevation: 2,
                    child: Container(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          _information(averageRateBusDriver, nameBusDriver,
                              line, startNeighborhood, endNeighborhood),
                          _map(startBusStopId, endBusStopId, startStreet,
                              endStreet),
                          _itinerary(weeks, weekendsHolidays)
                        ],
                      ),
                    ),
                  ),
                ),
              );
            } else {
              return Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                color: Constants.white_grey,
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  clipBehavior: Clip.antiAlias,
                  margin: EdgeInsets.all(18),
                  elevation: 2,
                  child: Container(
                    padding: EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _noDataAvailable(),
                    ),
                  ),
                ),
              );
            }
          }),
    );
  }

  _readNotifyJSON(final BluetoothDevice device,
      final BluetoothCharacteristic characteristic) {
    widget.notifyStream = characteristic.value.listen((value) async {
      try {
        String data = latin1.decode(value);
        if (data != 'OK!')
          widget.jsonBLE = widget.jsonBLE + data;
        else {
          //dataJSON_OK = true;
          widget.notifyStream.cancel();
          Map<String, dynamic> jsonData = _deserializableData(widget.jsonBLE);
          Bus bus = Bus.fromJson(jsonData);
          widget.blocBus.sendBus(bus);
        }
      } catch (e) {
        await device.disconnect();
        print(e);
      }
    });
  }

  Future<BluetoothService> _discoveryService(
      final BluetoothDevice device, String uuid) async {
    await device.requestMtu(512);
    print("configurateNotifyJSON");
    try {
      print("cheguei aqui-1");
      List<BluetoothService> services;
      do {
        services = await device.discoverServices().timeout(
            Duration(milliseconds: 100),
            onTimeout: () => <BluetoothService>[]);
        print(".");
      } while (services.length == 0);
      print("Serviço encontrado.");
      for (BluetoothService service in services)
        if (service.uuid.toString().contains(uuid)) return service;
    } catch (e) {
      await device.disconnect();
      print(e);
    }
    print("Nenhum serviço foi descoberto");
    return null;
  }

  BluetoothCharacteristic _discoveryCharacteristc(
      final BluetoothService service, final String uuid) {
    for (BluetoothCharacteristic characteristic in service.characteristics)
      if (characteristic.uuid.toString().contains(uuid)) return characteristic;
    print("Nenhuma caracteristica encontrada");
    return null;
  }

  Map<String, dynamic> _deserializableData(String jsonString) {
    try {
      Map<String, dynamic> jsonData = jsonDecode(jsonString);
      print(jsonData);
      return jsonData;
    } catch (e) {
      print(e);
      return null;
    }
  }

  Widget buttomBluetooth(BluetoothDevice device) {
    return StreamBuilder<Position>(
        stream: widget.blocPosition.output,
        builder: (context, snapshot) {
          return RaisedButton.icon(
              icon: Icon(
                isBusBluetoothConnected
                    ? MdiIcons.bluetoothConnect
                    : MdiIcons.bluetooth,
                color: isBusBluetoothConnected
                    ? Constants.white_grey
                    : Constants.accent_blue,
              ),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18.0),
                  side: BorderSide(color: Constants.accent_blue)),
              color: isBusBluetoothConnected
                  ? Constants.accent_blue
                  : Constants.white_grey,
              label: Text(
                isBusBluetoothConnected
                    ? "ONIBUS CONECTADO"
                    : "CONECTE-SE AO ONIBUS",
                style: TextStyle(
                    fontFamily: 'Roboto',
                    color: isBusBluetoothConnected
                        ? Constants.white_grey
                        : Constants.accent_blue),
              ),
              elevation: 2,
              onPressed: () async {
                setState(() {
                  isBusBluetoothConnected = !isBusBluetoothConnected;
                });
                if (isBusBluetoothConnected) {
                  await device.connect().timeout(Duration(milliseconds: 600),
                      onTimeout: () => <BluetoothDevice>[]);
                  BluetoothService service =
                      await _discoveryService(device, Constants.SERVICE_UUID);
                  _reciveJSON(
                      device,
                      _discoveryCharacteristc(
                          service, Constants.CHARACTERISTIC_UUID_TX));

                  widget.timer = Timer.periodic(
                      Duration(milliseconds: 2000),
                      (Timer t) async => snapshot.hasData
                          ? await _sendCoordinatesBLE(service, snapshot.data)
                          : null);
                } else {
                  widget.timer.cancel();
                  await device.disconnect();
                }
              });
        });
  }

  _reciveJSON(BluetoothDevice device, BluetoothCharacteristic characteristic) {
    characteristic.setNotifyValue(true);
    _readNotifyJSON(device, characteristic);
  }

  _sendCoordinatesBLE(BluetoothService service, Position position) {
    _sendLAT(
        _discoveryCharacteristc(service, Constants.CHARACTERISTIC_UUID_RX_LAT),
        position);
    _sendLONG(
        _discoveryCharacteristc(service, Constants.CHARACTERISTIC_UUID_RX_LONG),
        position);
  }

  _sendLAT(BluetoothCharacteristic characteristic, Position position) {
    List<int> latitude = utf8.encode(position.latitude.toString());
    characteristic.write(latitude, withoutResponse: true);
  }

  _sendLONG(BluetoothCharacteristic characteristic, Position position) {
    List<int> longitude = utf8.encode(position.longitude.toString());
    characteristic.write(longitude, withoutResponse: true);
  }

  ListView _buildListViewOfDevices() {
    List<Container> containers = new List<Container>();
    for (BluetoothDevice device in widget.devicesList) {
      containers.add(
        Container(
          height: 50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  RichText(
                    text: TextSpan(
                        style: TextStyle(
                            fontFamily: 'Roboto', color: Constants.accent_blue),
                        children: [
                          TextSpan(
                            text: 'Linha ',
                          ),
                          TextSpan(
                              text: device.name == ''
                                  ? '(unknown device)'
                                  : device.name,
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ]),
                  )
                  //Text(device.id.toString()),
                ],
              ),
              buttomBluetooth(device)
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(8),
      children: <Widget>[
        ...containers,
      ],
    );
  }

  List<Widget> _noDataAvailable() {
    List<Widget> list = new List<Widget>();
    list = [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text("Nenhum ônibus foi selecionado"),
      ),
      widget.devicesList.length > 0
          ? Expanded(child: _buildListViewOfDevices())
          : Text("ou reconhecido"),
    ];
    return list;
  }

  Widget _information(double averageRate, String nameBusDriver, String line,
      String startNeighborhood, String endNeighborhood) {
    return Container(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            child: Column(
              children: [
                SmoothStarRating(
                  rating: rating,
                  isReadOnly: false,
                  color: Colors.amber,
                  borderColor: Colors.amberAccent,
                  size: 22,
                  filledIconData: Icons.star,
                  halfFilledIconData: Icons.star_half,
                  defaultIconData: Icons.star_border,
                  starCount: 5,
                  allowHalfRating: true,
                  spacing: 2.0,
                  onRated: (value) {
                    print("rating value -> $value");
                    // print("rating value dd -> ${value.truncate()}");
                  },
                ),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  elevation: 2,
                  child: Container(
                    height: 120,
                    width: 120,
                    child: Stack(
                      children: [
                        Center(
                          child: Icon(
                            MdiIcons.account,
                            size: 120,
                            color: Constants.grey_blue.withOpacity(0.2),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Constants.white_grey.withOpacity(0.4),
                              borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(20),
                                  bottomRight: Radius.circular(20)),
                            ),
                            height: 20,
                            width: 120,
                            child: Center(
                                child: Text(
                              averageRate.toString(),
                              style: TextStyle(
                                fontFamily: 'OpenSans',
                                color: averageRate >= 4.0
                                    ? Constants.green.withOpacity(0.5)
                                    : averageRate >= 3 && averageRate < 4
                                        ? Colors.amberAccent.withOpacity(0.5)
                                        : Colors.red.withOpacity(0.5),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                //fontStyle: FontStyle.italic
                              ),
                            )),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 30.0, left: 8),
                  child: Text(nameBusDriver,
                      softWrap: true,
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'Oswald',
                        color: Constants.green,
                      )),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 18, left: 8),
                  child: Text(
                    "Linha " + line,
                    style: TextStyle(
                        color: Constants.green, fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10, left: 8),
                  child: RichText(
                    text: TextSpan(
                        style: TextStyle(fontFamily: 'Abel'),
                        children: [
                          TextSpan(
                              text: startNeighborhood + " - ",
                              style: TextStyle(color: Constants.accent_blue)),
                          TextSpan(
                              text: startNeighborhood,
                              style:
                                  TextStyle(color: Constants.brightness_blue))
                        ]),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _map(int startBusStopId, int endBusStopId, String startStreet,
      String endStreet) {
    return Container(
      margin: EdgeInsets.only(top: 16),
      width: 300,
      height: 300,
      decoration: BoxDecoration(
          color: Constants.white_grey.withOpacity(0.3),
          border: Border.all(width: 1, color: Constants.accent_blue),
          borderRadius: BorderRadius.all(Radius.circular(20))),
      child: Stack(
        children: [
          Column(
            children: [
              Flexible(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    color: Constants.accent_blue,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(19),
                        topRight: Radius.circular(19)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Flexible(
                          flex: 1,
                          child: Padding(
                            padding: const EdgeInsets.only(
                                top: 4, left: 10, bottom: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Icon(
                                  MdiIcons.circleOutline,
                                  size: 12,
                                  color: Constants.white_grey,
                                ),
                                Icon(
                                  MdiIcons.circle,
                                  size: 2,
                                  color: Constants.white_grey,
                                ),
                                Icon(
                                  MdiIcons.circle,
                                  size: 2,
                                  color: Constants.white_grey,
                                ),
                                Icon(MdiIcons.mapMarker,
                                    size: 12, color: Constants.white_grey),
                              ],
                            ),
                          )),
                      Flexible(
                        flex: 6,
                        child: Container(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 16.0, top: 4),
                            child: Column(
                              children: [
                                Container(
                                    margin: EdgeInsets.only(bottom: 4),
                                    padding: EdgeInsets.only(left: 8),
                                    height: 20,
                                    width: 300,
                                    decoration: BoxDecoration(
                                        border: Border.all(
                                            width: 1,
                                            color: Constants.white_grey),
                                        borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(12),
                                            bottomRight: Radius.circular(12))),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        startBusStopId.toString() +
                                            ' - ' +
                                            startStreet,
                                        style: TextStyle(
                                            color: Constants.white_grey,
                                            fontSize: 12),
                                      ),
                                    )),
                                Container(
                                    margin: EdgeInsets.only(bottom: 4),
                                    padding: EdgeInsets.only(left: 8),
                                    height: 20,
                                    width: 300,
                                    decoration: BoxDecoration(
                                        border: Border.all(
                                            width: 1,
                                            color: Constants.white_grey),
                                        borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(12),
                                            bottomRight: Radius.circular(12))),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        endBusStopId.toString() +
                                            ' - ' +
                                            endStreet,
                                        style: TextStyle(
                                            color: Constants.white_grey,
                                            fontSize: 12),
                                      ),
                                    )),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Flexible(
                flex: 8,
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20)),
                  child: Stack(
                    children: [
                      GoogleMap(
                        mapType: MapType.normal,
                        initialCameraPosition: widget._cameraPosition,
                        mapToolbarEnabled: false,
                        onMapCreated: _onMapCreated,
                        myLocationEnabled: false,
                        compassEnabled: false,
                        zoomControlsEnabled: false,
                        gestureRecognizers:
                            <Factory<OneSequenceGestureRecognizer>>[
                          new Factory<OneSequenceGestureRecognizer>(
                            () => new EagerGestureRecognizer(),
                          ),
                        ].toSet(),
                        //markers: widget._allMarkers,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 16.0, bottom: 8.0, top: 4.0),
                        child: Row(
                          children: [
                            Text(
                              "PRÓXIMO PONTO:  ",
                              style: TextStyle(
                                  color: Constants.accent_blue,
                                  fontSize: 8,
                                  fontFamily: 'Lato',
                                  fontStyle: FontStyle.normal,
                                  fontWeight: FontWeight.bold),
                            ),
                            Badge(
                              //labelPadding: EdgeInsets.all(2),
                              shape: BadgeShape.square,
                              padding: EdgeInsets.fromLTRB(2, 0, 2, 0),

                              badgeColor: Constants.white_grey,
                              borderRadius: 16,
                              badgeContent: Text(
                                "15:05",
                                style: TextStyle(
                                    color: Constants.green,
                                    fontFamily: 'Oswald',
                                    fontSize: 10),
                              ),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
            child: Align(
              child: FloatingActionButton(
                backgroundColor: Constants.accent_blue,
                child: Text(
                  "15:05",
                  style: TextStyle(color: Constants.white_grey, fontSize: 12.0),
                ),
                onPressed: null,
                mini: true,
              ),
              alignment: Alignment.bottomRight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _itinerary(String weeks, String weekendsHolidays) {
    return Container(
      margin: EdgeInsets.only(top: 14),
      child: RichText(
          text: TextSpan(
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'Abel',
              ),
              children: [
            TextSpan(
                text: "ITINERÁRIO",
                style: TextStyle(
                    color: Constants.scarlat,
                    fontWeight: FontWeight.normal,
                    fontSize: 18,
                    fontFamily: 'Oswald')),
            TextSpan(text: "\n\n"),
            TextSpan(
                text: 'Horários ',
                style: TextStyle(
                  color: Constants.scarlat,
                )),
            TextSpan(
                text: ' Segunda a Sexta',
                style: TextStyle(
                  color: Constants.accent_blue,
                )),
            TextSpan(text: "\n"),
            TextSpan(
                text: weeks,
                style: TextStyle(
                  height: 2,
                  color: Constants.grey_blue,
                )),
            TextSpan(text: "\n\n"),
            TextSpan(
                text: 'Horários ',
                style: TextStyle(
                  color: Constants.scarlat,
                )),
            TextSpan(
                text: ' Sábado, Domingo e Feriados',
                style: TextStyle(
                  color: Constants.accent_blue,
                )),
            TextSpan(text: "\n"),
            TextSpan(
                text: weekendsHolidays,
                style: TextStyle(
                  height: 2,
                  color: Constants.grey_blue,
                )),
          ])),
    );
  }
}
