// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Bus.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Bus _$BusFromJson(Map<String, dynamic> json) {
  return Bus(
      id: json['id']== null  ? null: json['id'] as int,
      line: json['line'] as int,
      isAvailable: json['isAvailable'] as bool,
      velocity: (json['velocity'] as num)?.toDouble(),
      busDriver: json['busDriver'] == null
          ? null
          : BusDriver.fromJson(json['busDriver'] as Map<String, dynamic>),
      itinerary: json['itinerary'] == null
          ? null
          : Itinerary.fromJson(json['itinerary'] as Map<String, dynamic>),
      currentPosition: json['currentPosition'] == null
          ? null
          : GlobalPosition.fromJson(json['currentPosition'] as Map<String, dynamic>));
}

Map<String, dynamic> _$BusToJson(Bus instance) => <String, dynamic>{
      'line': instance.line,
      'isAvailable': instance.isAvailable,
      'busDriver': instance.busDriver?.toJson(),
      'itinerary': instance.itinerary?.toJson(),
      'currentPosition': instance.currentPosition?.toJson(),
    };
