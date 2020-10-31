// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Adress.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Adress _$AdressFromJson(Map<String, dynamic> json) {
  return Adress(
    id: json['id'] as int,
    country: json['country'] == null ? 'x': json['country'] as String,
    uf: json['uf'] == null ? 'x': json['uf'] as String,
    city: json['city'] == null ? 'x': json['city'] as String,
    neighborhood: json['neighborhood'] == null ? 'x': json['neighborhood'] as String,
    street: json['street'] == null ? 'x': json['street'] as String,
    cep: json['cep'] == null ? 'x': json['cep'] as String,
    number: json['number'] == null ? 'x': json['number'] as String
  );
}

Map<String, dynamic> _$AdressToJson(Adress instance) => <String, dynamic>{
      'country': instance.country,
      'uf': instance.uf,
      'city': instance.city,
      'neighborhood': instance.neighborhood,
      'street': instance.street,
      'cep': instance.cep,
      'number': instance.number,
    };
