import 'dart:async';
import 'dart:typed_data';
import 'package:app_buscabus/Constants.dart';
import 'package:app_buscabus/models/Bus.dart';
import 'package:app_buscabus/models/BusStop.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'dart:ui' as ui;
import 'package:app_buscabus/Screens/BottomNavigationBar/ScreensPageView.dart';
import 'dart:math';

import 'package:rxdart/rxdart.dart';

class ScreenMap extends StatefulWidget {
  ScreenMap(
      {this.blocNavigation,
      this.blocFilter,
      this.blocBus,
      this.busWithGps,
      this.blocPosition});
  bool isSelectedLine;
  bool isSelectedBusStop;
  bool isSelectedTerminals;

  final NavigationBloc blocNavigation;
  final FilterBloc blocFilter;
  final BusBloc blocBus;
  final PositionBloc blocPosition;

  Bus busWithGps;
/*   List<dynamic> _listSelectedMarkers = new List<dynamic>();
  List<Widget> _listSelectedMarkersWidgets = new List<Widget>(); */
  Set<Marker> _allMarkers = new Set<Marker>();
  Set<Marker> _busStopsMarkers = {};
  Set<Marker> _busesMarkers = {};
  Set<Marker> _terminalsMarkers = {};

  CameraPosition _cameraPosition =
      CameraPosition(target: LatLng(-26.89635815, -48.67252082), zoom: 16);

  @override
  _ScreenMapState createState() => _ScreenMapState();
}

class _ScreenMapState extends State<ScreenMap> {
  Completer<GoogleMapController> controllerMap = new Completer();

  List<BitmapDescriptor> myIconsBusStops = new List<BitmapDescriptor>();
  List<BitmapDescriptor> myIconsBusTerminals = new List<BitmapDescriptor>();
  BitmapDescriptor myIconBus;
  BitmapDescriptor myIconPerson;
  Timer timer;

  static List<BusStop> listBusStops = new List<BusStop>();
  static List<Bus> listBuses = new List<Bus>();

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

  _loadLists() async {
    listBusStops = await BusStop.getList();
    listBusStops.removeWhere((element) => element.adress == null);
    listBuses = await Bus.getList();
  }

  _addMarkersBusStops() {
    listBusStops.forEach((element) {
      if (!element.isTerminal) {
        widget._busStopsMarkers.add(new Marker(
            markerId: MarkerId('BusStop ' + element.id.toString()),
            onTap: () {
/*                 if (widget._listSelectedMarkers.contains(element)) {
                  _removeSelectedMarkers(element);
                } else {
                  _addSelectedMarkers(element);
                } */
            },
            infoWindow: InfoWindow(
                title: element.adress.neighborhood,
                snippet: element.adress.street),
            position: LatLng(element.adress.globalPosition.latitude,
                element.adress.globalPosition.longitude),
            icon: myIconsBusStops.elementAt(element.id - 1)));
      } else {
        widget._terminalsMarkers.add(new Marker(
            markerId: MarkerId('Terminal ' + element.id.toString()),
            onTap: () {
/*                 if (widget._listSelectedMarkers.contains(element)) {
                  _removeSelectedMarkers(element);
                } else {
                  _addSelectedMarkers(element);
                } */
            },
            infoWindow: InfoWindow(
                title: element.adress.neighborhood,
                snippet: element.adress.street),
            position: LatLng(element.adress.globalPosition.latitude,
                element.adress.globalPosition.longitude),
            icon: myIconsBusTerminals.elementAt(element.id - 1)));
      }
    });
  }

  _addMarkersBuses() {
    listBuses.forEach((element) {
      if (element.id == Constants.busWithGpsId) {
        widget.busWithGps = element;
      }
      if (element.isAvailable) {
        if (element.currentPosition != null) {
          widget._busesMarkers.add(new Marker(
              markerId: MarkerId('Bus ' + element.id.toString()),
              onTap: () {
/*                 if (widget._listSelectedMarkers.contains(element)) {
                  _removeSelectedMarkers(element);
                } else {
                  _addSelectedMarkers(element);
                } */
              },
              infoWindow: InfoWindow(
                  title: "Linha " + element.line.toString(),
                  snippet: "Ver detalhes",
                  onTap: () {
                    widget.blocBus.sendBus(element);
                    widget.blocNavigation.changeNavigationIndex(Navigation.BUS);
                  }),
              position: LatLng(element.currentPosition.latitude,
                  element.currentPosition.longitude),
              icon: myIconBus /* BitmapDescriptor.defaultMarker */));
        }
      }
    });
  }

  _addMarkerPerson(Position position) {
    widget._allMarkers.add(new Marker(
        markerId: MarkerId("Person"),
        position: LatLng(position.latitude, position.longitude),
        infoWindow: InfoWindow(title: "Estou aqui"),
        icon: /* BitmapDescriptor.defaultMarker */ myIconPerson));
  }

  _loadMarkers() async {
    await _loadLists();
    _addMarkersBuses();
    _addMarkersBusStops();
  }

