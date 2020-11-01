import 'package:app_buscabus/Constants.dart';
import 'package:app_buscabus/models/BusStop.dart';
import 'package:app_buscabus/models/Itinerary.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
part 'Routes.g.dart';

@JsonSerializable(explicitToJson: true)
class Routes {
  int id;
  List<BusStop> busStops;
  BusStop start;
  BusStop end;
  List<Itinerary> itinerarys;
  Routes({this.id, this.busStops, this.start, this.end, this.itinerarys});

  factory Routes.fromJson(Map<String, dynamic> data) => _$RoutesFromJson(data);

  Map<String, dynamic> toJson() => _$RoutesToJson(this);

  static Future<List<Routes>> getList() async {
    String url = Constants.url_routes;
    print("\n\n" + url + "\n\n");
    http.Response response = await http.get(url);

    try {
      List<dynamic> dadosJson = json.decode(response.body);
      print(dadosJson);
      List<Routes> routes = dadosJson.map<Routes>((map) {
        return Routes.fromJson(map);
        // return Route.converterJson(map);
      }).toList();
      return routes;
    } catch (error) {
      print(error);
      print("\n Status Code : ${response.statusCode.toString()} \n");
      return null;
    }
  }
}
