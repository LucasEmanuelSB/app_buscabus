import 'package:json_annotation/json_annotation.dart';

part 'GlobalPosition.g.dart';

@JsonSerializable(explicitToJson: true)
class GlobalPosition {
  int id;
  double latitude;
  double longitude;
  String createdAt;
  String updatedAt;

  GlobalPosition(
      {this.id, this.latitude, this.longitude, this.createdAt, this.updatedAt});

  factory GlobalPosition.fromJson(Map<String, dynamic> data) =>
      _$GlobalPositionFromJson(data);

  Map<String, dynamic> toJson() => _$GlobalPositionToJson(this);
}
