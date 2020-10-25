// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'RatingBusDriver.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RatingBusDriver _$RatingBusDriverFromJson(Map<String, dynamic> json) {
  return RatingBusDriver(
      userId: json['userId'] as int,
      busDriverId: json['busDriverId'] as int,
     rate: double.parse(json['rate']));
}

Map<String, dynamic> _$RatingBusDriverToJson(RatingBusDriver instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'busDriverId': instance.busDriverId,
      'rate': instance.rate
    };
