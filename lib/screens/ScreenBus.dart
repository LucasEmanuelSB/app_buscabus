import 'dart:async';

import 'package:app_buscabus/Blocs.dart';
import 'package:app_buscabus/Constants.dart';
import 'package:app_buscabus/models/Bus.dart';
import 'package:app_buscabus/models/BusStop.dart';
import 'package:app_buscabus/models/Routes.dart';
import 'package:app_buscabus/CameraFunctions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:badges/badges.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'dart:convert';
import 'dart:math' as Math;

class ScreenBus extends StatefulWidget {
  ScreenBus(
      {this.blocBus,
      this.blocPosition,
      this.blocCoordinates,
      this.myIconsBusStops,
      this.myIconsBusTerminals,
      this.myIconBus,
      this.myIconPerson,
      this.mapStyle});

  final BusBloc blocBus;
  final PositionBloc blocPosition;
  final CoordinatesBloc blocCoordinates;

  final List<BitmapDescriptor> myIconsBusStops;
  final List<BitmapDescriptor> myIconsBusTerminals;
  final BitmapDescriptor myIconBus;
  final BitmapDescriptor myIconPerson;
  final String mapStyle;

  @override
  _ScreenBusState createState() => _ScreenBusState();
}

class _ScreenBusState extends State<ScreenBus> {
  Completer<GoogleMapController> controllerMap = new Completer();
  FlutterBlue flutterBlue = FlutterBlue.instance;
  List<BluetoothDevice> devicesList = new List<BluetoothDevice>();
  Set<Marker> busStopsMarkers = {};
  Set<Marker> terminalsMarkers = {};
  Set<Marker> allMarkers = new Set<Marker>();
  Set<Polyline> polylines = {};
  List<LatLng> polylineCoordinates = new List<LatLng>();
  CameraPosition cameraPosition = new CameraPosition(target: new LatLng(0, 0));
  List<String> lines = ["100"];
  String startAdress = "Origem da Linha";
  String endAdress = "Destino da Linha";
  String eta;
  Bus bus = new Bus();
  bool isBusBluetoothConnected = false;
  //bool isDataBLEOK = false;
  Marker busMarker;
  Position personPositon;
  String jsonBLE = "";
  Timer timerRealTimeData;
  Timer timerBLE;
  String routeETA = "0";
  bool isErrorBLE = false;
  bool isBusBluetooth = false;
  BluetoothDevice deviceBus;
  BluetoothService serviceBus;
  BusBloc blocBusBLE = new BusBloc();

  _addPolylinesRoute() async {
    Polyline polyline = Polyline(
        polylineId: PolylineId("Route " + bus.itinerary.route.id.toString()),
        color: Constants.accent_grey,
        points: polylineCoordinates);
    polylines.add(polyline);
  }

  _addMarkerTerminal(BusStop terminal) {
    terminalsMarkers.clear();
    terminalsMarkers.add(new Marker(
        markerId: MarkerId('Terminal ' + terminal.id.toString()),
        infoWindow: InfoWindow(
            title: terminal.adress.neighborhood,
            snippet: terminal.adress.street),
        position: LatLng(terminal.latitude, terminal.longitude),
        icon: widget.myIconsBusTerminals.elementAt(terminal.adress.id - 1)));

    allMarkers = [allMarkers, terminalsMarkers].expand((x) => x).toSet();
  }

  _addMarkersBusStops(List<BusStop> busStops) {
    busStopsMarkers.clear();
    busStops.forEach((element) {
      busStopsMarkers.add(new Marker(
          markerId: MarkerId('BusStop ' + element.id.toString()),
          infoWindow: InfoWindow(
              title: element.adress.neighborhood,
              snippet: element.adress.street),
          position: LatLng(element.latitude, element.longitude),
          icon: widget.myIconsBusStops.elementAt(element.id - 1)));
    });
    allMarkers = [allMarkers, busStopsMarkers].expand((x) => x).toSet();
  }

  _addMarkerBus(Bus bus) {
    if (bus.realTimeData != null) {
      allMarkers.removeWhere((element) => element == busMarker);
      busMarker = new Marker(
          markerId: MarkerId('Bus ' + bus.id.toString()),
          infoWindow: InfoWindow(title: "Linha " + bus.line.toString()),
          position:
              LatLng(bus.realTimeData.latitude, bus.realTimeData.longitude),
          icon: widget.myIconBus /* BitmapDescriptor.defaultMarker */);
    }
  }

