// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'User.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) {
  return User(
      name: json['name'] as String,
      surname: json['surname'] as String,
      email: json['email'] as String,
      password: json['password'] as String,
      birthDate: json['birthDate'] as String,
      gender: json['gender'] as String,
      job: json['job'] as String,
      credits: (json['credits'] as num)?.toDouble(),
      isOnline: json['isOnline'] as bool,
      deviceAdress: json['deviceAdress'] as String,
      favorites: json['favorites'] == null
          ? null
          : Favorite.fromJson(json['favorites'] as Map<String, dynamic>),
      person: json['person'] == null
          ? null
          : Person.fromJson(json['person'] as Map<String, dynamic>),
      ratingsBusDriver: (json['ratingsBusDriver'] as List)
          ?.map((e) => e == null
              ? null
              : RatingBusDriver.fromJson(e as Map<String, dynamic>))
          ?.toList(),
      ratingsCompanys: (json['ratingsCompanys'] as List)
          ?.map((e) => e == null
              ? null
              : RatingCompany.fromJson(e as Map<String, dynamic>))
          ?.toList());
}

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'surname': instance.surname,
      'email': instance.email,
      'password': instance.password,
      'birthDate': instance.birthDate,
      'gender': instance.gender,
      'job': instance.job,
      'credits': instance.credits,
      'isOnline': instance.isOnline,
      'deviceAdress': instance.deviceAdress,
      'favorites': instance.favorites?.toJson(),
      'person': instance.person?.toJson(),
      'ratingsBusDriver':
          instance.ratingsBusDriver?.map((e) => e?.toJson())?.toList(),
      'ratingsCompanys':
          instance.ratingsCompanys?.map((e) => e?.toJson())?.toList()
    };
