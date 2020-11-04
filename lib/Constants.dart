import 'package:flutter/material.dart';

class Constants {
  static const String googleAPIKey = "AIzaSyDVGS1rOl8vHtPqoUruCd7NGpSWumGlVIw";
  static const int num_icons = 30;
  static const Color green = Color(0xff1B9227);
  static const Color accent_scarlat = Color(0xffD90429);
  static const Color scarlat = Color(0xffEF233C);
  static const Color accent_blue = Color(0xff131D49);
  static const Color brightness_blue = Color(0xff009DE0);
  static const Color grey_blue = Color(0xff8D99AE);
  static const Color accent_grey = Color(0xff707070);
  static const Color white_grey = Color(0xffEDF2F4);

  static const String url = "http://35.199.104.230/api/";
  static const String url_buses = url + "buses";
  static const String url_busDrivers = url + "busDrivers";
  static const String url_busStops = url + "busStops";
  static const String url_itinerarys = url + "itinerarys";
  static const String url_calendars = url + "calendars";
  static const String url_routes = url + "routes";
  static const String url_adresses = url + "adresses";
  static const String url_points = url + "points";
  static const String url_globalPosition = url + "globalPositions";

  static const String SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  static const String CHARACTERISTIC_UUID_TX =
      "beb5483e-36e1-4688-b7f5-ea07361b26a1";
  static const String CHARACTERISTIC_UUID_RX_LAT =
      "68dadf0a-1323-11eb-adc1-0242ac120002";
  static const String CHARACTERISTIC_UUID_RX_LONG =
      "7ac3dc76-1323-11eb-adc1-0242ac120002";
  static const String BEACON_UUID = "3349AD51-5D51-C5A3-F348-B76D576993CE";
  static const int busWithGpsId = 1;
}
