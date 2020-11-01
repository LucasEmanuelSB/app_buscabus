import 'dart:async';
import 'dart:typed_data';
import 'package:app_buscabus/cameraFunctions.dart';
import 'package:app_buscabus/Constants.dart';
import 'package:app_buscabus/models/Bus.dart';
import 'package:app_buscabus/models/BusStop.dart';
import 'package:app_buscabus/models/Routes.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'dart:ui' as ui;
import 'package:app_buscabus/Screens/BottomNavigationBar/ScreensPageView.dart';

class ScreenMap extends StatefulWidget {
  ScreenMap(
      {this.blocNavigation,
      this.blocCameraPosition,
      this.blocFilter,
      this.blocBus,
      this.busWithGps,
      this.blocPosition,
      this.blocRoute,
      this.blocBusStop,
      this.listTerminals,
      this.listBuses,
      this.listBusStops,
      this.listRoutes});
  bool isSelectedLines = false;
  bool isSelectedRoutes = false;
  bool isSelectedBusStops = false;
  bool isSelectedTerminals = false;

  final NavigationBloc blocNavigation;
  final CameraPositionBloc blocCameraPosition;
  final FilterBloc blocFilter;
  final BusBloc blocBus;
  final RouteBloc blocRoute;
  final BusStopBloc blocBusStop;
  final PositionBloc blocPosition;
  final List<Bus> listBuses;
  final List<BusStop> listBusStops;
  final List<BusStop> listTerminals;
  final List<Routes> listRoutes;

  CameraPosition cameraPosition =
      CameraPosition(target: LatLng(-26.89635815, -48.67252082), zoom: 16);

  Bus busWithGps;

  Set<Marker> _allMarkers = new Set<Marker>();
  final Set<Marker> _busStopsMarkers = {};
  final Set<Marker> _busesMarkers = {};
  final Set<Marker> _terminalsMarkers = {};
  Set<Polyline> _polylines = {};
  List<LatLng> polylineCoordinates = [];
  PolylinePoints polylinePoints = new PolylinePoints();

  final List<BitmapDescriptor> myIconsBusStops = new List<BitmapDescriptor>();
  final List<BitmapDescriptor> myIconsBusTerminals =
      new List<BitmapDescriptor>();
  BitmapDescriptor myIconBus;
  BitmapDescriptor myIconPerson;

  @override
  _ScreenMapState createState() => _ScreenMapState();
}

class _ScreenMapState extends State<ScreenMap> {
  Completer<GoogleMapController> controllerMap = new Completer();

  Timer timer;
  double pixelRatio;
  String mapStyle;

  @override
  void initState() {
    super.initState();
    _defineMapStyle(); //define o estilo do mapa
    _loadBitmapDescriptors(); // carrega assets dos markers
    // carrega listner para posicao do usuario no mapa
  }

  @override
  void dispose() {
    super.dispose();
    timer?.cancel();
  }

