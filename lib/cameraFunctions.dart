import 'dart:async';
import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';

LatLngBounds getBounds(List<double> lats, List<double> lngs) {
  double topMost = lngs.reduce(max);
  double leftMost = lats.reduce(min);
  double rightMost = lats.reduce(max);
  double bottomMost = lngs.reduce(min);

  LatLngBounds bounds = LatLngBounds(
    northeast: LatLng(rightMost, topMost),
    southwest: LatLng(leftMost, bottomMost),
  );

  return bounds;
}

moveCameraBetween(
    double latitudeOrigin,
    double latitudeDestiny,
    double longitudeOrigem,
    double longitudeDestino,
    Completer<GoogleMapController> controllerMap) {
  var nLat, nLon, sLat, sLon;

  double latitudeOrigin, latitudeDestiny, longitudeOrigem, longitudeDestino;

  if (latitudeOrigin <= latitudeDestiny) {
    sLat = latitudeOrigin;
    nLat = latitudeDestiny;
  } else {
    sLat = latitudeDestiny;
    nLat = latitudeOrigin;
  }

  if (longitudeOrigem <= longitudeDestino) {
    sLon = longitudeOrigem;
    nLon = longitudeDestino;
  } else {
    sLon = longitudeDestino;
    nLon = longitudeOrigem;
  }

  moveCameraBounds(
      LatLngBounds(
          northeast: LatLng(nLat, nLon), //nordeste
          southwest: LatLng(sLat, sLon) //sudoeste
          ),
      controllerMap);
}

moveCameraBounds(LatLngBounds latLngBounds,
    Completer<GoogleMapController> controllerMap) async {
  GoogleMapController googleMapController = await controllerMap.future;
  googleMapController
      .animateCamera(CameraUpdate.newLatLngBounds(latLngBounds, 100));
}

moveCamera(CameraPosition cameraPosition,
    Completer<GoogleMapController> controllerMap) async {
  GoogleMapController googleMapController = await controllerMap.future;
  googleMapController
      .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
}
