// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'RealTimeData.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RealTimeData _$RealTimeDataFromJson(Map<String, dynamic> json) {
  return RealTimeData(
    id: json['id'] == null ? null : json['id'] as int,
    latitude: (json['latitude'] as num)?.toDouble(),
    longitude: (json['longitude'] as num)?.toDouble(),
    velocity: (json['velocity'] as num)?.toDouble(),
    nDevices: json['nDevices'] == null ? null : json['nDevices'] as int,
    createdAt: (json['createdAt'] as String),
    updatedAt: (json['updatedAt'] as String),
  );
}

Map<String, dynamic> _$RealTimeDataToJson(RealTimeData instance) =>
    <String, dynamic>{
/*       'id': instance.id, */
      'latitude': instance.latitude,
      'longitude': instance.longitude,
    };
