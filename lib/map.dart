import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:dart_geohash/dart_geohash.dart';
import 'package:location/location.dart';
import 'coloredTile.dart';
import 'model/Model.dart';

class GeoMap {
  GeoMap(this._mapController);

  final MapController _mapController;

  final GeoHasher _geoHasher = GeoHasher();

  //Should be downloaded from database

  List<Polyline> _gridX = [];
  List<Polyline> _gridY = [];

  //Half a square
  final double _lngDiff = 0.00017185; //Might overlap, original was: 0.00017167
  final double _latDiff = 0.00017185 / 2;

  LatLng userPosition = LatLng(0, 0);

  double zoom = 0;

  Future<void> initGeoMap() async {
    //Location
    Location location = Location();

    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    location.onLocationChanged.listen((LocationData userLocation) {
      userPosition =
          LatLng(userLocation.latitude ?? 0, userLocation.longitude ?? 0);
      _mapController.move(
          userPosition,
          _mapController
              .zoom); //We don't want this. Should only center when we start the application
    });

    //Map
    onMapMove();
  }

  LatLng getGeoCenter(LatLng latlng) {
    String geohash =
        _geoHasher.encode(latlng.longitude, latlng.latitude, precision: 8);
    List<double> geohashLatlng = _geoHasher.decode(geohash);
    return LatLng(geohashLatlng[1], geohashLatlng[0]);
  }

  void addTile(LatLng latlng, Colors color) {
    //tiles.add(...)
  }

  void addPolygon(LatLng latlng, Color color) {
    //_polygons.add(createPolygon(ColoredTile(getGeoCenter(latlng), color)));
  }

  List<LatLng> createSquare(ColoredTile tile) {
    double lat = tile.position.latitude;
    double lng = tile.position.longitude;

    return [
      LatLng(lat + _latDiff, lng + _lngDiff),
      LatLng(lat + _latDiff, lng - _lngDiff),
      LatLng(lat - _latDiff, lng - _lngDiff),
      LatLng(lat - _latDiff, lng + _lngDiff),
    ];
  }

  Polygon createPolygon(ColoredTile tile) {
    return Polygon(
      points: createSquare(tile),
      color: tile.color,
      isFilled: true,
      borderStrokeWidth: 0,
    );
  }

  void onMapMove() {
    zoom = _mapController.zoom;

    populateGrid();
  }

  void populateGrid() {
    if (zoom >= 17) {
      LatLngBounds border =
          _mapController.bounds ?? LatLngBounds(LatLng(0, 0), LatLng(0, 0));
      double left = border.west;
      double right = border.east;

      double top = border.north;
      double bottom = border.south;

      List<Polyline> newGridX = [];
      List<Polyline> newGridY = [];

      //Populate x
      for (double i = left; i <= right; i += (_lngDiff * 2)) {
        //get the center of the start and end point
        LatLng startLatLngCenter = getGeoCenter(LatLng(top, i));
        LatLng endLatLngCenter = getGeoCenter(LatLng(bottom, i));

        //Add half a square, so that the lines are not in the middle
        LatLng startLatLng = LatLng((startLatLngCenter.latitude + _latDiff),
            (startLatLngCenter.longitude + _lngDiff));
        LatLng endLatLng = LatLng((endLatLngCenter.latitude - _latDiff),
            (endLatLngCenter.longitude + _lngDiff));

        newGridX.add(Polyline(
          points: [
            startLatLng,
            endLatLng,
          ],
          color: Colors.black45,
          strokeWidth: 1,
        ));
      }

      _gridX = newGridX;

      //Populate y
      for (double i = bottom; i <= top; i += (_latDiff * 2)) {
        //get the center of the start and end point
        LatLng startLatLngCenter = getGeoCenter(LatLng(i, left));
        LatLng endLatLngCenter = getGeoCenter(LatLng(i, right));

        //Add half a square, so that the lines are not in the middle
        LatLng startLatLng = LatLng((startLatLngCenter.latitude + _latDiff),
            (startLatLngCenter.longitude - _lngDiff));
        LatLng endLatLng = LatLng((endLatLngCenter.latitude + _latDiff),
            (endLatLngCenter.longitude + _lngDiff));

        newGridY.add(Polyline(
          points: [
            startLatLng,
            endLatLng,
          ],
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

  List<Marker> userMarker() {
    double outer = (zoom >= 16) ? 5 : 2;
    double inner = (zoom >= 16) ? 20 : 7;
    double size = outer + inner;
    return [
      Marker(
          point: userPosition,
          width: size,
          height: size,
          builder: (context) => AnimatedContainer(
                width: inner,
                height: inner,
                decoration: BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: outer,
                      strokeAlign: StrokeAlign.outside,
                    )),
                duration: const Duration(milliseconds: 500),
              ))
    ];
  }

//TODO change how the map gets the model ? MODEL should live in main or something. maybe make one controller class which creates both map and dbcomm and model.
  Widget showMap(Model model) {
    print("Found tiles: " + model.getTiles().toString());
    //List<Polygon> _polygons = [];
    List<Polygon> _polygons = model
        .getTiles()
        .map((tile) =>
            createPolygon(ColoredTile(getGeoCenter(tile.position), tile.color)))
        .toList();

    return FlutterMap(
      options: MapOptions(
        center: userPosition,
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

        //Mark user position
        MarkerLayer(
          markers: userMarker(),
        ),
      ],
    );
  }
}