  _updateMarkers() {
    _addMarkerTerminal(bus.itinerary.route.start);
    _addMarkerTerminal(bus.itinerary.route.end);
    _addMarkersBusStops(bus.itinerary.route.busStops);
    _addMarkerBus(bus);
  }

  double calculateETA(double distance, double velocity) {
    return (distance / velocity);
  }

  double distanceOnGeoid(double lat1, double lon1, double lat2, double lon2) {
    // Convert degrees to radians
    lat1 = lat1 * Math.pi / 180.0;
    lon1 = lon1 * Math.pi / 180.0;

    lat2 = lat2 * Math.pi / 180.0;
    lon2 = lon2 * Math.pi / 180.0;

    // radius of earth in metres
    double r = 6378100;

    // P
    double rho1 = r * Math.cos(lat1);
    double z1 = r * Math.sin(lat1);
    double x1 = rho1 * Math.cos(lon1);
    double y1 = rho1 * Math.sin(lon1);

    // Q
    double rho2 = r * Math.cos(lat2);
    double z2 = r * Math.sin(lat2);
    double x2 = rho2 * Math.cos(lon2);
    double y2 = rho2 * Math.sin(lon2);

    // Dot product
    double dot = (x1 * x2 + y1 * y2 + z1 * z2);
    double cosTheta = dot / (r * r);

    double theta = Math.acos(cosTheta);

    // Distance in Metres
    return r * theta;
  }

  _updateRealTimeData() {
    bus.updateRealTimeData();
    moveCamera(
        new CameraPosition(
            target:
                LatLng(bus.realTimeData.latitude, bus.realTimeData.longitude),
            zoom: 18,
            tilt: 45),
        controllerMap);
    double lat1 = bus.realTimeData.latitude;
    double lng1 = bus.realTimeData.longitude;
    var markerPosition = LatLng(lat1, lng1);
    String busMarkerId = 'Bus ' + bus.id.toString();
    Marker busMarker = Marker(
        markerId: MarkerId(busMarkerId),
        infoWindow: InfoWindow(
            title: "Linha " + bus.line.toString(),
            snippet: "N° passageiros: " + bus.realTimeData.nDevices.toString()),
        position: markerPosition, // updated position
        icon: widget.myIconBus);

    setState(() {
      allMarkers.removeWhere((m) => m.markerId.value == busMarkerId);
      allMarkers.add(busMarker);
    });

    double lat2 = bus.itinerary.route.end.latitude;
    double lng2 = bus.itinerary.route.end.longitude;

    double distance = distanceOnGeoid(lat1, lng1, lat2, lng2);
    double eta = calculateETA(distance, bus.realTimeData.velocity);

    int secondsDuration = Duration(seconds: eta.truncate()).inSeconds;

    if (secondsDuration > 3600) {
      // hours
      int h = (secondsDuration / 3600).truncate();
      int m = ((secondsDuration % 3600) / 60).truncate();
      setState(() {
        routeETA = h.toString() + "h" + m.toString() + "m";
      });
    } else if (secondsDuration >= 60 && eta < 3600) {
      // minutes
      int m = (secondsDuration / 60).truncate();
      int s = secondsDuration % 60;
      setState(() {
        routeETA = m.toString() + "m" + s.toString() + "s";
      });
    } else if (eta < 60) {
      // seconds
      setState(() {
        routeETA = secondsDuration.toString() + "s";
      });
    }

    print("Latitude: " + bus.realTimeData.latitude.toString());
    print("Longitude: " + bus.realTimeData.longitude.toString());
  }

  _onMapCreated(GoogleMapController controller) async {
    controller.setMapStyle(widget.mapStyle);
    controllerMap.complete(controller); // definindo o controller do mapa
    if (lines.contains(bus.line.toString())) {
      timerRealTimeData = Timer.periodic(
          Duration(seconds: 2), (Timer t) async => await _updateRealTimeData());
    }
  }

  @override
  void initState() {
    super.initState();
    _scanBLE();
  }

  @override
  void dispose() async {
    super.dispose();
    await deviceBus?.disconnect();
    blocBusBLE.dispose();
    timerBLE?.cancel();
    timerRealTimeData?.cancel();
  }

  _addDeviceTolist(final BluetoothDevice device) {
    if (!devicesList.contains(device)) {
      setState(() {
        devicesList.add(device);
      });
    }
  }

