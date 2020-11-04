import 'package:json_annotation/json_annotation.dart';

part 'RealTimeData.g.dart';

@JsonSerializable(explicitToJson: true)
class RealTimeData {
  int id;
  double latitude;
  double longitude;
  double velocity;
  int nDevices;
  String createdAt;
  String updatedAt;

  RealTimeData(
      {this.id, this.latitude, this.longitude, this.velocity,this.nDevices,this.createdAt, this.updatedAt});

  factory RealTimeData.fromJson(Map<String, dynamic> data) =>
      _$RealTimeDataFromJson(data);

  Map<String, dynamic> toJson() => _$RealTimeDataToJson(this);
}
