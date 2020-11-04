import 'dart:async';
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
import 'package:app_buscabus/Screens/BottomNavigationBar/ScreensPageView.dart';

//ignore: must_be_immutable
class ScreenMap extends StatefulWidget {
  ScreenMap(
      {this.blocNavigation,
      this.blocCameraPosition,
      this.blocFilter,
      this.blocBus,
      this.busWithGps,
      this.blocPosition,
      this.blocRoute,
      this.blocCoordinates,
      this.blocBusStop,
      this.listTerminals,
      this.listBuses,
      this.listBusStops,
      this.listRoutes,
      this.myIconsBusStops,
      this.myIconsBusTerminals,
      this.myIconBus,
      this.myIconPerson,
      this.mapStyle});

  bool isSelectedLines = false;
  bool isSelectedRoutes = false;
  bool isSelectedBusStops = false;
  bool isSelectedTerminals = false;

  final List<BitmapDescriptor> myIconsBusStops;
  final List<BitmapDescriptor> myIconsBusTerminals;
  final BitmapDescriptor myIconBus;
  final BitmapDescriptor myIconPerson;
  final String mapStyle;

  final NavigationBloc blocNavigation;
  final CameraPositionBloc blocCameraPosition;
  final FilterBloc blocFilter;
  final BusBloc blocBus;
  final RouteBloc blocRoute;
  final BusStopBloc blocBusStop;
  final PositionBloc blocPosition;
  final CoordinatesBloc blocCoordinates;
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
  final Set<Polyline> _polylines = {};
  final Map<int, List<LatLng>> polylineCoordinates =
      new Map<int, List<LatLng>>();

  @override
  _ScreenMapState createState() => _ScreenMapState();
}

class _ScreenMapState extends State<ScreenMap> {
  Completer<GoogleMapController> controllerMap = new Completer();

  Timer timer;
  double pixelRatio;

  bool isListRoutesComplete = false;

  @override
  void initState() {
    super.initState();

    if (widget.polylineCoordinates.isEmpty) {
      Future<bool> futureisListRoutesComplete = _searchPolylinesRoute();
      futureisListRoutesComplete.then((value) {
        setState(() {
          isListRoutesComplete = value;
        });
      });
    } else {
      isListRoutesComplete = true;
    }
  }

  @override
  void dispose() {
    super.dispose();
    timer?.cancel();
  }