  _scanBLE() {
    // Start scanning
    flutterBlue.startScan(timeout: Duration(seconds: 4));
    print("Scan devices.....");
    flutterBlue.connectedDevices
        .asStream()
        .listen((List<BluetoothDevice> devices) {
      for (BluetoothDevice device in devices) {
        print("device found: ${device.name}");
        if (lines.contains(device.name)) _addDeviceTolist(device);
      }
    });
    flutterBlue.scanResults.listen((List<ScanResult> results) {
      for (ScanResult result in results) {
        print("device found: ${result.device.name}");
        if (lines.contains(result.device.name)) _addDeviceTolist(result.device);
      }
    });
    // Stop scanning
    flutterBlue.stopScan();
  }

  _readNotifyJSON(final BluetoothCharacteristic characteristic) {
    characteristic.value.listen((value) async {
      try {
        String data = latin1.decode(value);
        if (data != 'OK!')
          jsonBLE = jsonBLE + data;
        else {
          //widget.notifyStream.cancel();
          Map<String, dynamic> jsonData = _deserializableData(jsonBLE);
          bus = Bus.fromJson(jsonData);
          setState(() {
            //isDataBLEOK = true;
            isBusBluetoothConnected = true;
            isBusBluetooth = true;
            isErrorBLE = false;
          });
          blocBusBLE.sendBus(bus);
          _sendDataBLE();

        }
      } catch (e) {
        print(e);
/*         await deviceBus.disconnect();
        setState(() {
          //isDataBLEOK = false;
          isBusBluetoothConnected = false;
          isBusBluetooth = false;
          isErrorBLE = true;
        }); */
      }
    });
  }

