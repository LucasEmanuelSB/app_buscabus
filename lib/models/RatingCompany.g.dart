// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'RatingCompany.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RatingCompany _$RatingCompanyFromJson(Map<String, dynamic> json) {
  return RatingCompany(
      userId: json['userId'] as int,
      userCompany: json['userCompany'] as int,
      rate: double.parse(json['rate']));
}

Map<String, dynamic> _$RatingCompanyToJson(RatingCompany instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'userCompany': instance.userCompany,
      'rate': instance.rate
    };
