// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Favorite.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Favorite _$FavoriteFromJson(Map<String, dynamic> json) {
  return Favorite(
      busId: (json['busId'] as List)?.map((e) => e as int)?.toList(),
      busStopId: (json['busStopId'] as List)?.map((e) => e as int)?.toList(),
      itineraryId:
          (json['itineraryId'] as List)?.map((e) => e as int)?.toList());
}

Map<String, dynamic> _$FavoriteToJson(Favorite instance) => <String, dynamic>{
      'busId': instance.busId,
      'busStopId': instance.busStopId,
      'itineraryId': instance.itineraryId
    };
