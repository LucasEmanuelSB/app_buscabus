import 'package:app_buscabus/Constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

import 'package:app_buscabus/models/Adress.dart';
import 'package:app_buscabus/models/Route.dart';
import 'package:json_annotation/json_annotation.dart';

part 'BusStop.g.dart';

@JsonSerializable(explicitToJson: true)
class BusStop {
  int id;
  bool isTerminal;
  Adress adress;
  List<Route> routes;

  BusStop({this.id, this.isTerminal, this.adress, this.routes});

  factory BusStop.fromJson(Map<String, dynamic> data) =>
      _$BusStopFromJson(data);

  Map<String, dynamic> toJson() => _$BusStopToJson(this);

  static Future<List<BusStop>> getList() async {
    http.Response response = await http.get(Constants.url_busStops);

    try {
      List<dynamic> dadosJson = json.decode(response.body);
      print(dadosJson);
      List<BusStop> busStops = dadosJson.map<BusStop>((map) {
        return BusStop.fromJson(map);

      }).toList();
      return busStops;
    } catch (error) {
      print(error);
      print("\n Status Code : ${response.statusCode.toString()} \n");
      return null;
    }
  }
}
