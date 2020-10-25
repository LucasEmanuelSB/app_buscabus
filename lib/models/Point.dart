import 'package:app_buscabus/models/Route.dart';
import 'package:json_annotation/json_annotation.dart';

part 'Point.g.dart';

@JsonSerializable()
class Point {
  int id;
  double latitude;
  double longitude;
  Route route;

  Point({this.id, this.latitude, this.longitude, this.route});

  factory Point.fromJson(Map<String, dynamic> data) => _$PointFromJson(data);

  Map<String, dynamic> toJson() => _$PointToJson(this);

/*   static Future<List<Point>> getList() async {
    http.Response response = await http.get(Constants.url_points);

    try {
      List<dynamic> dadosJson = json.decode(response.body);
      print(dadosJson);
      List<Point> points = dadosJson.map<Point>((map) {
        return Point.fromJson(map);
        // return Itinerary.converterJson(map);
      }).toList();
      return points;
    } catch (error) {
      print(error);
      print("\n Status Code : ${response.statusCode.toString()} \n");
      return null;
    }
  } */
}
