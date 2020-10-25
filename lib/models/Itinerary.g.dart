// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Itinerary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Itinerary _$ItineraryFromJson(Map<String, dynamic> json) {
  return Itinerary(
      id: json['id'] as int,
      bus: json['bus'] == null
          ? null
          : Bus.fromJson(json['bus'] as Map<String, dynamic>),
      route: json['route'] == null
          ? null
          : Route.fromJson(json['route'] as Map<String, dynamic>),
      calendar: json['calendar'] == null
          ? null
          : Calendar.fromJson(json['calendar'] as Map<String, dynamic>));
}

Map<String, dynamic> _$ItineraryToJson(Itinerary instance) => <String, dynamic>{

      'bus': instance.bus?.toJson(),
      'route': instance.route?.toJson(),
      'calendar': instance.calendar?.toJson(),
    };
