import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:dart_geohash/dart_geohash.dart';
import 'package:location/location.dart';
import 'coloredTile.dart';
import 'main.dart';
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

  LatLng _userPosition = LatLng(0, 0);

  double _zoom = 0;

  List<Polygon> _drawableArea = [];
  late LatLngBounds _drawableBounds;

  double selectedOpacity = 1;

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
      _userPosition =
          LatLng(userLocation.latitude ?? 0, userLocation.longitude ?? 0);

      _showDrawableArea();
    });

    LocationData userLocation = await location.getLocation();
    _userPosition =
        LatLng(userLocation.latitude ?? 0, userLocation.longitude ?? 0);

    //Map
    onMapMove();
  }

  void centerMapOnUser() async {
    /* Location location = Location();
    LocationData userLocation = await location.getLocation();
    userPosition =
        LatLng(userLocation.latitude ?? 0, userLocation.longitude ?? 0); */
    _mapController.move(_userPosition, _mapController.zoom);
  }

  LatLng _getGeoCenter(LatLng latlng) {
    String geohash =
        _geoHasher.encode(latlng.longitude, latlng.latitude, precision: 8);
    List<double> geohashLatlng = _geoHasher.decode(geohash);
    return LatLng(geohashLatlng[1], geohashLatlng[0]);
  }

  List<LatLng> _createSquare(ColoredTile tile, scale) {
    double lat = tile.position.latitude;
    double lng = tile.position.longitude;

    return [
      LatLng(lat + _latDiff * scale, lng + _lngDiff * scale),
      LatLng(lat + _latDiff * scale, lng - _lngDiff * scale),
      LatLng(lat - _latDiff * scale, lng - _lngDiff * scale),
      LatLng(lat - _latDiff * scale, lng + _lngDiff * scale),
    ];
  }

  Polygon _createPolygon(ColoredTile tile, double scale) {
    return Polygon(
      points: _createSquare(tile, scale),
      color: tile.color,
      isFilled: true,
      borderStrokeWidth: 0,
    );
  }

  void onMapMove() {
    _zoom = _mapController.zoom;

    _populateGrid();
  }

  void _populateGrid() {
    if (_zoom >= 17) {
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
        LatLng startLatLngCenter = _getGeoCenter(LatLng(top, i));
        LatLng endLatLngCenter = _getGeoCenter(LatLng(bottom, i));

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
        LatLng startLatLngCenter = _getGeoCenter(LatLng(i, left));
        LatLng endLatLngCenter = _getGeoCenter(LatLng(i, right));

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
      _drawableArea = [];
    }
  }

  List<Marker> _userMarker() {
    double outer = (_zoom >= 17) ? 5 : 2;
    double inner = (_zoom >= 17) ? 20 : 7;
    double size = outer + inner;

    return [
      Marker(
          point: _userPosition,
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

  void _showDrawableArea() {
    LatLng topLeftCenter = _getGeoCenter(LatLng(
        _userPosition.latitude + (_latDiff * 4),
        _userPosition.longitude + (_lngDiff * 4)));
    LatLng bottomRightCenter = _getGeoCenter(LatLng(
        _userPosition.latitude - (_latDiff * 4),
        _userPosition.longitude - (_lngDiff * 4)));

    LatLng topLeft = LatLng(
        topLeftCenter.latitude + _latDiff, topLeftCenter.longitude + _lngDiff);
    LatLng bottomRight = LatLng(bottomRightCenter.latitude - _latDiff,
        bottomRightCenter.longitude - _lngDiff);

    _drawableBounds = LatLngBounds(topLeft, bottomRight);

    _drawableArea = [
      Polygon(
        points: [
          _drawableBounds.northWest,
          _drawableBounds.northEast ?? LatLng(0, 0),
          _drawableBounds.southEast,
          _drawableBounds.southWest ?? LatLng(0, 0)
        ],
        borderColor: Colors.amber,
        borderStrokeWidth: 2,
      )
    ];
  }

  bool isValidTilePosition(double lat, double lng) {
    LatLng latLng = LatLng(lat, lng);
    return _drawableBounds.contains(latLng);
  }

  Widget showMap(Model model) {
    List<Polygon> _polygons = model
        .getTiles()
        .map((tile) => _createPolygon(
            ColoredTile(_getGeoCenter(tile.position),
                tile.color.withOpacity(selectedOpacity)),
            1))
        .toList();

    //TODO change _createPolygon to something else
    List<Polygon> _blueprintPolygons = [];
    if (model.getIsBluePrintEditing() || model.shouldShowBlueprint()) {
      List<ColoredTile>? tempBlueprintTiles =
          model.getActiveBlueprint()?.getTiles();

      //print("The gathered blueprint tiles ${tempBlueprintTiles.toString()} for blueprint ${model.getActiveBlueprint()?.getName()}");
      if (tempBlueprintTiles != null) {
        _blueprintPolygons = tempBlueprintTiles
            .map((tile) => _createPolygon(
                ColoredTile(_getGeoCenter(tile.position), tile.color),
                model.shouldShowBlueprint() ? 0.5 : 1))
            .toList();
      }
    }

    return FlutterMap(
      options: MapOptions(
        center: _userPosition,
        zoom: 18,
        maxZoom: 22,
        interactiveFlags: InteractiveFlag.all & ~InteractiveFlag.doubleTapZoom,
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
          polygons: _polygons + _blueprintPolygons + _drawableArea,
        ),

        //Grid
        PolylineLayer(
          polylineCulling: false,
          polylines: _gridX + _gridY,
        ),

        //Mark user position
        MarkerLayer(
          markers: _userMarker(),
        ),
      ],
    );
  }
}
