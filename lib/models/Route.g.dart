// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Route.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Route _$RouteFromJson(Map<String, dynamic> json) {
  return Route(
      id: json['id'] as int,
      busStops: (json['busStops'] as List)
          ?.map((e) =>
              e == null ? null : BusStop.fromJson(e as Map<String, dynamic>))
          ?.toList(),
      itinerarys: (json['itinerarys'] as List)
          ?.map((e) =>
              e == null ? null : Itinerary.fromJson(e as Map<String, dynamic>))
          ?.toList(),
      points: (json['points'] as List)
          ?.map((e) =>
              e == null ? null : Point.fromJson(e as Map<String, dynamic>))
          ?.toList());
}

Map<String, dynamic> _$RouteToJson(Route instance) => <String, dynamic>{
  
      'busStops': instance.busStops?.map((e) => e?.toJson())?.toList(),
      'itinerarys': instance.itinerarys?.map((e) => e?.toJson())?.toList(),
      'points': instance.points?.map((e) => e?.toJson())?.toList()
    };
