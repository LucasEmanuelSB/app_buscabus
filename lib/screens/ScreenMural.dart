import 'package:app_buscabus/Constants.dart';
import 'package:app_buscabus/models/Bus.dart';
import 'package:app_buscabus/models/BusStop.dart';
import 'package:app_buscabus/models/Itinerary.dart';
import 'package:app_buscabus/models/Routes.dart';
import 'package:badges/badges.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:app_buscabus/Screens/ScreenPageView.dart';


class ScreenMural extends StatefulWidget {
  ScreenMural(
      {this.blocNavigation,
      this.blocCameraPosition,
      this.blocFilter,
      this.blocBus,
      this.blocRoute,
      this.blocBusStop,
      this.listBuses,
      this.listBusStops,
      this.listTerminals,
      this.listRoutes});
  final NavigationBloc blocNavigation;
  final CameraPositionBloc blocCameraPosition;
  final BusBloc blocBus;
  final RouteBloc blocRoute;
  final BusStopBloc blocBusStop;
  final FilterBloc blocFilter;
  final List<Bus> listBuses;
  final List<BusStop> listBusStops;
  final List<Routes> listRoutes;
  final List<BusStop> listTerminals;

  @override
  _ScreenMuralState createState() => _ScreenMuralState();
}

class _ScreenMuralState extends State<ScreenMural> {

  bool isSelectedLines = false;
  bool isSelectedRoutes = false;
  bool isSelectedBusStops = false;
  bool isSelectedTerminals = false;

  @override
  void initState() {
    super.initState();
  }

  List<dynamic> _getList() {
    List<dynamic> lists = new List<dynamic>();

    if (isSelectedLines)
      lists = [lists, widget.listBuses].expand((x) => x).toList();

    if (isSelectedRoutes)
      lists = [lists, widget.listRoutes].expand((x) => x).toList();

    if (isSelectedBusStops)
      lists = [lists, widget.listBusStops].expand((x) => x).toList();

    if (isSelectedTerminals)
      lists = [lists, widget.listTerminals].expand((x) => x).toList();

    return lists;
  }

  Widget _leading(Routes route) {
    return Badge(
        badgeColor: Constants.accent_grey,
        padding: route.id < 10
            ? EdgeInsets.symmetric(vertical: 10, horizontal: 10)
            : EdgeInsets.symmetric(vertical: 0, horizontal: 10),
        badgeContent: Text(route.id.toString(),
            style: TextStyle(color: Constants.white_grey)));
  }

  Widget _subtitle(Routes route) {
    return Wrap(
      runSpacing: 4,
      alignment: WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.center,
      direction: Axis.horizontal,
      children: _generateRouteIcons(route.start, route.end, route.busStops),
    );
  }

