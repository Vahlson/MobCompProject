import 'package:dart_geohash/dart_geohash.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class Model {
  //Tiles of the whole map (at least what is visible)
  List<ColoredTile> _tiles = [];
  User _user = User("");

  void setTiles(List<ColoredTile> newTiles) {
    _tiles = newTiles;
  }

//Returns a copy of the tiles list.
  List<ColoredTile> getTiles() {
    return _tiles.toList();
  }

  void setCurrentUser(User user) {
    _user = user;
  }

  User getCurrentUser() {
    return _user;
  }

  Blueprint? getActiveBlueprint() {
    return _user.getActiveBlueprint();
  }

  void addBlueprintToUser(Blueprint newBlueprint) {
    _user.addBlueprint(newBlueprint);
  }

  void setActiveBlueprint(Blueprint newBlueprint) {
    _user.setActiveBlueprint(newBlueprint);
  }
}

class User {
  Blueprint? _activeBlueprint;
  List<Blueprint> _availableBlueprints = [];
  String? _userID;
  //User(this._userID);

  User(this._userID);

  User.fromMap(
    String key,
    Map<String, dynamic> data,
  ) {
    _availableBlueprints = data["Groups"];
    _userID = data[key];
  }

  String? getUserID() {
    return _userID;
  }

  //Returns a copy of the active blueprint.
  Blueprint? getActiveBlueprint() {
    return _activeBlueprint;
  }

  void setActiveBlueprint(Blueprint newActiveBlueprint) {
    _activeBlueprint = newActiveBlueprint;
  }

//Returns a copy of the blueprints list
  List<Blueprint> getAvailableBlueprints() {
    return _availableBlueprints.toList();
  }

  void addBlueprint(Blueprint newBlueprint) {
    return _availableBlueprints.add(newBlueprint);
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
  String _name = "";

  List<ColoredTile> getTiles() {
    return _blueprintTiles.toList();
  }

  Blueprint(String id, String name,
      {List<ColoredTile> blueprintTiles = const []}) {
    _blueprintID = id;
    _name = name;
  }

  Blueprint.fromMap(String id, Map<String, dynamic> data) {}

  String getBlueprintID() {
    return _blueprintID;
  }

  String getName() {
    return _name;
  }

  void setTiles(List<ColoredTile> newTiles) {
    _blueprintTiles = newTiles;
  }
}

class Group {
  var id = "";
  var name = "";
  var memberCount = 0;
  var description = "";

  Group(this.id, this.name, {this.description = ""});
}
