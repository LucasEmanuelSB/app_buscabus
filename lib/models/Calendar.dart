import 'package:json_annotation/json_annotation.dart';

part 'Calendar.g.dart';

@JsonSerializable()
class Calendar {
  int id;
  List<String> weeks;
  List<String> weekendsHolidays;

  Calendar({this.id, this.weeks, this.weekendsHolidays});

  factory Calendar.fromJson(Map<String, dynamic> data) =>
      _$CalendarFromJson(data);

  Map<String, dynamic> toJson() => _$CalendarToJson(this);
/*   static Future<List<Calendar>> getList() async {
    http.Response response = await http.get(Constants.url_calendars);

    try {
      List<dynamic> dadosJson = json.decode(response.body);
      print(dadosJson);
      List<Calendar> calendars = dadosJson.map<Calendar>((map) {
        return Calendar.fromJson(map);
        // return Calendar.converterJson(map);
      }).toList();
      return calendars;
    } catch (error) {
      print(error);
      print("\n Status Code : ${response.statusCode.toString()} \n");
      return null;
    }
  } */
}
