// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Point.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Point _$PointFromJson(Map<String, dynamic> json) {
  return Point(
      id: json['id'] as int,
      latitude: (json['latitude'] as num)?.toDouble(),
      longitude: (json['longitude'] as num)?.toDouble(),
      route: json['route'] == null
          ? null
          : Route.fromJson(json['route'] as Map<String, dynamic>));
}

Map<String, dynamic> _$PointToJson(Point instance) => <String, dynamic>{

      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'route': instance.route
    };
