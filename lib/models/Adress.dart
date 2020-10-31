import 'package:app_buscabus/models/GlobalPosition.dart';
import 'package:json_annotation/json_annotation.dart';

part 'Adress.g.dart';

@JsonSerializable()
class Adress {
  int id;
  String country;
  String uf;
  String city;
  String neighborhood;
  String street;
  String cep;
  String number;

  Adress(
      {this.id,
      this.country,
      this.uf,
      this.city,
      this.neighborhood,
      this.street,
      this.cep,
      this.number});

  factory Adress.fromJson(Map<String, dynamic> data) => _$AdressFromJson(data);

  Map<String, dynamic> toJson() => _$AdressToJson(this);

/*   static Future<List<Adress>> getList() async {
    http.Response response = await http.get(Constants.url_adresses);
    try {
      List<dynamic> dadosJson = json.decode(response.body);
      print(dadosJson);
      List<Adress> adresses = dadosJson.map<Adress>((map) {
        return Adress.fromJson(map);
        // return Adress.converterJson(map);
      }).toList();
      return adresses;
    } catch (error) {
      print(error);
      print("\n Status Code : ${response.statusCode.toString()} \n");
      return null;
    } 
  }*/
}
