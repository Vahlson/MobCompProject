import 'package:dart_geohash/dart_geohash.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class Model {
  //Tiles of the whole map (at least what is visible)
  List<ColoredTile> _tiles = [];
  User? _user;

  bool _isBlueprintEditing = false;

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

  User? getCurrentUser() {
    return _user;
  }

  Blueprint? getActiveBlueprint() {
    return _user?.getActiveBlueprint();
  }

  bool getIsBluePrintEditing() {
    return _isBlueprintEditing;
  }

  void setUserBlueprints(List<Blueprint> newBlueprints) {
    _user?.setUserBlueprints(newBlueprints);
  }

  void setUserGroups(List<Group> newGroups) {
    _user?.setGroups(newGroups);
  }

  void setActiveBlueprint(String blueprintID) {
    _user?.setActiveBlueprint(blueprintID);
  }

  void setIsBluePrintEditing(bool value) {
    _isBlueprintEditing = value;
  }

}

class User {
  String? _activeBlueprintID;
  List<Blueprint> _availableBlueprints = [];
  List<Group> _groups = [];
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
    Blueprint? activeBlueprint = _availableBlueprints.firstWhere(
        (b) => b.getBlueprintID() == _activeBlueprintID, orElse: () {
      return Blueprint("", "");
    });

    if (activeBlueprint.getBlueprintID() == "") {
      return null;
    } else {
      return activeBlueprint;
    }
  }

  void setActiveBlueprint(String blueprintID) {
    Blueprint? newActiveBlueprint = getAvailableBlueprints().firstWhere(
        (blueprint) => blueprint.getBlueprintID() == blueprintID, orElse: () {
      print('No matching element. Keeping currently active bluprint active');
      return Blueprint("", "");
    });

    String? newActiveBlueprintID = newActiveBlueprint.getBlueprintID();
    if (newActiveBlueprintID != null && newActiveBlueprintID != "") {
      print("New active blueprint is: " + newActiveBlueprint._name);
      _activeBlueprintID = newActiveBlueprintID;
    }
  }

//Returns a copy of the blueprints list
  List<Blueprint> getAvailableBlueprints() {
    return List<Blueprint>.from(_availableBlueprints);
  }

  List<Group> getAvailableGroups() {
    return List<Group>.from(_groups);
  }

  void setUserBlueprints(List<Blueprint> newBlueprints) {
    _availableBlueprints = newBlueprints;
  }

  void setGroups(List<Group> newGroups) {
    _groups = newGroups;
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
  late String _blueprintID;
  String _name = "";

  List<ColoredTile> getTiles() {
    return _blueprintTiles.toList();
  }

  Blueprint(String id, String name,
      {List<ColoredTile> blueprintTiles = const []}) {
    _blueprintID = id;
    _name = name;
  }

  Blueprint.fromMap(String bluePrintID, Map<String, dynamic> data) {
    _blueprintID = bluePrintID;
    _name = data["blueprintName"];

    if (data["tiles"] != null && data["tiles"] != false) {
      Map<String, dynamic> tilesMap =
          Map<String, dynamic>.from(data["tiles"] as Map);

      List<ColoredTile> newTilesList = [];
      //Loop through each tile
      tilesMap.forEach((geohash, data) {
        if (geohash != null && data != null) {
          Map<String, dynamic> tile = Map<String, dynamic>.from(data);
          //The assumption here is that "value" is another map.
          newTilesList.add(ColoredTile.fromMap(geohash, tile));
        }
      });
      print("LOLOLOL ${newTilesList}");
      _blueprintTiles = newTilesList;
    }
  }

  String? getBlueprintID() {
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

  Group.fromMap(String iD, Map<String, dynamic> data) {
    id = iD;
    name = data["name"];
    memberCount = data["membercount"];
    description = data["description"];
  }
}
