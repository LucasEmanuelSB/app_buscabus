import 'package:app_buscabus/Constants.dart';
import 'package:app_buscabus/models/Bus.dart';
import 'package:app_buscabus/models/BusStop.dart';
import 'package:app_buscabus/models/Itinerary.dart';
import 'package:app_buscabus/models/Routes.dart';
import 'package:badges/badges.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:app_buscabus/Screens/BottomNavigationBar/ScreensPageView.dart';

class MuralScreen extends StatefulWidget {
  MuralScreen({this.blocFilter});
  final FilterBloc blocFilter;

  bool isSelectedLines = false;
  bool isSelectedRoutes = false;
  bool isSelectedBusStops = false;
  bool isSelectedTerminals = false;
  @override
  _MuralScreenState createState() => _MuralScreenState();
}

class _MuralScreenState extends State<MuralScreen> {
  Future<List<dynamic>> _getList() async {
    http.Response responseBuses = await http.get(Constants.url_buses);
    http.Response responseBusStops = await http.get(Constants.url_busStops);
    http.Response responseRoutes = await http.get(Constants.url_routes);
    try {
      List<dynamic> dadosJsonBuses = json.decode(responseBuses.body);
      List<dynamic> dadosJsonBusStops = json.decode(responseBusStops.body);
      List<dynamic> dadosJsonRoutes = json.decode(responseRoutes.body);

      List<Bus> buses = dadosJsonBuses.map<Bus>((map) {
        return Bus.fromJson(map);
      }).toList();

      List<BusStop> busStops = dadosJsonBusStops.map<BusStop>((map) {
        return BusStop.fromJson(map);
      }).toList();

      List<Routes> routes = dadosJsonRoutes.map<Routes>((map) {
        return Routes.fromJson(map);
      }).toList();

      List<BusStop> terminals = new List<BusStop>();
      List<dynamic> lists = new List<dynamic>();
      busStops.removeWhere((element) => element.adress == null);

      for (int i = 0; i < busStops.length; i++) {
        if (busStops[i].isTerminal) {
          terminals.add(busStops[i]);
          busStops.removeAt(i);
          i--;
        }
      }

      if (widget.isSelectedLines)
        lists = [lists, buses].expand((x) => x).toList();

      if (widget.isSelectedRoutes)
        lists = [lists, routes].expand((x) => x).toList();

      if (widget.isSelectedBusStops)
        lists = [lists, busStops].expand((x) => x).toList();

      if (widget.isSelectedTerminals)
        lists = [lists, terminals].expand((x) => x).toList();

      return lists;
    } catch (error) {
      print(error);
      return null;
    }
  }

