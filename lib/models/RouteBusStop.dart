import 'package:json_annotation/json_annotation.dart';

part 'RouteBusStop.g.dart';

@JsonSerializable(explicitToJson: true)
class RouteBusStop {
  int routeId;
  int busStopId;

  RouteBusStop({
    this.routeId,
    this.busStopId,
  });

  factory RouteBusStop.fromJson(Map<String, dynamic> data) =>
      _$RouteBusStopFromJson(data);

  Map<String, dynamic> toJson() => _$RouteBusStopToJson(this);
}
