// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'GlobalPosition.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GlobalPosition _$GlobalPositionFromJson(Map<String, dynamic> json) {
  return GlobalPosition(
      id: json['id']== null  ? null: json['id'] as int ,
      latitude: (json['latitude'] as num)?.toDouble(),
      longitude: (json['longitude'] as num)?.toDouble(),
      createdAt: (json['createdAt'] as String),
      updatedAt: (json['updatedAt'] as String),
);
}

Map<String, dynamic> _$GlobalPositionToJson(GlobalPosition instance) =>
    <String, dynamic>{
/*       'id': instance.id, */
      'latitude': instance.latitude,
      'longitude': instance.longitude,
    };
