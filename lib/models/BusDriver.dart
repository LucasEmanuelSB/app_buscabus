import 'package:json_annotation/json_annotation.dart';

part 'BusDriver.g.dart';

@JsonSerializable()
class BusDriver {
  int id;
  String name;

  BusDriver(
      {this.id, this.name});

  factory BusDriver.fromJson(Map<String, dynamic> data) =>
      _$BusDriverFromJson(data);

  Map<String, dynamic> toJson() => _$BusDriverToJson(this);
  
/*   static Future<List<BusDriver>> getList() async {
    http.Response response = await http.get(Constants.url_bus_drivers);

    try {
      List<dynamic> dadosJson = json.decode(response.body);
      print(dadosJson);
      List<BusDriver> busDrivers = dadosJson.map<BusDriver>((map) {
        return BusDriver.fromJson(map);
        // return BusDriver.converterJson(map);
      }).toList();
      return busDrivers;
    } catch (error) {
      print(error);
      print("\n Status Code : ${response.statusCode.toString()} \n");
      return null;
    }
  } */
}
