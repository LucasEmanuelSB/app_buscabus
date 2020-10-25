import 'package:app_buscabus/models/Favorite.dart';
import 'package:app_buscabus/models/Person.dart';
import 'package:app_buscabus/models/RatingBusDriver.dart';
import 'package:app_buscabus/models/RatingCompany.dart';
import 'package:json_annotation/json_annotation.dart';

part 'User.g.dart';

@JsonSerializable(explicitToJson: true)
class User {
  int id;
  String name;
  String surname;
  String email;
  String password;
  String birthDate;
  String gender;
  String job;
  double credits;
  bool isOnline;
  String deviceAdress;
  Favorite favorites;
  Person person;
  List<RatingBusDriver> ratingsBusDriver;
  List<RatingCompany> ratingsCompanys;

  User(
      {this.id,
      this.name,
      this.surname,
      this.email,
      this.password,
      this.birthDate,
      this.gender,
      this.job,
      this.credits,
      this.isOnline,
      this.deviceAdress,
      this.favorites,
      this.person,
      this.ratingsBusDriver,
      this.ratingsCompanys,
});

  factory User.fromJson(Map<String, dynamic> data) => _$UserFromJson(data);

  Map<String, dynamic> toJson() => _$UserToJson(this);
}
