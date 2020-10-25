import 'package:app_buscabus/models/Bus.dart';
import 'package:json_annotation/json_annotation.dart';

part 'Person.g.dart';

@JsonSerializable(explicitToJson: true)
class Person {
  int id;
  String deviceAdress;
  Bus bus;
  double latitude;
  double longitude;

  Person({this.id, this.deviceAdress, this.bus,this.latitude,this.longitude});

  factory Person.fromJson(Map<String, dynamic> data) => _$PersonFromJson(data);

  Map<String, dynamic> toJson() => _$PersonToJson(this);
}