  Widget _leading(Routes route) {
    return Badge(
      badgeColor: Constants.accent_grey,
      padding: route.id < 10 ? EdgeInsets.symmetric(vertical: 10, horizontal: 10): EdgeInsets.symmetric(vertical: 0, horizontal: 10),
      badgeContent: Text(route.id.toString(), style: TextStyle(color: Constants.white_grey)));
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

/*   Widget _lines(Routes route) {
    return Row(
      children: _generateRouteLines(route.itinerarys),
    );
  } */

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
      children.add(new Text(itinerarys[i].bus.line.toString()));
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
            shape: i == 0 || i == (path.length + 1)
                ? BadgeShape.square
                : BadgeShape.circle,
            borderRadius: 12,
            badgeContent: Text(
              i == 0 || i == (path.length + 1)
                  ? busStop.adress.neighborhood
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
                  widget.isSelectedLines = snapshot.data[0];
                  widget.isSelectedRoutes = snapshot.data[1];
                  widget.isSelectedTerminals = snapshot.data[2];
                  widget.isSelectedBusStops = snapshot.data[3];
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
                                color: widget.isSelectedLines
                                    ? Constants.white_grey
                                    : Constants.accent_blue),
                            selected: widget.isSelectedLines,
                            onSelected: (bool selected) {
                              setState(() {
                                widget.isSelectedLines =
                                    !widget.isSelectedLines;
                                widget.blocFilter
                                    .changeChips(0, widget.isSelectedLines);
                              });
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
                                color: widget.isSelectedRoutes
                                    ? Constants.white_grey
                                    : Constants.accent_blue),
                            selected: widget.isSelectedRoutes,
                            onSelected: (bool selected) {
                              setState(() {
                                widget.isSelectedRoutes =
                                    !widget.isSelectedRoutes;
                                widget.blocFilter
                                    .changeChips(1, widget.isSelectedRoutes);
                              });
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
                                color: widget.isSelectedTerminals
                                    ? Constants.white_grey
                                    : Constants.accent_blue),
                            selected: widget.isSelectedTerminals,
                            onSelected: (bool selected) {
                              setState(() {
                                widget.isSelectedTerminals =
                                    !widget.isSelectedTerminals;
                                widget.blocFilter
                                    .changeChips(2, widget.isSelectedTerminals);
                              });
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
                                color: widget.isSelectedBusStops
                                    ? Constants.white_grey
                                    : Constants.accent_blue),
                            selected: widget.isSelectedBusStops,
                            onSelected: (bool selected) {
                              setState(() {
                                widget.isSelectedBusStops =
                                    !widget.isSelectedBusStops;
                                widget.blocFilter
                                    .changeChips(3, widget.isSelectedBusStops);
                              });
                            },
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
        body: Column(
          children: [
            Expanded(
              child: Container(
                child: FutureBuilder<List<dynamic>>(
                  future: _getList(),
                  builder: (context, snapshot) {
                    switch (snapshot.connectionState) {
                      case ConnectionState.none:
                        print("Não há conexão");
                        break;
                      case ConnectionState.waiting:
                        return Center(child: CircularProgressIndicator());
                        break;
                      case ConnectionState.active:
                        print("Conexão ativa");
                        break;
                      case ConnectionState.done:
                        print("done");
                        if (snapshot.hasData) {
                          if (snapshot.data.isNotEmpty) {
                            return Padding(
                              padding: const EdgeInsets.all(6.0),
                              child: ListView.builder(
                                itemCount: snapshot.data.length,
                                scrollDirection: Axis.vertical,
                                itemBuilder: (context, index) {
                                  List<dynamic> list = snapshot.data;
                                  dynamic element = list[index];

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
                                              // onTap: () => {}, //_details(),
                                              leading: Badge(
                                                padding: element.line < 10 ? EdgeInsets.symmetric(vertical: 10, horizontal: 10): element.id > 9 && element.id < 99 ? EdgeInsets.symmetric(vertical: 6, horizontal: 6) : EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                                                badgeContent: Text(
                                                  element.line.toString(),
                                                  style: TextStyle(
                                                      color:
                                                          Constants.white_grey),
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
                                                      : Constants
                                                          .accent_scarlat,
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
                                                        text: element.itinerary.route.start
                                                          .adress.neighborhood,
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          color: Constants
                                                              .accent_blue,
                                                        )),
                                                    TextSpan(
                                                        text: ' : ',
                                                        style: TextStyle(
                                                          color: Constants
                                                              .accent_blue,
                                                        )),
                                                    TextSpan(
                                                        text: element.itinerary.route.start
                                                          .adress.street,
                                                        style: TextStyle(
                                                          color: Constants
                                                              .accent_blue,
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
                                                        text: element.itinerary.route.end
                                                          .adress.neighborhood,
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          color: Constants
                                                              .accent_blue,
                                                        )),
                                                    TextSpan(
                                                        text: ' : ',
                                                        style: TextStyle(
                                                          color: Constants
                                                              .accent_blue,
                                                        )),
                                                    TextSpan(
                                                        text: element.itinerary.route.end
                                                          .adress.street,
                                                        style: TextStyle(
                                                          color: Constants
                                                              .accent_blue,
                                                        ))
                                                  ])),
                                            ),
                                          ),
                                        )
                                      : element is Routes
                                          ? Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Container(
                                                //margin: EdgeInsets.only(bottom: 8),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.all(
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
                                                    padding: const EdgeInsets
                                                        .fromLTRB(16, 12, 16, 12),
                                                    child: Row(
                                                      //direction: Axis.vertical,
                                                      children: [
                                                        Align(
                                                            alignment: Alignment
                                                                .centerLeft,
                                                            child: _leading(
                                                                element)),
                                                        Expanded(
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                        .fromLTRB(
                                                                    32,
                                                                    0,
                                                                    0,
                                                                    0),
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                /* _lines(element),
                                                                SizedBox(
                                                                  height: 10,
                                                                ), */
                                                                _subtitle(
                                                                    element),
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
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Container(
                                                //margin: EdgeInsets.only(bottom: 8),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.all(
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

                                                  /* selected: false, */
                                                  leading: Badge(
                                                    padding: element.id < 10 ?
                                                        EdgeInsets.symmetric(
                                                            vertical: 10,
                                                            horizontal: 10) : EdgeInsets.symmetric(
                                                            vertical: 6,
                                                            horizontal: 6),
                                                    badgeColor: element
                                                            .isTerminal
                                                        ? Constants.accent_blue
                                                        : Constants
                                                            .brightness_blue,
                                                    badgeContent: Text(
                                                        element.id.toString(),
                                                        style: TextStyle(
                                                            color: Constants
                                                                .white_grey)),
                                                  ),
                                                  title: Text(
                                                      element.adress == null
                                                          ? 'Indisponível'
                                                          : element.adress
                                                              .neighborhood,
                                                      style: TextStyle(
                                                          color: Constants
                                                              .accent_blue,
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                  subtitle: Text(
                                                      element.adress == null
                                                          ? 'Indisponível'
                                                          : element
                                                              .adress.street),
                                                ),
                                              ),
                                            );
                                },
                              ),
                            );
                          } else {
                            return Center(
                              child: Text("Nenhum dado a ser exibido!"),
                            );
                          }
                        } else {
                          return Center(
                            child: Text("Nenhum dado a ser exibido!"),
                          );
                        }
                        break;
                    }

                    return Center(
                      child: Text(snapshot.data.toString()),
                    );
                  },
                ),
              ),
            )
          ],
        ));
  }
}