  _updateBusLocation() async {
    await widget.busWithGps.updateCurrentPosition();
    var markerPosition = LatLng(widget.busWithGps.currentPosition.latitude,
        widget.busWithGps.currentPosition.longitude);
    String busMarkerId = 'Bus ' + widget.busWithGps.id.toString();
    Marker busMarker = Marker(
        markerId: MarkerId(busMarkerId),
        position: markerPosition, // updated position
        icon: myIconBus);

    setState(() {
      widget._allMarkers.removeWhere((m) => m.markerId.value == busMarkerId);
      widget._allMarkers.add(busMarker);
    });
    print("Latitude: " + widget.busWithGps.currentPosition.latitude.toString());
    print(
        "Longitude: " + widget.busWithGps.currentPosition.longitude.toString());
  }

/*   _removeSelectedMarkers(dynamic element) {
    for (int index = 0; index < widget._listSelectedMarkers.length; index++) {
      if (widget._listSelectedMarkers.elementAt(index) == element) {
        widget._listSelectedMarkersWidgets.removeAt(index);
        widget._listSelectedMarkers.removeAt(index);
      }
    }
  } */

/*   _addSelectedMarkers(dynamic element) {
    widget._listSelectedMarkers.add(element);
    widget._listSelectedMarkersWidgets.add(InputChip(
        deleteIconColor: Constants.accent_grey,
        visualDensity: VisualDensity.comfortable,
        label: Text(
          element is BusStop
              ? element.isTerminal
                  ? "TERMINAL " + element.id.toString()
                  : "PONTO " + element.id.toString()
              : "LINHA " + element.line.toString(),
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: element is BusStop
                  ? element.isTerminal
                      ? Constants.accent_blue
                      : Constants.brightness_blue
                  : Constants.green),
        ),
        onDeleted: () => print("delete")));
  } */

  _onMapCreated(GoogleMapController controller) async {
    controller.setMapStyle(mapStyle);
    controllerMap.complete(controller); // definindo o controller do mapa
    await _loadMarkers(); // carrega os markers

    timer = Timer.periodic(
        Duration(seconds: 2), (Timer t) async => await _updateBusLocation());
  }

  LatLngBounds getBounds(List<Marker> markers) {
    var lngs = markers.map<double>((m) => m.position.longitude).toList();
    var lats = markers.map<double>((m) => m.position.latitude).toList();

    double topMost = lngs.reduce(max);
    double leftMost = lats.reduce(min);
    double rightMost = lats.reduce(max);
    double bottomMost = lngs.reduce(min);

    LatLngBounds bounds = LatLngBounds(
      northeast: LatLng(rightMost, topMost),
      southwest: LatLng(leftMost, bottomMost),
    );

    return bounds;
  }

  _moveCameraBetween(double latitudeOrigin, double latitudeDestiny,
      double longitudeOrigem, double longitudeDestino) {
    var nLat, nLon, sLat, sLon;

    double latitudeOrigin, latitudeDestiny, longitudeOrigem, longitudeDestino;

    if (latitudeOrigin <= latitudeDestiny) {
      sLat = latitudeOrigin;
      nLat = latitudeDestiny;
    } else {
      sLat = latitudeDestiny;
      nLat = latitudeOrigin;
    }

    if (longitudeOrigem <= longitudeDestino) {
      sLon = longitudeOrigem;
      nLon = longitudeDestino;
    } else {
      sLon = longitudeDestino;
      nLon = longitudeOrigem;
    }

    _moveCameraBounds(LatLngBounds(
        northeast: LatLng(nLat, nLon), //nordeste
        southwest: LatLng(sLat, sLon) //sudoeste
        ));
  }

  _moveCameraBounds(LatLngBounds latLngBounds) async {
    GoogleMapController googleMapController = await controllerMap.future;
    googleMapController
        .animateCamera(CameraUpdate.newLatLngBounds(latLngBounds, 100));
  }

  _moveCamera(CameraPosition cameraPosition) async {
    GoogleMapController googleMapController = await controllerMap.future;
    googleMapController
        .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
  }

  _drawScreen() {}

  _searchScreen() {}

  _showFavorites() {}

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
                  widget.isSelectedLine = snapshot.data[0];
                  widget.isSelectedBusStop = snapshot.data[2];
                  widget.isSelectedTerminals = snapshot.data[1];

                  return AppBar(
                    leading: IconButton(
                      onPressed: () => {},
                      icon: Icon(
                        Icons.menu,
                        color: Constants.accent_blue,
                      ),
                    ),
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
                                  widget.isSelectedLine =
                                      !widget.isSelectedLine;
                                  widget.blocFilter
                                      .changeChips(0, widget.isSelectedLine);
                                  if (widget.isSelectedLine) {
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
                                color: widget.isSelectedLine
                                    ? Constants.white_grey
                                    : Constants.accent_blue),
                            selected: widget.isSelectedLine,
                            selectedColor: Constants.green,
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
                                      1, widget.isSelectedTerminals);
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
                                  widget.isSelectedBusStop =
                                      !widget.isSelectedBusStop;
                                  widget.blocFilter
                                      .changeChips(2, widget.isSelectedBusStop);
                                  if (widget.isSelectedBusStop) {
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
                                color: widget.isSelectedBusStop
                                    ? Constants.white_grey
                                    : Constants.accent_blue),
                            selected: widget.isSelectedBusStop,
                            selectedColor: Constants.brightness_blue,
                            checkmarkColor: Constants.white_grey),
                      ),
                    ],
                  );
                }
              }),
        ),
        body: Stack(children: [
          Container(
            child: StreamBuilder<Position>(
                stream: widget.blocPosition.output,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    _addMarkerPerson(snapshot.data);
                    return GoogleMap(
                      mapType: MapType.normal,
                      initialCameraPosition: widget._cameraPosition,
                      mapToolbarEnabled: false,
                      onMapCreated: _onMapCreated,
                      myLocationEnabled: false,
                      compassEnabled: false,
                      zoomControlsEnabled: false,
                      markers: widget._allMarkers,
                    );
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
                  _moveCameraBounds(getBounds(widget._allMarkers.toList()));
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
                          _moveCamera(CameraPosition(
                              target: LatLng(snapshot.data.latitude,
                                  snapshot.data.longitude),
                              zoom: 19));
                        });
                  })),
        ]));
  }
}
