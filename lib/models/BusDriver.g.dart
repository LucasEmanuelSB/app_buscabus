// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'BusDriver.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BusDriver _$BusDriverFromJson(Map<String, dynamic> json) {
  return BusDriver(
      id: json['id'] as int,
      name: json['name'] as String,
      averageRate: double.parse(json['averageRate'] as String),
      usersRatings: (json['usersRatings'] as List)
          ?.map((e) => e == null
              ? null
              : RatingBusDriver.fromJson(e as Map<String, dynamic>))
          ?.toList(),
      buses: (json['buses'] as List)
          ?.map(
              (e) => e == null ? null : Bus.fromJson(e as Map<String, dynamic>))
          ?.toList());
}

Map<String, dynamic> _$BusDriverToJson(BusDriver instance) => <String, dynamic>{

      'name': instance.name,
      'averageRate': instance.averageRate,
      'usersRatings': instance.usersRatings,
      'buses': instance.buses
    };