  Widget _lines(Routes route) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      direction: Axis.horizontal,
      children: _generateRouteLines(route.itinerarys),
    );
  }

  List<Widget> _generateRouteLines(List<Itinerary> itinerarys) {
    List<Widget> children = [];
    children.add(Text(
      "Linhas: ",
      style: TextStyle(
          color: Constants.accent_grey,
          fontWeight: FontWeight.bold,
          fontFamily: 'Abel'),
    ));
    for (int i = 0; i < itinerarys.length; i++) {
      children.add(new Badge(
        padding: itinerarys[i].bus.line < 10
            ? EdgeInsets.symmetric(vertical: 10, horizontal: 10)
            : itinerarys[i].bus.line > 9 && itinerarys[i].bus.line < 99
                ? EdgeInsets.symmetric(vertical: 6, horizontal: 6)
                : EdgeInsets.symmetric(vertical: 5, horizontal: 5),
        badgeContent: Text(
          itinerarys[i].bus.line.toString(),
          style: TextStyle(color: Constants.white_grey),
        ),
        badgeColor: Constants.green,
      ));
      if (i != itinerarys.length - 1) children.add(new Text(', '));
    }
    return children;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: StreamBuilder<List<bool>>(
              initialData: filterchips,
              stream: widget.blocFilter.output,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  isSelectedLines = snapshot.data[0];
                  isSelectedRoutes = snapshot.data[1];
                  isSelectedTerminals = snapshot.data[2];
                  isSelectedBusStops = snapshot.data[3];
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
                            labelStyle: TextStyle(
                                fontFamily: 'Lato',
                                fontWeight: FontWeight.bold,
                                color: isSelectedLines
                                    ? Constants.white_grey
                                    : Constants.accent_blue),
                            selected: isSelectedLines,
                            onSelected: (bool selected) {
                              if (mounted) {
                                setState(() {
                                  isSelectedLines =
                                      !isSelectedLines;
                                  widget.blocFilter
                                      .changeChips(0, isSelectedLines);
                                });
                              }
                            },
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
                            labelStyle: TextStyle(
                                fontFamily: 'Lato',
                                fontWeight: FontWeight.bold,
                                color: isSelectedRoutes
                                    ? Constants.white_grey
                                    : Constants.accent_blue),
                            selected: isSelectedRoutes,
                            onSelected: (bool selected) {
                              if (mounted) {
                                setState(() {
                                  isSelectedRoutes =
                                      !isSelectedRoutes;
                                  widget.blocFilter
                                      .changeChips(1, isSelectedRoutes);
                                });
                              }
                            },
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
                            labelStyle: TextStyle(
                                fontFamily: 'Lato',
                                fontWeight: FontWeight.bold,
                                color: isSelectedTerminals
                                    ? Constants.white_grey
                                    : Constants.accent_blue),
                            selected: isSelectedTerminals,
                            onSelected: (bool selected) {
                              if (mounted) {
                                setState(() {
                                  isSelectedTerminals =
                                      !isSelectedTerminals;
                                  widget.blocFilter.changeChips(
                                      2, isSelectedTerminals);
                                });
                              }
                            },
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
                            labelStyle: TextStyle(
                                fontFamily: 'Lato',
                                fontWeight: FontWeight.bold,
                                color: isSelectedBusStops
                                    ? Constants.white_grey
                                    : Constants.accent_blue),
                            selected: isSelectedBusStops,
                            onSelected: (bool selected) {
                              if (mounted) {
                                setState(() {
                                  isSelectedBusStops =
                                      !isSelectedBusStops;
                                  widget.blocFilter.changeChips(
                                      3, isSelectedBusStops);
                                });
                              }
                            },
                            selectedColor: Constants.brightness_blue,
                            checkmarkColor: Constants.white_grey),
                      ),
                    ],
                  );
                } else {
                  return Center(
                    child: Text("Nenhum dado a ser exibido!"),
                  );
                }
              }),
        ),
        body: Column(
          children: [
            Expanded(
              child: Container(
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: StreamBuilder<List<bool>>(
                      initialData: filterchips,
                      stream: widget.blocFilter.output,
                      builder: (context, snapshot) {
                        isSelectedLines = snapshot.data[0];
                        isSelectedRoutes = snapshot.data[1];
                        isSelectedTerminals = snapshot.data[2];
                        isSelectedBusStops = snapshot.data[3];

                        return ListView.builder(
                          itemCount: _getList().length,
                          scrollDirection: Axis.vertical,
                          itemBuilder: (context, index) {
                            List<dynamic> lists = _getList();
                            dynamic element = lists[index];
                            return element is Bus
                                ? Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Container(
                                      //margin: EdgeInsets.all(bottom: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(18)),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(0.5),
                                            spreadRadius: 5,
                                            blurRadius: 7,
                                            offset: Offset(0,
                                                3), // changes position of shadow
                                          ),
                                        ],
                                      ),
                                      child: ListTile(
                                        onTap: () => _busSelected(element),
                                        leading: Badge(
                                          padding: element.line < 10
                                              ? EdgeInsets.symmetric(
                                                  vertical: 10, horizontal: 10)
                                              : element.id > 9 &&
                                                      element.id < 99
                                                  ? EdgeInsets.symmetric(
                                                      vertical: 6,
                                                      horizontal: 6)
                                                  : EdgeInsets.symmetric(
                                                      vertical: 5,
                                                      horizontal: 5),
                                          badgeContent: Text(
                                            element.line.toString(),
                                            style: TextStyle(
                                                color: Constants.white_grey),
                                          ),
                                          badgeColor: Constants.green,
                                        ),
                                        trailing: Padding(
                                          padding: const EdgeInsets.only(
                                              top: 4.0, left: 4.0),
                                          child: Icon(
                                            MdiIcons.circle,
                                            size: 12,
                                            color: element.isAvailable
                                                ? Constants.green
                                                : Constants.accent_scarlat,
                                          ),
                                        ),
                                        title: RichText(
                                            text: TextSpan(
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontFamily: 'Abel',
                                                ),
                                                children: [
                                              TextSpan(
                                                  text: element
                                                      .itinerary
                                                      .route
                                                      .start
                                                      .adress
                                                      .neighborhood,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        Constants.accent_blue,
                                                  )),
                                              TextSpan(
                                                  text: ' : ',
                                                  style: TextStyle(
                                                    color:
                                                        Constants.accent_blue,
                                                  )),
                                              TextSpan(
                                                  text: element.itinerary.route
                                                      .start.adress.street,
                                                  style: TextStyle(
                                                    color:
                                                        Constants.accent_blue,
                                                  ))
                                            ])),
                                        subtitle: RichText(
                                            text: TextSpan(
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontFamily: 'Abel',
                                                ),
                                                children: [
                                              TextSpan(
                                                  text: element.itinerary.route
                                                      .end.adress.neighborhood,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        Constants.accent_blue,
                                                  )),
                                              TextSpan(
                                                  text: ' : ',
                                                  style: TextStyle(
                                                    color:
                                                        Constants.accent_blue,
                                                  )),
                                              TextSpan(
                                                  text: element.itinerary.route
                                                      .end.adress.street,
                                                  style: TextStyle(
                                                    color:
                                                        Constants.accent_blue,
                                                  ))
                                            ])),
                                      ),
                                    ),
                                  )
                                : element is Routes
                                    ? Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Container(
                                          //margin: EdgeInsets.only(bottom: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(18)),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.grey
                                                    .withOpacity(0.5),
                                                spreadRadius: 5,
                                                blurRadius: 7,
                                                offset: Offset(0,
                                                    3), // changes position of shadow
                                              ),
                                            ],
                                          ),
                                          child: Container(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                      16, 12, 16, 12),
                                              child: Row(
                                                children: [
                                                  Align(
                                                      alignment:
                                                          Alignment.centerLeft,
                                                      child: _leading(element)),
                                                  Expanded(
                                                    child: Padding(
                                                      padding: const EdgeInsets
                                                              .fromLTRB(
                                                          32, 0, 0, 0),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          _subtitle(element),
                                                          SizedBox(
                                                            height: 10,
                                                          ),
                                                          _lines(element),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                    : Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Container(
                                          //margin: EdgeInsets.only(bottom: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(18)),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.grey
                                                    .withOpacity(0.5),
                                                spreadRadius: 5,
                                                blurRadius: 7,
                                                offset: Offset(0,
                                                    3), // changes position of shadow
                                              ),
                                            ],
                                          ),
                                          child: ListTile(
                                            isThreeLine: false,
                                            onTap: () =>
                                                _busStopSelected(element),
                                            leading: Badge(
                                              padding: element.id < 10
                                                  ? EdgeInsets.symmetric(
                                                      vertical: 10,
                                                      horizontal: 10)
                                                  : EdgeInsets.symmetric(
                                                      vertical: 6,
                                                      horizontal: 6),
                                              badgeColor: element.isTerminal
                                                  ? Constants.accent_blue
                                                  : Constants.brightness_blue,
                                              badgeContent: Text(
                                                  element.id.toString(),
                                                  style: TextStyle(
                                                      color: Constants
                                                          .white_grey)),
                                            ),
                                            title: Text(
                                                element.adress == null
                                                    ? 'Indisponível'
                                                    : element
                                                        .adress.neighborhood,
                                                style: TextStyle(
                                                    color:
                                                        Constants.accent_blue,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            subtitle: Text(
                                                element.adress == null
                                                    ? 'Indisponível'
                                                    : element.adress.street),
                                          ),
                                        ),
                                      );
                          },
                        );
                      }),
                ),
              ),
            )
          ],
        ));
  }

  _busSelected(Bus bus) {
    CameraPosition cameraPosition = CameraPosition(
        target: LatLng(bus.realTimeData.latitude, bus.realTimeData.longitude),
        zoom: 20);
    widget.blocCameraPosition.sendCameraPosition(cameraPosition);
    widget.blocBus.sendBus(bus);
    widget.blocNavigation.changeNavigationIndex(Navigation.MAP);
  }

  _busStopSelected(BusStop busStop) {
    CameraPosition cameraPosition = CameraPosition(
        target: LatLng(busStop.latitude, busStop.longitude), zoom: 20);
    widget.blocCameraPosition.sendCameraPosition(cameraPosition);
    widget.blocBusStop.sendBus(busStop);
    widget.blocNavigation.changeNavigationIndex(Navigation.MAP);
  }
}
