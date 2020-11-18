import 'package:app_buscabus/models/Bus.dart';
import 'package:app_buscabus/models/BusStop.dart';
import 'package:app_buscabus/models/Routes.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rxdart/rxdart.dart';

enum Navigation { BUS, MAP, MURAL }
List<bool> filterchips = [false, false, false, false];

class NavigationBloc {
  //BehaviorSubject is from rxdart package
  final BehaviorSubject<Navigation> _controller =
      BehaviorSubject.seeded(Navigation.MAP);
  // seeded with inital page value. I'am assuming PAGE_ONE value as initial page.

  //exposing stream that notify us when navigation index has changed
  Stream<Navigation> get currentNavigationIndex => _controller.stream;

  // method to change your navigation index
  // when we call this method it sends data to stream and his listener
  // will be notified about it.
  void changeNavigationIndex(final Navigation option) =>
      _controller.sink.add(option);

  void dispose() => _controller?.close();
}

class CameraPositionBloc {
  final BehaviorSubject<CameraPosition> _controller =
      BehaviorSubject<CameraPosition>();
  Sink<CameraPosition> get input => _controller.sink;
  Stream<CameraPosition> get output => _controller.stream;

  void sendCameraPosition(CameraPosition cameraPosition) async {
    input.add(cameraPosition);
  }

  void dispose() => _controller?.close();
}

class PositionBloc {
  final BehaviorSubject<Position> _controller = BehaviorSubject<Position>();
  Sink<Position> get input => _controller.sink;
  Stream<Position> get output => _controller.stream;

  Position get currentPosition => _controller.value;
  void newPosition(Position position) {
    input.add(position);
  }

  void dispose() => _controller?.close();
}

class FilterBloc {
  final BehaviorSubject<List<bool>> _controller = BehaviorSubject<List<bool>>();
  Sink<List<bool>> get input => _controller.sink;
  Stream<List<bool>> get output => _controller.stream;

  void changeChips(int index, bool value) {
    filterchips[index] = value;
    input.add(filterchips);
  }

  void dispose() => _controller?.close();
}

class BusBloc {
  final BehaviorSubject<Bus> _controller = BehaviorSubject<Bus>();
  Sink<Bus> get input => _controller.sink;
  Stream<Bus> get output => _controller.stream;

  void sendBus(Bus bus) async {
    input.add(bus);
  }

  void dispose() => _controller?.close();
}

class RouteBloc {
  final BehaviorSubject<Routes> _controller = BehaviorSubject<Routes>();
  Sink<Routes> get input => _controller.sink;
  Stream<Routes> get output => _controller.stream;

  void sendBus(Routes route) async {
    input.add(route);
  }

  void dispose() => _controller?.close();
}

class CoordinatesBloc {
  final BehaviorSubject<Map<int,List<LatLng>>> _controller =
      BehaviorSubject<Map<int,List<LatLng>>>();
  Sink<Map<int,List<LatLng>>> get input => _controller.sink;
  Stream<Map<int,List<LatLng>>> get output => _controller.stream;
  Map<int,List<LatLng>> get currentDate => _controller.value;
  void sendCoordinates(Map<int,List<LatLng>> coordinates) async {
    input.add(coordinates);
  }

  
  void dispose() => _controller?.close();
}

class BusStopBloc {
  final BehaviorSubject<BusStop> _controller = BehaviorSubject<BusStop>();
  Sink<BusStop> get input => _controller.sink;
  Stream<BusStop> get output => _controller.stream;

  void sendBus(BusStop busStop) async {
    input.add(busStop);
  }

  void dispose() => _controller?.close();
}
