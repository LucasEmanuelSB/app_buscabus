import 'package:app_buscabus/Constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

import 'package:app_buscabus/models/BusDriver.dart';
import 'package:app_buscabus/models/Itinerary.dart';
import 'package:app_buscabus/models/GlobalPosition.dart';
import 'package:json_annotation/json_annotation.dart';
part 'Bus.g.dart';

@JsonSerializable(explicitToJson: true)
class Bus {
  int id;
  int line;
  bool isAvailable;
  double velocity;
  double eta;
  BusDriver busDriver;
  Itinerary itinerary;
  GlobalPosition currentPosition;

  Bus(
      {this.id,
      this.line,
      this.isAvailable,
      this.busDriver,
      this.itinerary,
      this.currentPosition,
      this.velocity,
      this.eta
      });

  factory Bus.fromJson(Map<String, dynamic> data) => _$BusFromJson(data);

  Map<String, dynamic> toJson() => _$BusToJson(this);

  static Future<List<dynamic>> getList() async {
    http.Response response = await http.get(Constants.url_buses);

    try {
      List<dynamic> dadosJson = json.decode(response.body);
      print(dadosJson);
      List<Bus> buses = dadosJson.map<Bus>((map) {
        return Bus.fromJson(map);
        // return Bus.converterJson(map);
      }).toList();
      return buses;
    } catch (error) {
      print(error);
      print("\n Status Code : ${response.statusCode.toString()} \n");
      return null;
    }
  }

  updateCurrentPosition() async {
    http.Response response = await http.get(Constants.url_globalPosition +
        "/" +
        this.currentPosition.id.toString());
    var dadosJson = json.decode(response.body);
    this.currentPosition.latitude = dadosJson["latitude"];
    this.currentPosition.longitude = dadosJson["longitude"];
  }
}
