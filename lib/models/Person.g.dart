// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Person.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Person _$PersonFromJson(Map<String, dynamic> json) {
  return Person(
      id: json['id'] as int,
      deviceAdress: json['deviceAdress'] as String,
      bus: json['bus'] == null
          ? null
          : Bus.fromJson(json['bus'] as Map<String, dynamic>));
}

Map<String, dynamic> _$PersonToJson(Person instance) => <String, dynamic>{

      'deviceAdress': instance.deviceAdress,
      'bus': instance.bus?.toJson()
    };
