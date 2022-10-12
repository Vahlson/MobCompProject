import 'package:dart_geohash/dart_geohash.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class Model {
  //Tiles of the whole map (at least what is visible)
  List<ColoredTile> _tiles = [];
  Blueprint? _activeBlueprint;
  List<Blueprint> _availableBlueprints = [];

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

//Returns a copy of the active blueprint.
  Blueprint? getActiveBlueprint() {
    return _activeBlueprint;
  }

//Returns a copy of the blueprints list
  List<Blueprint> getAvailableBlueprints() {
    return _availableBlueprints.toList();
  }

  void addBlueprint(Blueprint newBlueprint) {
    return _availableBlueprints.add(newBlueprint);
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
  String _blueprintID = "";

  List<ColoredTile> getTiles() {
    return _blueprintTiles.toList();
  }

  Blueprint(String id, {List<ColoredTile> blueprintTiles = const []}) {
    _blueprintID = id;
  }

  Blueprint.fromMap(String id, Map<String, dynamic> data) {}

  String getBlueprintID() {
    return _blueprintID;
  }

  void setTiles(List<ColoredTile> newTiles) {
    _blueprintTiles = newTiles;
  }
}
