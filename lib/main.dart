import 'package:app_buscabus/AddAdresses.dart';
import 'package:app_buscabus/Home.dart';
import 'package:flutter_statusbarcolor/flutter_statusbarcolor.dart';
import 'package:flutter/material.dart';
import 'Constants.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    FlutterStatusbarcolor.setStatusBarColor(Constants.accent_blue);
    FlutterStatusbarcolor.setNavigationBarWhiteForeground(true);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      //home: AddAdresses(),
      home: Home(),
      theme: ThemeData(
          textTheme: Theme.of(context).textTheme.apply(
              fontFamily: 'Abel',
              bodyColor: Constants.accent_grey,
              displayColor: Constants.accent_blue)),
    );
  }
}
