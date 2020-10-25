// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'BusStop.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BusStop _$BusStopFromJson(Map<String, dynamic> json) {
  return BusStop(
      id: json['id']== null  ? null: json['id'] as int,
      isTerminal: json['isTerminal'] as bool,
      
      adress: json['adress'] == null
          ? null
          : Adress.fromJson(json['adress'] as Map<String, dynamic>),
      routes: (json['routes'] as List)
          ?.map((e) =>
              e == null ? null : Route.fromJson(e as Map<String, dynamic>))
          ?.toList());
}

Map<String, dynamic> _$BusStopToJson(BusStop instance) => <String, dynamic>{
      'isTerminal': instance.isTerminal,
      'adress': instance.adress?.toJson(),
      'routes': instance.routes?.map((e) => e?.toJson())?.toList()
    };
