import 'package:app_buscabus/models/Adress.dart';
import 'package:flutter/material.dart';
import 'package:geocoder/geocoder.dart';
import 'package:app_buscabus/Constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class AddAdresses extends StatefulWidget {
  @override
  _AddAdressesState createState() => _AddAdressesState();
}

class _AddAdressesState extends State<AddAdresses> {
  TextEditingController _latitudeTextField = TextEditingController();
  TextEditingController _longitudeTextField = TextEditingController();

  @override
  void initState() {
    _latitudeTextField.addListener(() {});
    _longitudeTextField.addListener(() {});
    super.initState();
  }

  Future<Adress> _getAdressFromLatLng(double latitude, double longitude) async {
    final coordinates = Coordinates(latitude, longitude);
    var addresses =
        await Geocoder.local.findAddressesFromCoordinates(coordinates);

    if (addresses != null && addresses.length > 0) {
      var first = addresses.first;

      Adress location = new Adress();
      location.country = first.countryName == null ? "" : first.countryName;
      location.uf = first.adminArea == null ? "" : first.adminArea;
      location.city = first.locality == null ? "" : first.locality;
      location.cep = first.postalCode == null ? "" : first.postalCode;
      location.neighborhood =
          first.subLocality == null ? "" : first.subLocality;
      location.street = first.thoroughfare == null ? "" : first.thoroughfare;
      location.number =
          first.subThoroughfare == null ? "" : first.subThoroughfare;
      return location;
    } else
      return null;
  }

  _sendAdress() async {
    double latitude = double.parse(_latitudeTextField.text);
    double longitude = double.parse(_longitudeTextField.text);
    Adress newAdress = await _getAdressFromLatLng(latitude, longitude);

    Map<String, String> headers = {
      'Content-type': 'application/json',
      'Accept': 'application/json',
    };
    //print(response.id);
    String bodyAdress = jsonEncode(newAdress.toJson());
    try {
      //print(responseGlobalPosition.body);
      http.Response responseAdress = await http.post(Constants.url_adresses,
          headers: headers, body: bodyAdress);
      print(responseAdress.statusCode.toString() + " \n " + bodyAdress + "\n");
    } catch (error) {
      print(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Adicione um endereço")),
      body: Center(
        child: Column(
          children: [
            TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(hintText: " Latitude"),
              autocorrect: false,
              controller: _latitudeTextField,
            ),
            TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(hintText: " Longitude"),
              autocorrect: false,
              controller: _longitudeTextField,
            ),
            RaisedButton(
              child: Text("Enviar endereço"),
              onPressed: () async {
                await _sendAdress();
              },
            )
          ],
        ),
      ),
    );
  }
}
