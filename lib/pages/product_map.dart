import 'package:flutter/material.dart';
import 'package:flutter_app/shared/global_config.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';

class ProductMap extends StatefulWidget {
  final double lat;
  final double lng;
  ProductMap(this.lat, this.lng);

  @override
  State<StatefulWidget> createState() {
    return _ProductMapState();
  }
}

class _ProductMapState extends State<ProductMap> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Product Location'),
      ),
      body: FlutterMap(
          options:
              MapOptions(center: LatLng(widget.lat, widget.lng), minZoom: 14.0),
          layers: [
            new TileLayerOptions(
              urlTemplate: "https://api.tiles.mapbox.com/v4/"
                  "{id}/{z}/{x}/{y}@2x.png?access_token={accessToken}",
              additionalOptions: {
                'accessToken': apiKey,
                'id': 'mapbox.streets',
              },
            ),
            new MarkerLayerOptions(markers: [
              new Marker(
                width: 45.0,
                height: 45.0,
                point: new LatLng(widget.lat, widget.lng),
                builder: (context) => new Container(
                      child: Icon(
                        Icons.location_on,
                        color: Colors.blue,
                        size: 45.0,
                      ),
                    ),
              )
            ])
          ]),
    );
  }
}
