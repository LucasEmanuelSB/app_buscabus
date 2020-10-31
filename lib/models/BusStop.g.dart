// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'BusStop.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BusStop _$BusStopFromJson(Map<String, dynamic> json) {
  return BusStop(
      id: json['id'] == null ? null : json['id'] as int,
      isTerminal: json['isTerminal'] as bool,
      latitude: (json['latitude'] as num)?.toDouble(),
      longitude: (json['longitude'] as num)?.toDouble(),
      adress: json['adress'] == null
          ? null
          : Adress.fromJson(json['adress'] as Map<String, dynamic>));
}

Map<String, dynamic> _$BusStopToJson(BusStop instance) => <String, dynamic>{
      'isTerminal': instance.isTerminal,
      'adress': instance.adress?.toJson(),
      'latitude': instance.latitude,
      'longitude': instance.longitude,
    };
