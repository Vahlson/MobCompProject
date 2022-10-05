import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:dart_geohash/dart_geohash.dart';
import 'coloredTile.dart';

class GeoMap {
  GeoMap(this._mapController);

  final MapController _mapController;

  GeoHasher geoHasher = GeoHasher();

  List<ColoredTile> tiles = []; //Should be downloaded from database

  List<Polygon> polygons = []; //Used to populate map

  void addTile(LatLng latlng, Colors color){
    //tiles.add(...)
  }

  void addPolygon(LatLng latlng, Color color) {
    String geohash = geoHasher.encode(latlng.longitude, latlng.latitude, precision: 8);
    List<double> geohashLatlng = geoHasher.decode(geohash);
    polygons.add(createPolygon(ColoredTile(LatLng(geohashLatlng[1], geohashLatlng[0]), color)));
  }

  List<LatLng> createSquare(ColoredTile tile) {
    double lat = tile.position.latitude;
    double lng = tile.position.longitude;

    double lngDiff = 0.00017185; //Might overlap, original was: 0.00017167
    double latDiff = lngDiff / 2;

    return [LatLng(lat + latDiff, lng + lngDiff),
      LatLng(lat + latDiff, lng - lngDiff),
      LatLng(lat - latDiff, lng - lngDiff),
      LatLng(lat - latDiff, lng + lngDiff),];
  }

  Polygon createPolygon(ColoredTile tile) {
    return Polygon(
      points: createSquare(tile),
      color: tile.color,
      isFilled: true,
      borderStrokeWidth: 0,
    );
  }

  Widget showMap() {
    return FlutterMap(
      options: MapOptions(
        center: LatLng(57.70677670633015, 11.936813840131594),
        zoom: 18,
      ),
      mapController: _mapController,
      /*nonRotatedChildren: [
        AttributionWidget.defaultWidget(
          source: 'OpenStreetMap contributors',
          onSourceTapped: null,
        ),
      ],*/
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.app',
        ),
        PolygonLayer(
          polygonCulling: false,
          polygons: polygons,
        ),

      ],
    );

  }

}