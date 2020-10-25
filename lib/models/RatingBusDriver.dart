import 'package:json_annotation/json_annotation.dart';

part 'RatingBusDriver.g.dart';

@JsonSerializable(explicitToJson: true)
class RatingBusDriver {
  int userId;
  int busDriverId;
  double rate;

  RatingBusDriver({this.userId, this.busDriverId, this.rate});

  factory RatingBusDriver.fromJson(Map<String, dynamic> data) =>
      _$RatingBusDriverFromJson(data);

  Map<String, dynamic> toJson() => _$RatingBusDriverToJson(this);
}
