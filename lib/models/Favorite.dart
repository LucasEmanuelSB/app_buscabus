import 'package:json_annotation/json_annotation.dart';

part 'Favorite.g.dart';

@JsonSerializable(explicitToJson: true)
class Favorite {
  List<int> busId;
  List<int> busStopId;
  List<int> itineraryId;

  Favorite({this.busId, this.busStopId, this.itineraryId});

  factory Favorite.fromJson(Map<String, dynamic> data) =>
      _$FavoriteFromJson(data);

  Map<String, dynamic> toJson() => _$FavoriteToJson(this);
}
