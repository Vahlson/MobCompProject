import 'package:dart_geohash/dart_geohash.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class Model {
  //Tiles of the whole map (at least what is visible)
  List<ColoredTile> _tiles = [];
  Blueprint _activeBlueprint = Blueprint([]);

  void setTiles(List<ColoredTile> newTiles) {
    _tiles = newTiles;
  }

  void setActiveBlueprint(Blueprint newActiveBlueprint) {
    _activeBlueprint = newActiveBlueprint;
  }

//Returns a copy of the tiles list.
  List<ColoredTile> getTiles() {
    return _tiles.toList();
  }

//Returns a copy of the tiles list.
  Blueprint getActiveBlueprint() {
    return _activeBlueprint;
  }
}

class User {
  final String? _userID = null;
  //User(this._userID);

  String? getUserID() {
    return _userID;
  }
}

class ColoredTile {
  ColoredTile(this.position, this.color);

  late LatLng position;
  late Color color;

  ColoredTile.fromMap(String geohash, Map<String, dynamic> data) {
    color = Color.fromRGBO(data["r"], data["g"], data["b"], 1);
    //color = Color.fromRGBO(1, 1, 1, 1);
    //Decode geohash
    GeoHash g = GeoHash(geohash);
    position = LatLng(g.latitude(), g.longitude());
  }
}

class Blueprint {
  List<ColoredTile> _blueprintTiles = [];
  String groupID = "";

  Blueprint(this._blueprintTiles);

  Blueprint.fromMap(String geohash, Map<String, dynamic> data) {}
}
