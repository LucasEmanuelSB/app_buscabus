// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Calendar.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Calendar _$CalendarFromJson(Map<String, dynamic> json) {

  return Calendar(
      id: json['id'] as int,
      weeks:
          (json['weeks'] as List)?.map((e) => e as String)?.toList(),
      weekendsHolidays: (json['weekendsHolidays'] as List)
          ?.map((e) => e as String)
          ?.toList());
}

Map<String, dynamic> _$CalendarToJson(Calendar instance) => <String, dynamic>{
      'weeks': instance.weeks,
      'weekendsHolidays': instance.weekendsHolidays
    };
