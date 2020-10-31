// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Routes.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Routes _$RoutesFromJson(Map<String, dynamic> json) {
  return Routes(
      id: json['id'] as int,
      start: json['start'] == null
          ? null
          : BusStop.fromJson(json['start'] as Map<String, dynamic>),
      end: json['end'] == null
          ? null
          : BusStop.fromJson(json['start'] as Map<String, dynamic>),
      busStops: (json['path'] as List)
          ?.map((e) =>
              e == null ? null : BusStop.fromJson(e as Map<String, dynamic>))
          ?.toList(),
      itinerarys: (json['itinerarys'] as List)
          ?.map((e) =>
              e == null ? null : Itinerary.fromJson(e as Map<String, dynamic>))
          ?.toList()
      );
}

Map<String, dynamic> _$RoutesToJson(Routes instance) => <String, dynamic>{
      'busStops': instance.busStops?.map((e) => e?.toJson())?.toList(),
    };
