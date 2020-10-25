import 'package:app_buscabus/models/Route.dart';
import 'package:app_buscabus/models/Bus.dart';
import 'package:app_buscabus/models/BusStop.dart';
import 'package:app_buscabus/models/Calendar.dart';
import 'package:json_annotation/json_annotation.dart';

part 'Itinerary.g.dart';

@JsonSerializable(explicitToJson: true)
class Itinerary {
  int id;
  Bus bus;
  Route route;
  Calendar calendar;

  Itinerary(
      {this.id,
      this.bus,
      this.route,
      this.calendar});

  factory Itinerary.fromJson(Map<String, dynamic> data) =>
      _$ItineraryFromJson(data);

  Map<String, dynamic> toJson() => _$ItineraryToJson(this);
/*   static Future<List<Itinerary>> getList() async {
    http.Response response = await http.get(Constants.url_itinerarys);

    try {
      List<dynamic> dadosJson = json.decode(response.body);
      print(dadosJson);
      List<Itinerary> itinerarys = dadosJson.map<Itinerary>((map) {
        return Itinerary.fromJson(map);
        // return Itinerary.converterJson(map);
      }).toList();
      return itinerarys;
    } catch (error) {
      print(error);
      print("\n Status Code : ${response.statusCode.toString()} \n");
      return null;
    }
  } */
}
