// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Company.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Company _$CompanyFromJson(Map<String, dynamic> json) {
  return Company(
      id: json['id'] as int,
      name: json['name'] as String,
      averageRate: double.parse(json['averageRate'] as String),
      usersRatings: (json['usersRatings'] as List)
          ?.map((e) => e == null
              ? null
              : RatingCompany.fromJson(e as Map<String, dynamic>))
          ?.toList());
}

Map<String, dynamic> _$CompanyToJson(Company instance) => <String, dynamic>{

      'name': instance.name,
      'averageRate': instance.averageRate,
      'usersRatings': instance.usersRatings?.map((e) => e?.toJson())?.toList()
    };
