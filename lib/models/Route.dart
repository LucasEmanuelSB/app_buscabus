import 'package:app_buscabus/models/BusStop.dart';
import 'package:app_buscabus/models/Itinerary.dart';
import 'package:app_buscabus/models/Point.dart';
import 'package:json_annotation/json_annotation.dart';

part 'Route.g.dart';

@JsonSerializable(explicitToJson: true)
class Route {
  int id;
  List<BusStop> busStops;
  List<Itinerary> itinerarys;
  List<Point> points;

  Route({this.id, this.busStops, this.itinerarys, this.points});

  factory Route.fromJson(Map<String, dynamic> data) => _$RouteFromJson(data);

  Map<String, dynamic> toJson() => _$RouteToJson(this);

/* 
  static Future<List<Route>> getList() async {
    String url = Constants.url_routes;
    print("\n\n" + url + "\n\n");
    http.Response response = await http.get(url);

    try {
      List<dynamic> dadosJson = json.decode(response.body);
      print(dadosJson);
      List<Route> routes = dadosJson.map<Route>((map) {
        return Route.fromJson(map);
        // return Route.converterJson(map);
      }).toList();
      return routes;
    } catch (error) {
      print(error);
      print("\n Status Code : ${response.statusCode.toString()} \n");
      return null;
    }
  } */
}