  Future<bool> _searchPolylinesRoute() async {
    PolylinePoints polylinePointsStart = new PolylinePoints();
    PolylinePoints polylinePointsPath = new PolylinePoints();
    PolylinePoints polylinePointsEnd = new PolylinePoints();

    try {
      List<PointLatLng> listpolylinePoints = new List<PointLatLng>();

      for (int i = 0; i < widget.listRoutes.length; i++) {
        PolylineResult resultStart =
            await polylinePointsStart?.getRouteBetweenCoordinates(
                Constants.googleAPIKey,
                PointLatLng(widget.listRoutes[i].start.latitude,
                    widget.listRoutes[i].start.longitude),
                PointLatLng(widget.listRoutes[i].busStops[0].latitude,
                    widget.listRoutes[i].busStops[0].longitude));

        listpolylinePoints = resultStart.points;

        PolylineResult resultPath;
        for (int j = 0; j < widget.listRoutes[i].busStops.length - 1; j++) {
          resultPath = await polylinePointsPath?.getRouteBetweenCoordinates(
              Constants.googleAPIKey,
              PointLatLng(widget.listRoutes[i].busStops[j].latitude,
                  widget.listRoutes[i].busStops[j].longitude),
              PointLatLng(widget.listRoutes[i].busStops[j + 1].latitude,
                  widget.listRoutes[i].busStops[j + 1].longitude));
          listpolylinePoints =
              [listpolylinePoints, resultPath.points].expand((x) => x).toList();
        }

        PolylineResult resultEnd =
            await polylinePointsEnd?.getRouteBetweenCoordinates(
                Constants.googleAPIKey,
                PointLatLng(
                    widget
                        .listRoutes[i]
                        .busStops[widget.listRoutes[i].busStops.length - 1]
                        .latitude,
                    widget
                        .listRoutes[i]
                        .busStops[widget.listRoutes[i].busStops.length - 1]
                        .longitude),
                PointLatLng(widget.listRoutes[i].end.latitude,
                    widget.listRoutes[i].end.longitude));

        listpolylinePoints =
            [listpolylinePoints, resultEnd.points].expand((x) => x).toList();

        if (listpolylinePoints.isNotEmpty) {
          List<LatLng> polylineCoordinates = new List<LatLng>();
          listpolylinePoints.forEach((PointLatLng point) {
            polylineCoordinates.add(LatLng(point.latitude, point.longitude));
          });

          widget.polylineCoordinates
              .putIfAbsent(widget.listRoutes[i].id, () => polylineCoordinates);
        }
      }

      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  _addPolylinesRoutes() {
    for (int i = 0; i < widget.listRoutes.length; i++) {
      Polyline polyline = Polyline(
          polylineId: PolylineId("Route " + widget.listRoutes[i].id.toString()),
          color: Constants.accent_grey,
          points: widget.polylineCoordinates[widget.listRoutes[i].id]);

      widget._polylines.add(polyline);
    }
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
                    widget.blocCoordinates
                        .sendCoordinates(widget.polylineCoordinates);
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

  _updateMarkersBus(bool selected) {
    widget.isSelectedLines = selected;
    widget.blocFilter.changeChips(0, widget.isSelectedLines);
    if (widget.isSelectedLines) {
      widget._allMarkers =
          [widget._allMarkers, widget._busesMarkers].expand((x) => x).toSet();
    } else {
      List<Marker> toRemove = [];
      widget._allMarkers.forEach((element) {
        if (element.markerId.value.split(' ').toList().elementAt(0) == 'Bus') {
          toRemove.add(element);
        }
      });
      widget._allMarkers.removeWhere((element) => toRemove.contains(element));
    }
  }

  _updatePolylinesRoutes(bool selected) {
    widget.isSelectedRoutes = selected;
    widget.blocFilter.changeChips(1, widget.isSelectedRoutes);
    if (widget.isSelectedRoutes) {
      _addPolylinesRoutes();
    } else {
      widget._polylines.clear();
    }
  }

  _updateMarkersBusStop(bool selected) {
    widget.isSelectedBusStops = selected;
    widget.blocFilter.changeChips(3, widget.isSelectedBusStops);
    if (widget.isSelectedBusStops) {
      widget._allMarkers = [widget._allMarkers, widget._busStopsMarkers]
          .expand((x) => x)
          .toSet();
    } else {
      List<Marker> toRemove = [];
      widget._allMarkers.forEach((element) {
        if (element.markerId.value.split(' ').toList().elementAt(0) ==
            'BusStop') {
          toRemove.add(element);
        }
      });
      widget._allMarkers.removeWhere((element) => toRemove.contains(element));
    }
  }

  _updateMarkersTerminals(bool selected) {
    widget.isSelectedTerminals = selected;
    widget.blocFilter.changeChips(2, widget.isSelectedTerminals);
    if (widget.isSelectedTerminals) {
      widget._allMarkers = [widget._allMarkers, widget._terminalsMarkers]
          .expand((x) => x)
          .toSet();
    } else {
      List<Marker> toRemove = [];
      widget._allMarkers.forEach((element) {
        if (element.markerId.value.split(' ').toList().elementAt(0) ==
            'Terminal') {
          toRemove.add(element);
        }
      });
      widget._allMarkers.removeWhere((element) => toRemove.contains(element));
    }
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

  _onMapCreated(GoogleMapController controller) async {
    controller.setMapStyle(widget.mapStyle);
    controllerMap.complete(controller); // definindo o controller do mapa
    _loadMarkers(); // carrega os markers
    /*   timer = Timer.periodic(
        Duration(seconds: 2), (Timer t) async => await _updateBusLocation()); */
  }

  @override
  Widget build(BuildContext context) {
    pixelRatio = MediaQuery.of(context).devicePixelRatio;

    if (isListRoutesComplete == false) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    } else {
      return StreamBuilder<List<bool>>(
          initialData: filterchips,
          stream: widget.blocFilter.output,
          builder: (context, snapshotFilter) {
            widget.isSelectedLines = snapshotFilter.data[0];
            widget.isSelectedRoutes = snapshotFilter.data[1];
            widget.isSelectedTerminals = snapshotFilter.data[2];
            widget.isSelectedBusStops = snapshotFilter.data[3];
            return Scaffold(
                appBar: PreferredSize(
                  preferredSize: const Size.fromHeight(56),
                  child: AppBar(
                    backgroundColor: Constants.white_grey,
                    actions: [
                      Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: FilterChip(
                            elevation: 3,
                            backgroundColor: Constants.white_grey,
                            showCheckmark: false,
                            label: Text('ÔNIBUS'),
                            onSelected: (bool selected) =>
                                _updateMarkersBus(selected),
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
                            onSelected: (bool selected) =>
                                _updatePolylinesRoutes(selected),
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
                            onSelected: (bool selected) =>
                                _updateMarkersTerminals(selected),
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
                            onSelected: (bool selected) =>
                                _updateMarkersBusStop(selected),
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
                  ),
                ),
                body: Stack(children: [
                  Container(
                    child: StreamBuilder<Position>(
                        stream: widget.blocPosition.output,
                        builder: (context, snapshotPosition) {
                          if (snapshotPosition.hasData) {
                            _addMarkerPerson(snapshotPosition.data);
                            return StreamBuilder<CameraPosition>(
                                stream: widget.blocCameraPosition.output,
                                builder: (contextCamera, snapshotCamera) {
                                  if (snapshotCamera.hasData) {
                                    return GoogleMap(
                                      mapType: MapType.normal,
                                      initialCameraPosition:
                                          snapshotCamera.data,
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
                          moveCameraBounds(
                              getBounds(lats, lngs), controllerMap);
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
          });
    }
  }
}
