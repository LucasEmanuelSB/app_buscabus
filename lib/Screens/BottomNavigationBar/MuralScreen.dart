import 'package:app_buscabus/Constants.dart';
import 'package:app_buscabus/models/Bus.dart';
import 'package:app_buscabus/models/BusStop.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:app_buscabus/Screens/BottomNavigationBar/ScreensPageView.dart';

class MuralScreen extends StatefulWidget {
  MuralScreen({this.blocFilter});
  final FilterBloc blocFilter;

  bool isSelectedLine = false;
  bool isSelectedBusStop = false;
  bool isSelectedTerminals = false;
  @override
  _MuralScreenState createState() => _MuralScreenState();
}

class _MuralScreenState extends State<MuralScreen> {

  Future<List<dynamic>> _getList() async {
    
    http.Response responseBuses = await http.get(Constants.url_buses);
    http.Response responseBusStops = await http.get(Constants.url_busStops);

    try {
      List<dynamic> dadosJsonBuses = json.decode(responseBuses.body);
      List<dynamic> dadosJsonBusStops = json.decode(responseBusStops.body);

      List<Bus> buses = dadosJsonBuses.map<Bus>((map) {
        return Bus.fromJson(map);
      }).toList();

      List<BusStop> busStops = dadosJsonBusStops.map<BusStop>((map) {
        return BusStop.fromJson(map);
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

      if (widget.isSelectedLine)
        lists = [lists, buses].expand((x) => x).toList();

      if (widget.isSelectedBusStop)
        lists = [lists, busStops].expand((x) => x).toList();

      if (widget.isSelectedTerminals)
        lists = [lists, terminals].expand((x) => x).toList();
      return lists;
    } catch (error) {
      print(error);
      return null;
    }
  }

  _backScreenMap() {}

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
                  widget.isSelectedLine = snapshot.data[0];
                  widget.isSelectedBusStop = snapshot.data[2];
                  widget.isSelectedTerminals = snapshot.data[1];
                  return AppBar(
                    leading: IconButton(
                        icon: Icon(
                          Icons.menu,
                          color: Constants.accent_blue,
                        ),
                        onPressed: () => _backScreenMap()),
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
                                color: widget.isSelectedLine
                                    ? Constants.white_grey
                                    : Constants.accent_blue),
                            selected: widget.isSelectedLine,
                            onSelected: (bool selected) {
                              setState(() {
                                widget.isSelectedLine = !widget.isSelectedLine;
                                widget.blocFilter
                                    .changeChips(0, widget.isSelectedLine);
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
                                    .changeChips(1, widget.isSelectedTerminals);
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
                                color: widget.isSelectedBusStop
                                    ? Constants.white_grey
                                    : Constants.accent_blue),
                            selected: widget.isSelectedBusStop,
                            onSelected: (bool selected) {
                              setState(() {
                                widget.isSelectedBusStop =
                                    !widget.isSelectedBusStop;
                                widget.blocFilter
                                    .changeChips(2, widget.isSelectedBusStop);
                              });
                            },
                            selectedColor: Constants.brightness_blue,
                            checkmarkColor: Constants.white_grey),
                      ),
                    ],
                  );
                }
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
                                  String busStopsFromItinerarys = "";
                                  String startAdress = "Indisponível",
                                      endAdress = "Indisponível";
                                  int routeLenght;
                                  if (element is Bus) {
                                    if (element.itinerary != null &&
                                        element.itinerary.route != null &&
                                        element.itinerary.route.busStops !=
                                            null) {
                                      routeLenght = element
                                          .itinerary.route.busStops.length;
                                      element.itinerary.route.busStops[0]
                                                  .adress !=
                                              null
                                          ? startAdress = element
                                              .itinerary
                                              .route
                                              .busStops[0]
                                              .adress
                                              .neighborhood
                                          : startAdress = "Indisponível";

                                      element
                                                  .itinerary
                                                  .route
                                                  .busStops[routeLenght - 1]
                                                  .adress !=
                                              null
                                          ? endAdress = element
                                              .itinerary
                                              .route
                                              .busStops[routeLenght - 1]
                                              .adress
                                              .neighborhood
                                          : endAdress = "Indisponível";

                                      element.itinerary.route.busStops
                                          .forEach((elementList) {
                                        busStopsFromItinerarys =
                                            busStopsFromItinerarys +
                                                elementList.id.toString() +
                                                ' - ';
                                      });
                                    }
                                  }

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

                                              leading: Padding(
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
                                              title: Text(
                                                element.line.toString(),
                                                style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        Constants.accent_blue),
                                              ),

                                              subtitle: RichText(
                                                  text: TextSpan(
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontFamily: 'Abel',
                                                      ),
                                                      children: [
                                                    TextSpan(
                                                        text: startAdress,
                                                        style: TextStyle(
                                                          color: Constants
                                                              .accent_blue,
                                                        )),
                                                    TextSpan(
                                                        text: ' - ',
                                                        style: TextStyle(
                                                          color: Constants
                                                              .accent_blue,
                                                        )),
                                                    TextSpan(
                                                        text: endAdress,
                                                        style: TextStyle(
                                                          color: Constants
                                                              .accent_blue,
                                                        ))
                                                  ])),

                                              /* trailing: Padding(
                                                    padding: const EdgeInsets.all(8.0),
                                                   child: Icon(MdiIcons.arrow,),
                                                  ) */
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

                                              /* selected: false, */
                                              leading: Container(
                                                width: 25,
                                                height: 25,
                                                decoration: BoxDecoration(
                                                    color: element.isTerminal
                                                        ? Constants.accent_blue
                                                        : Constants
                                                            .brightness_blue,
                                                    border: Border.all(
                                                        width:
                                                            element.isTerminal
                                                                ? 0
                                                                : 1,
                                                        color: element
                                                                .isTerminal
                                                            ? Constants
                                                                .accent_blue
                                                            : Constants
                                                                .brightness_blue,
                                                        style:
                                                            BorderStyle.solid),
                                                    borderRadius:
                                                        BorderRadius.all(
                                                            Radius.circular(
                                                                50))),
                                                child: Center(
                                                  child: Text(
                                                    element.id.toString(),
                                                    style: TextStyle(
                                                        color: Constants
                                                            .white_grey,
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                ),
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
