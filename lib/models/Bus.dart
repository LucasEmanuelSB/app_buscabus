import 'package:app_buscabus/Constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

import 'package:app_buscabus/models/BusDriver.dart';
import 'package:app_buscabus/models/Itinerary.dart';
import 'package:app_buscabus/models/RealTimeData.dart';
import 'package:json_annotation/json_annotation.dart';
part 'Bus.g.dart';

@JsonSerializable(explicitToJson: true)
class Bus {
  int id;
  int line;
  bool isAvailable;
  BusDriver busDriver;
  Itinerary itinerary;
  RealTimeData realTimeData;

  Bus(
      {this.id,
      this.line,
      this.isAvailable,
      this.busDriver,
      this.itinerary,
      this.realTimeData});

  factory Bus.fromJson(Map<String, dynamic> data) => _$BusFromJson(data);

  Map<String, dynamic> toJson() => _$BusToJson(this);

  static Future<List<Bus>> getList() async {
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

  updateRealTimeData() async {
    http.Response response = await http.get(
        Constants.url_realTimeData + "/" + this.realTimeData.id.toString());
    var dadosJson = json.decode(response.body);
    this.realTimeData = RealTimeData.fromJson(dadosJson);
  }
}
