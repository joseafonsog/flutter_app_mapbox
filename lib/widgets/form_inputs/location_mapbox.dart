import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_app/models/location_data.dart';
import 'package:flutter_app/models/product.dart';
import 'package:flutter_app/shared/global_config.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart' as geoloc;

class LocationMapboxInput extends StatefulWidget {
  final Function setLocation;
  final Product product;

  LocationMapboxInput(this.setLocation, this.product);

  @override
  State<StatefulWidget> createState() {
    return _LocationMapboxInputState();
  }
}

class _LocationMapboxInputState extends State<LocationMapboxInput> {
  final FocusNode _addressInputFocusNode = FocusNode();
  final TextEditingController _addressInputController = TextEditingController();
  Uri _staticMapUri;
  LocationData _locationData;

  @override
  void initState() {
    _addressInputFocusNode.addListener(_updateLocation);
    if (widget.product != null) {
      _getStaticMap(widget.product.location.address, geocode: false);
    }
    super.initState();
  }

  @override
  void dispose() {
    _addressInputFocusNode.removeListener(_updateLocation);
    super.dispose();
  }

  void _getStaticMap(String address,
      {bool geocode = true, double lat, double lng}) async {
    if (address.isEmpty) {
      setState(() {
        _staticMapUri = null;
      });
      widget.setLocation(null);
      return;
    }
    if (geocode) {
      final String encodedAddress = Uri.encodeComponent(address);
      final Uri uri = Uri.https(
        'api.mapbox.com',
        '/geocoding/v5/mapbox.places/$encodedAddress.json',
        {'access_token': apiKey},
      );
      final http.Response response = await http.get(uri);
      final Map<String, dynamic> decodedResponse = json.decode(response.body);
      final String formattedAddress =
          decodedResponse['features'][0]['place_name'];
      final List<dynamic> coords =
          decodedResponse['features'][0]['geometry']['coordinates'];
      _locationData = LocationData(
          address: formattedAddress, latitude: coords[1], longitude: coords[0]);
    } else if (lat == null && lng == null) {
      _locationData = widget.product.location;
    } else {
      _locationData =
          LocationData(address: address, latitude: lat, longitude: lng);
    }

    if (mounted) {
      final Uri staticMapUri = Uri.https(
        'api.mapbox.com',
        '/v4/mapbox.emerald/pin-s-bicycle+285A98(${_locationData.longitude},${_locationData.latitude})/${_locationData.longitude},${_locationData.latitude},14/500x300@2x.png',
        {'access_token': apiKey},
      );
      widget.setLocation(_locationData);

      setState(() {
        _addressInputController.text = _locationData.address;
        _staticMapUri = staticMapUri;
      });
    }
  }

  Future<String> _getAddress(double lat, double lng) async {
    final Uri uri = Uri.https(
      'api.mapbox.com',
      '/geocoding/v5/mapbox.places/$lng,$lat.json',
      {'access_token': apiKey},
    );

    http.Response response = await http.get(uri);
    final Map<String, dynamic> decodedResponse = json.decode(response.body);
    final String formattedAddress =
        decodedResponse['features'][0]['place_name'];

    return formattedAddress;
  }

  void _getUserLocation() async {
    final geoloc.Location location = geoloc.Location();
    try {
      final geoloc.LocationData currentLocation = await location.getLocation();
      String address = await _getAddress(
          currentLocation.latitude, currentLocation.longitude);
      _getStaticMap(address,
          geocode: false,
          lat: currentLocation.latitude,
          lng: currentLocation.longitude);
    } catch (error) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Could not fetch location'),
              content: Text('Please add address manually!'),
              actions: <Widget>[
                FlatButton(
                  child: Text('Okay'),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                )
              ],
            );
          });
    }
  }

  void _updateLocation() {
    if (!_addressInputFocusNode.hasFocus) {
      _getStaticMap(_addressInputController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        TextFormField(
          focusNode: _addressInputFocusNode,
          controller: _addressInputController,
          validator: (String value) {
            if (_locationData == null || value.isEmpty) {
              return 'no valid location found.';
            }
          },
          decoration: InputDecoration(labelText: 'Address'),
        ),
        SizedBox(height: 10.0),
        FlatButton(
          child: Text('Locate user'),
          onPressed: _getUserLocation,
        ),
        SizedBox(height: 10.0),
        _locationData == null
            ? Container()
            : Image.network(_staticMapUri.toString())
      ],
    );
  }
}
