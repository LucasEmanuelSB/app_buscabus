import 'package:app_buscabus/models/RatingCompany.dart';
import 'package:json_annotation/json_annotation.dart';

part 'Company.g.dart';

@JsonSerializable(explicitToJson: true)
class Company {
  int id;
  String name;
  double averageRate;
  List<RatingCompany> usersRatings;

  Company({this.id, this.name, this.averageRate, this.usersRatings});

  factory Company.fromJson(Map<String, dynamic> data) =>
      _$CompanyFromJson(data);

  Map<String, dynamic> toJson() => _$CompanyToJson(this);
}