  Future<BluetoothService> _discoveryService(
      final BluetoothDevice device, String uuid) async {
    await device.requestMtu(512);
    print("configurateNotifyJSON");
    try {
      print("cheguei aqui-1");
      List<BluetoothService> services = new List<BluetoothService>();
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

  Widget buttomBluetooth(final BluetoothDevice device) {
    deviceBus = device;
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
          isBusBluetoothConnected ? "ONIBUS CONECTADO" : "CONECTE-SE AO ONIBUS",
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
            try {
              await deviceBus.connect().timeout(Duration(milliseconds: 600),
                  onTimeout: () => <BluetoothDevice>[]);
              isErrorBLE = false;
            } catch (e) {
              isErrorBLE = true;
              await deviceBus.disconnect();
              setState(() {
                isBusBluetoothConnected = false;
              });
              print(e);
            }
            serviceBus =
                await _discoveryService(deviceBus, Constants.SERVICE_UUID);

            _reciveJSON(_discoveryCharacteristc(
                serviceBus, Constants.CHARACTERISTIC_UUID_TX));
          } else {
            timerBLE.cancel();
            await deviceBus.disconnect();
          }
        });
  }

  _sendDataBLE() async {
    timerBLE = Timer.periodic(
        Duration(seconds: 3),
        (Timer t) async => await _sendCoordinatesBLE(
            serviceBus, widget.blocPosition.currentPosition));
  }

  _reciveJSON(BluetoothCharacteristic characteristic) {
    characteristic.setNotifyValue(true);
    _readNotifyJSON(characteristic);
  }

  _sendCoordinatesBLE(final BluetoothService service, final Position position) {
    _sendLAT(
        _discoveryCharacteristc(service, Constants.CHARACTERISTIC_UUID_RX_LAT),
        position);
    _sendLONG(
        _discoveryCharacteristc(service, Constants.CHARACTERISTIC_UUID_RX_LONG),
        position);
  }

  _sendLAT(final BluetoothCharacteristic characteristic,
      final Position position) async {
    List<int> latitude = utf8.encode(position.latitude.toString());
    try {
      await characteristic.write(latitude, withoutResponse: true);
    } catch (e) {
      print(e);
    }
  }

  _sendLONG(final BluetoothCharacteristic characteristic,
      final Position position) async {
    List<int> longitude = utf8.encode(position.longitude.toString());
    try {
      await characteristic.write(longitude, withoutResponse: true);
    } catch (e) {
      print(e);
    }
  }

  List<Widget> _noDataAvailable() {
    List<Widget> list = new List<Widget>();
    list = [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text("Nenhum ônibus foi selecionado"),
      ),
      devicesList.length > 0
          ? Expanded(child: _buildListViewOfDevices())
          : Text("ou reconhecido"),
    ];
    return list;
  }

  Widget _items(Routes route) {
    return Wrap(
      runSpacing: 4,
      alignment: WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.center,
      direction: Axis.horizontal,
      children: _generateRouteIcons(route.start, route.end, route.busStops),
    );
  }

  List<Widget> _generateRouteIcons(
      BusStop start, BusStop end, List<BusStop> path) {
    List<Widget> children = [];
    for (int i = 0; i < path.length + 2; i++) {
      BusStop busStop;
      if (i == 0) {
        busStop = start;
      } else if (i == path.length + 1) {
        busStop = end;
      } else
        busStop = path[i - 1];
      children.add(Padding(
          padding: const EdgeInsets.all(1.0),
          child: Badge(
            alignment: Alignment.center,
            child: i == 0 || (i == path.length + 1)
                ? new Badge(
                    shape: BadgeShape.square,
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    /* padding: EdgeInsets.all(16), */
                    badgeContent: Text(busStop.adress.neighborhood,
                        style: TextStyle(
                            color: Constants.accent_blue,
                            fontWeight: FontWeight.bold)),
                    badgeColor: Constants.white_grey,
                  )
                : null,
            shape: i == 0 || i == (path.length + 1)
                ? BadgeShape.circle
                : BadgeShape.circle,
            padding: busStop.id < 10 ? EdgeInsets.all(6) : EdgeInsets.all(3),
            badgeContent: Text(
              i == 0 || i == (path.length + 1)
                  ? busStop.id.toString()
                  : busStop.id.toString(),
              style: TextStyle(
                  color: Constants.white_grey,
                  fontSize: 12,
                  fontWeight: FontWeight.bold),
            ),
            badgeColor: busStop.isTerminal
                ? Constants.accent_blue
                : Constants.brightness_blue,
          )));
      if (i != path.length + 1)
        children.add(Padding(
          padding: const EdgeInsets.all(4.0),
          child: new Icon(
            MdiIcons.arrowRightThick,
            color: Constants.accent_grey,
            size: 15,
          ),
        ));
    }
    return children;
  }

  Widget _route(Bus bus) {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
            child: Text("ROTA",
                style: TextStyle(
                    color: Constants.accent_blue,
                    fontWeight: FontWeight.normal,
                    fontSize: 18,
                    fontFamily: 'Oswald')),
          ),
          _items(bus.itinerary.route),
        ],
      ),
    );
  }

  Widget _map(Bus bus, int startBusStopId, int endBusStopId, String startStreet,
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
                        initialCameraPosition: cameraPosition,
                        mapToolbarEnabled: false,
                        onMapCreated: _onMapCreated,
                        myLocationEnabled: false,
                        compassEnabled: false,
                        zoomControlsEnabled: false,
                        markers: allMarkers,
                        polylines: polylines,
                        gestureRecognizers:
                            <Factory<OneSequenceGestureRecognizer>>[
                          new Factory<OneSequenceGestureRecognizer>(
                            () => new EagerGestureRecognizer(),
                          ),
                        ].toSet(),
                      ),
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
                  routeETA,
                  style: TextStyle(color: Constants.white_grey, fontSize: 8.0),
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

  Widget _information(
      String nameBusDriver,
      String line,
      String startNeighborhood,
      String endNeighborhood,
      int startId,
      int endId) {
    return Container(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            child: Column(
              children: [
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
                  padding: const EdgeInsets.fromLTRB(4, 0, 0, 0),
                  child: Text(nameBusDriver,
                      softWrap: true,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        fontFamily: 'Abel',
                        color: Constants.accent_blue,
                      )),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 0, 0),
                  child: Text(
                    "LINHA " + line,
                    style: TextStyle(
                        color: Constants.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 0, 0),
                  child: Row(
                    children: [
                      Badge(
                        badgeContent: Text(
                          startId.toString(),
                          style: TextStyle(color: Constants.white_grey),
                        ),
                        badgeColor: Constants.accent_blue,
                        padding: startId < 10
                            ? EdgeInsets.all(6)
                            : EdgeInsets.all(3),
                      ),
                      SizedBox(width: 6),
                      RichText(
                        text: TextSpan(
                            style: TextStyle(fontFamily: 'Abel', fontSize: 16),
                            children: [
                              TextSpan(
                                  text: "Terminal ",
                                  style: TextStyle(
                                    color: Constants.accent_blue,
                                  )),
                              TextSpan(
                                  text: startNeighborhood,
                                  style: TextStyle(
                                      color: Constants.scarlat,
                                      fontWeight: FontWeight.bold))
                            ]),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 0, 0),
                  child: Row(
                    children: [
                      Badge(
                        badgeContent: Text(
                          endId.toString(),
                          style: TextStyle(color: Constants.white_grey),
                        ),
                        badgeColor: Constants.accent_blue,
                        padding:
                            endId < 10 ? EdgeInsets.all(6) : EdgeInsets.all(3),
                      ),
                      SizedBox(width: 6),
                      RichText(
                        text: TextSpan(
                            style: TextStyle(fontFamily: 'Abel', fontSize: 16),
                            children: [
                              TextSpan(
                                  text: "Terminal ",
                                  style: TextStyle(
                                    color: Constants.accent_blue,
                                  )),
                              TextSpan(
                                  text: endNeighborhood,
                                  style: TextStyle(
                                      color: Constants.scarlat,
                                      fontWeight: FontWeight.bold))
                            ]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  ListView _buildListViewOfDevices() {
    List<Container> containers = new List<Container>();
    for (BluetoothDevice device in devicesList) {
      containers.add(
        Container(
          height: 600,
          child: Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    RichText(
                      text: TextSpan(
                          style: TextStyle(
                              fontFamily: 'Roboto',
                              color: Constants.accent_blue),
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
                    ),
                    buttomBluetooth(device),
                    isBusBluetoothConnected
                        ? CircularProgressIndicator()
                        : SizedBox(),
                  ],
                ),
                isErrorBLE == true && !isBusBluetoothConnected
                    ? Center(
                        child: Text("Erro, tente novamente."),
                      )
                    : SizedBox(
                        height: 0,
                      ),
              ],
            ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Constants.white_grey,
      ),
      body: StreamBuilder<Bus>(
          stream: isBusBluetooth ? blocBusBLE.output : widget.blocBus.output,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              if (bus.realTimeData != null) {
                cameraPosition = CameraPosition(
                    target: LatLng(
                        bus.realTimeData.latitude, bus.realTimeData.longitude));
              }
              bus = snapshot.data;
              if (!isBusBluetooth && !isBusBluetoothConnected) {
                polylineCoordinates =
                    widget.blocCoordinates.currentDate[bus.itinerary.route.id];
                _updateMarkers();
                _addPolylinesRoute();
              }
              String nameBusDriver = "";
              String busStopsFromItinerarys = "";
              int startId = 0, endId = 0;
              String startNeighborhood = "Bairro Indisponível",
                  endNeighborhood = "Bairro Indisponível",
                  startStreet = "Rua Indisponível",
                  endStreet = "Rua Indisponível";
              int startBusStopId = -1, endBusStopId = -1;
              String weeks = "";
              String weekendsHolidays = "";
              String line = bus.line.toString();
              if (bus.busDriver != null) {
                nameBusDriver = bus.busDriver.name;
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
                    if (bus.itinerary.route.start.adress.neighborhood != null) {
                      startId = bus.itinerary.route.start.id;
                      startNeighborhood =
                          bus.itinerary.route.start.adress.neighborhood;
                      startStreet = bus.itinerary.route.start.adress.street;
                      startBusStopId = bus.itinerary.route.start.id;
                    }
                    if (bus.itinerary.route.end.adress != null) {
                      endId = bus.itinerary.route.end.id;
                      endNeighborhood =
                          bus.itinerary.route.end.adress.neighborhood;
                      endStreet = bus.itinerary.route.end.adress.street;
                      endBusStopId = bus.itinerary.route.end.id;
                    }
                    bus.itinerary.route.busStops.forEach((busList) {
                      busStopsFromItinerarys = busStopsFromItinerarys +
                          busList.id.toString() +
                          ' - ';
                    });
                  }
                }
              }

              return Container(
                color: Constants.white_grey,
                height: double.infinity,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Card(
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
                              _information(
                                  nameBusDriver,
                                  line,
                                  startNeighborhood,
                                  endNeighborhood,
                                  startId,
                                  endId),
                              isBusBluetooth == false
                                  ? _map(bus, startBusStopId, endBusStopId,
                                      startStreet, endStreet)
                                  : _route(bus),
                              _itinerary(weeks, weekendsHolidays)
                            ],
                          ),
                        ),
                      ),
                      isBusBluetooth == false
                          ? SizedBox(
                              height: 0,
                            )
                          : buttomBluetooth(deviceBus),
                    ],
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
}