  _defineMapStyle() {
    rootBundle.loadString('assets/map_style.txt').then((string) {
      mapStyle = string;
    });
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
        widget.myIconsBusStops.add(BitmapDescriptor.fromBytes(onValue));
      });

      getBytesFromAsset('assets/markers/terminal' + i.toString() + '.png', 64)
          .then((onValue) {
        widget.myIconsBusTerminals.add(BitmapDescriptor.fromBytes(onValue));
      });
    }
    getBytesFromAsset('assets/markers/bus.png', 64).then((onValue) {
      widget.myIconBus = BitmapDescriptor.fromBytes(onValue);
    });

    getBytesFromAsset('assets/markers/person.png', 64).then((onValue) {
      widget.myIconPerson = BitmapDescriptor.fromBytes(onValue);
    });
  }

  _addPolylinesRoutes() {
    widget.listRoutes.forEach((element) async {
      List<PointLatLng> polylinePoints = new List<PointLatLng>();
      PolylineResult resultStart = await widget.polylinePoints
          ?.getRouteBetweenCoordinates(
              Constants.googleAPIKey,
              PointLatLng(element.start.latitude, element.start.longitude),
              PointLatLng(
                  element.busStops[0].latitude, element.busStops[0].longitude));
      polylinePoints = resultStart.points;

      PolylineResult resultPath;
      for (int i = 0; i < element.busStops.length - 1; i++) {
        resultPath = await widget.polylinePoints?.getRouteBetweenCoordinates(
            Constants.googleAPIKey,
            PointLatLng(
                element.busStops[i].latitude, element.busStops[i].longitude),
            PointLatLng(element.busStops[i + 1].latitude,
                element.busStops[i + 1].longitude));
        polylinePoints =
            [polylinePoints, resultPath.points].expand((x) => x).toList();
      }

      PolylineResult resultEnd = await widget.polylinePoints
          ?.getRouteBetweenCoordinates(
              Constants.googleAPIKey,
              PointLatLng(
                  element.busStops[element.busStops.length - 1].latitude,
                  element.busStops[element.busStops.length - 1].longitude),
              PointLatLng(element.end.latitude, element.end.longitude));

      polylinePoints =
          [polylinePoints, resultEnd.points].expand((x) => x).toList();

      if (polylinePoints.isNotEmpty) {
        // loop through all PointLatLng points and convert them
        // to a list of LatLng, required by the Polyline
        polylinePoints.forEach((PointLatLng point) {
          widget.polylineCoordinates
              .add(LatLng(point.latitude, point.longitude));
        });
      }
      setState(() {
        // create a Polyline instance
        // with an id, an RGB color and the list of LatLng pairs
        Polyline polyline = Polyline(
            polylineId: PolylineId("Route " + element.id.toString()),
            color: Constants.accent_grey,
            points: widget.polylineCoordinates);

        // add the constructed polyline as a set of points
        // to the polyline set, which will eventually
        // end up showing up on the map
        widget._polylines.add(polyline);
      });
    });
  }

  _addMarkerTerminals() {
    widget.listTerminals.forEach((element) {
      widget._terminalsMarkers.add(new Marker(
          markerId: MarkerId('Terminal ' + element.id.toString()),
          infoWindow: InfoWindow(
              title: element.adress.neighborhood,
              snippet: element.adress.street),
          position: LatLng(element.latitude, element.longitude),
          icon: widget.myIconsBusTerminals.elementAt(element.id - 1)));
    });
  }

  _addMarkersBusStops() {
    widget.listBusStops.forEach((element) {
      widget._busStopsMarkers.add(new Marker(
          markerId: MarkerId('BusStop ' + element.id.toString()),
          infoWindow: InfoWindow(
              title: element.adress.neighborhood,
              snippet: element.adress.street),
          position: LatLng(element.latitude, element.longitude),
          icon: widget.myIconsBusStops.elementAt(element.id - 1)));
    });
  }

  _addMarkersBuses() {
    widget.listBuses.forEach((element) {
      if (element.id == Constants.busWithGpsId) {
        widget.busWithGps = element;
      }
      if (element.isAvailable) {
        if (element.currentPosition != null) {
          widget._busesMarkers.add(new Marker(
              markerId: MarkerId('Bus ' + element.id.toString()),
              infoWindow: InfoWindow(
                  title: "Linha " + element.line.toString(),
                  snippet: "Ver detalhes",
                  onTap: () {
                    widget.blocBus.sendBus(element);
                    widget.blocNavigation.changeNavigationIndex(Navigation.BUS);
                  }),
              position: LatLng(element.currentPosition.latitude,
                  element.currentPosition.longitude),
              icon: widget.myIconBus /* BitmapDescriptor.defaultMarker */));
        }
      }
    });
  }

  _addMarkerPerson(Position position) {
    widget._allMarkers
        .removeWhere((marker) => marker.markerId == MarkerId("Person"));
    widget._allMarkers.add(new Marker(
        markerId: MarkerId("Person"),
        position: LatLng(position.latitude, position.longitude),
        infoWindow: InfoWindow(title: "Estou aqui"),
        icon: /* BitmapDescriptor.defaultMarker */ widget.myIconPerson));
  }

  _loadMarkers() {
    _addMarkersBuses();
    _addMarkersBusStops();
    _addMarkerTerminals();
  }

  _updateBusLocation() async {
    await widget.busWithGps.updateCurrentPosition();
    var markerPosition = LatLng(widget.busWithGps.currentPosition.latitude,
        widget.busWithGps.currentPosition.longitude);
    String busMarkerId = 'Bus ' + widget.busWithGps.id.toString();
    Marker busMarker = Marker(
        markerId: MarkerId(busMarkerId),
        position: markerPosition, // updated position
        icon: widget.myIconBus);

    setState(() {
      widget._allMarkers.removeWhere((m) => m.markerId.value == busMarkerId);
      if (widget.isSelectedLines) widget._allMarkers.add(busMarker);
    });
    print("Latitude: " + widget.busWithGps.currentPosition.latitude.toString());
    print(
        "Longitude: " + widget.busWithGps.currentPosition.longitude.toString());
  }

  _onMapCreated(GoogleMapController controller) {
    controller.setMapStyle(mapStyle);
    controllerMap.complete(controller); // definindo o controller do mapa
    _loadMarkers(); // carrega os markers
    /*   timer = Timer.periodic(
        Duration(seconds: 2), (Timer t) async => await _updateBusLocation()); */
  }

  @override
  Widget build(BuildContext context) {
    pixelRatio = MediaQuery.of(context).devicePixelRatio;
    return Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: StreamBuilder<List<bool>>(
              initialData: filterchips,
              stream: widget.blocFilter.output,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  setState(() {
                    widget.isSelectedLines = snapshot.data[0];
                    widget.isSelectedRoutes = snapshot.data[1];
                    widget.isSelectedTerminals = snapshot.data[2];
                    widget.isSelectedBusStops = snapshot.data[3];
                  });
                  return AppBar(
                    backgroundColor: Constants.white_grey,
                    actions: [
                      Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: FilterChip(
                            elevation: 3,
                            backgroundColor: Constants.white_grey,
                            showCheckmark: false,
                            label: Text('ÔNIBUS'),
                            onSelected: (bool selected) async {
                              if (this.mounted) {
                                setState(() {
                                  widget.isSelectedLines =
                                      !widget.isSelectedLines;
                                  widget.blocFilter
                                      .changeChips(0, widget.isSelectedLines);
                                  if (widget.isSelectedLines) {
                                    widget._allMarkers = [
                                      widget._allMarkers,
                                      widget._busesMarkers
                                    ].expand((x) => x).toSet();
                                  } else {
                                    List<Marker> toRemove = [];
                                    widget._allMarkers.forEach((element) {
                                      if (element.markerId.value
                                              .split(' ')
                                              .toList()
                                              .elementAt(0) ==
                                          'Bus') {
                                        toRemove.add(element);
                                      }
                                    });
                                    widget._allMarkers.removeWhere((element) =>
                                        toRemove.contains(element));
                                  }
                                });
                              }
                            },
                            labelStyle: TextStyle(
                                fontFamily: 'Lato',
                                fontWeight: FontWeight.bold,
                                color: widget.isSelectedLines
                                    ? Constants.white_grey
                                    : Constants.accent_blue),
                            selected: widget.isSelectedLines,
                            selectedColor: Constants.green,
                            checkmarkColor: Constants.white_grey),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: FilterChip(
                            elevation: 3,
                            backgroundColor: Constants.white_grey,
                            showCheckmark: false,
                            label: Text('ROTAS'),
                            onSelected: (bool selected) async {
                              if (this.mounted) {
                                setState(() {
                                  widget.isSelectedRoutes =
                                      !widget.isSelectedRoutes;
                                  widget.blocFilter
                                      .changeChips(1, widget.isSelectedRoutes);
                                  if (widget.isSelectedRoutes) {
                                    _addPolylinesRoutes();
                                  } else {
                                    widget._polylines.clear();
                                  }
                                });
                              }
                            },
                            labelStyle: TextStyle(
                                fontFamily: 'Lato',
                                fontWeight: FontWeight.bold,
                                color: widget.isSelectedRoutes
                                    ? Constants.white_grey
                                    : Constants.accent_blue),
                            selected: widget.isSelectedRoutes,
                            selectedColor: Constants.accent_grey,
                            checkmarkColor: Constants.white_grey),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: FilterChip(
                            elevation: 3,
                            backgroundColor: Constants.white_grey,
                            showCheckmark: false,
                            label: Text('TERMINAIS'),
                            onSelected: (bool selected) async {
                              if (this.mounted) {
                                setState(() {
                                  widget.isSelectedTerminals =
                                      !widget.isSelectedTerminals;
                                  widget.blocFilter.changeChips(
                                      2, widget.isSelectedTerminals);
                                  if (widget.isSelectedTerminals) {
                                    widget._allMarkers = [
                                      widget._allMarkers,
                                      widget._terminalsMarkers
                                    ].expand((x) => x).toSet();
                                  } else {
                                    List<Marker> toRemove = [];
                                    widget._allMarkers.forEach((element) {
                                      if (element.markerId.value
                                              .split(' ')
                                              .toList()
                                              .elementAt(0) ==
                                          'Terminal') {
                                        toRemove.add(element);
                                      }
                                    });
                                    widget._allMarkers.removeWhere((element) =>
                                        toRemove.contains(element));
                                  }
                                });
                              }
                            },
                            labelStyle: TextStyle(
                                fontFamily: 'Lato',
                                fontWeight: FontWeight.bold,
                                color: widget.isSelectedTerminals
                                    ? Constants.white_grey
                                    : Constants.accent_blue),
                            selected: widget.isSelectedTerminals,
                            selectedColor: Constants.accent_blue,
                            checkmarkColor: Constants.white_grey),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: FilterChip(
                            elevation: 3,
                            backgroundColor: Constants.white_grey,
                            showCheckmark: false,
                            label: Text('PONTOS'),
                            onSelected: (bool selected) async {
                              if (this.mounted) {
                                setState(() {
                                  widget.isSelectedBusStops =
                                      !widget.isSelectedBusStops;
                                  widget.blocFilter.changeChips(
                                      3, widget.isSelectedBusStops);
                                  if (widget.isSelectedBusStops) {
                                    widget._allMarkers = [
                                      widget._allMarkers,
                                      widget._busStopsMarkers
                                    ].expand((x) => x).toSet();
                                  } else {
                                    List<Marker> toRemove = [];
                                    widget._allMarkers.forEach((element) {
                                      if (element.markerId.value
                                              .split(' ')
                                              .toList()
                                              .elementAt(0) ==
                                          'BusStop') {
                                        toRemove.add(element);
                                      }
                                    });
                                    widget._allMarkers.removeWhere((element) =>
                                        toRemove.contains(element));
                                  }
                                });
                              }
                            },
                            labelStyle: TextStyle(
                                fontFamily: 'Lato',
                                fontWeight: FontWeight.bold,
                                color: widget.isSelectedBusStops
                                    ? Constants.white_grey
                                    : Constants.accent_blue),
                            selected: widget.isSelectedBusStops,
                            selectedColor: Constants.brightness_blue,
                            checkmarkColor: Constants.white_grey),
                      ),
                    ],
                  );
                }
                return Center(
                  child: Text("Nenhum dado a ser exibido!"),
                );
              }),
        ),
        body: Stack(children: [
          Container(
            child: StreamBuilder<Position>(
                stream: widget.blocPosition.output,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    _addMarkerPerson(snapshot.data);
                    return StreamBuilder<CameraPosition>(
                        stream: widget.blocCameraPosition.output,
                        builder: (contextCamera, snapshotCamera) {
                          if (snapshotCamera.hasData) {
                            return GoogleMap(
                              mapType: MapType.normal,
                              initialCameraPosition: snapshotCamera.data,
                              mapToolbarEnabled: false,
                              onMapCreated: _onMapCreated,
                              myLocationEnabled: false,
                              compassEnabled: false,
                              zoomControlsEnabled: false,
                              markers: widget._allMarkers,
                              polylines: widget._polylines,
                            );
                          } else {
                            return Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                        });
                  } else {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                }),
          ),
          Positioned(
            bottom: 64,
            right: 8,
            child: IconButton(
                icon: Icon(MdiIcons.selectMultipleMarker),
                onPressed: () {
                  List<double> lngs = widget._allMarkers
                      .toList()
                      .map<double>((m) => m.position.longitude)
                      .toList();
                  List<double> lats = widget._allMarkers
                      .toList()
                      .map<double>((m) => m.position.latitude)
                      .toList();
                  moveCameraBounds(getBounds(lats, lngs), controllerMap);
                }),
          ),
          Positioned(
              bottom: 16,
              right: 8,
              child: StreamBuilder<Position>(
                  stream: widget.blocPosition.output,
                  builder: (context, snapshot) {
                    return IconButton(
                        icon: Icon(Icons.my_location),
                        onPressed: () {
                          moveCamera(
                              CameraPosition(
                                  target: LatLng(snapshot.data.latitude,
                                      snapshot.data.longitude),
                                  zoom: 19),
                              controllerMap);
                        });
                  })),
        ]));
  }
}
