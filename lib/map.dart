import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:dart_geohash/dart_geohash.dart';
import 'coloredTile.dart';

class GeoMap {
  GeoMap(this._mapController);

  final MapController _mapController;

  final GeoHasher _geoHasher = GeoHasher();

  List<ColoredTile> _tiles = []; //Should be downloaded from database

  List<Polygon> _polygons = []; //Used to populate map

  List<Polyline> _gridX = [];
  List<Polyline> _gridY = [];

  //Half a square
  double _lngDiff = 0.00017185; //Might overlap, original was: 0.00017167
  double _latDiff = 0.00017185 / 2;

  void addTile(LatLng latlng, Colors color){
    //tiles.add(...)
  }

  LatLng getGeoCenter(LatLng latlng){
    String geohash = _geoHasher.encode(latlng.longitude, latlng.latitude, precision: 8);
    List<double> geohashLatlng = _geoHasher.decode(geohash);
    return LatLng(geohashLatlng[1], geohashLatlng[0]);
  }

  void addPolygon(LatLng latlng, Color color) {
    _polygons.add(createPolygon(ColoredTile(getGeoCenter(latlng), color)));
  }

  List<LatLng> createSquare(ColoredTile tile) {
    double lat = tile.position.latitude;
    double lng = tile.position.longitude;

    return [LatLng(lat + _latDiff, lng + _lngDiff),
      LatLng(lat + _latDiff, lng - _lngDiff),
      LatLng(lat - _latDiff, lng - _lngDiff),
      LatLng(lat - _latDiff, lng + _lngDiff),];
  }

  Polygon createPolygon(ColoredTile tile) {
    return Polygon(
      points: createSquare(tile),
      color: tile.color,
      isFilled: true,
      borderStrokeWidth: 0,
    );
  }

  void populateGrid() {
    if(_mapController.zoom >= 17){
      LatLngBounds border = _mapController.bounds ?? LatLngBounds(LatLng(0, 0), LatLng(0, 0));
      double left = border.west;
      double right  = border.east;

      double top = border.north;
      double bottom  = border.south;

      List<Polyline> newGridX = [];
      List<Polyline> newGridY = [];

      //Populate x
      for(double i = left; i <= right; i+=(_lngDiff*2)) {
        //get the center of the start and end point
        LatLng startLatLngCenter = getGeoCenter(LatLng(top, i));
        LatLng endLatLngCenter = getGeoCenter(LatLng(bottom, i));

        //Add half a square, so that the lines are not in the middle
        LatLng startLatLng = LatLng((startLatLngCenter.latitude + _latDiff), (startLatLngCenter.longitude + _lngDiff));
        LatLng endLatLng = LatLng((endLatLngCenter.latitude - _latDiff), (endLatLngCenter.longitude + _lngDiff));

        newGridX.add(Polyline(
          points: [startLatLng, endLatLng,],
          color: Colors.black45,
          strokeWidth: 1,
        ));
      }

      _gridX = newGridX;

      //Populate y
      for(double i = bottom; i <= top; i+=(_latDiff*2)) {
        //get the center of the start and end point
        LatLng startLatLngCenter = getGeoCenter(LatLng(i, left));
        LatLng endLatLngCenter = getGeoCenter(LatLng(i, right));

        //Add half a square, so that the lines are not in the middle
        LatLng startLatLng = LatLng((startLatLngCenter.latitude + _latDiff), (startLatLngCenter.longitude - _lngDiff));
        LatLng endLatLng = LatLng((endLatLngCenter.latitude + _latDiff), (endLatLngCenter.longitude + _lngDiff));

        newGridY.add(Polyline(
          points: [startLatLng, endLatLng,],
          color: Colors.black45,
          strokeWidth: 1,
        ));
      }

      _gridY = newGridY;
    } else {
      _gridX = [];
      _gridY = [];
    }
  }

  Widget showMap() {
    return FlutterMap(
      options: MapOptions(
        center: LatLng(57.70677670633015, 11.936813840131594),
        zoom: 18,
        maxZoom: 22,
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

        //Colored tiles
        PolygonLayer(
          polygonCulling: false,
          polygons: _polygons,
        ),

        //Grid
        PolylineLayer(
          polylineCulling: false,
          polylines: _gridX + _gridY,
        ),
      ],
    );

  }

}