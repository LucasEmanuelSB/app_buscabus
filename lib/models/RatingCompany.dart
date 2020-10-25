import 'package:json_annotation/json_annotation.dart';

part 'RatingCompany.g.dart';

@JsonSerializable(explicitToJson: true)
class RatingCompany {
  int userId;
  int userCompany;
  double rate;

  RatingCompany({this.userId, this.userCompany, this.rate});

  factory RatingCompany.fromJson(Map<String, dynamic> data) =>
      _$RatingCompanyFromJson(data);

  Map<String, dynamic> toJson() => _$RatingCompanyToJson(this);
}
