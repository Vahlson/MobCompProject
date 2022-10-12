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

  void setUserBlueprints(List<Blueprint> newBlueprints) {
    _user.setBlueprints(newBlueprints);
  }

  void setUserGroups(List<Group> newGroups) {
    _user.setGroups(newGroups);
  }

  void setActiveBlueprint(String blueprintID) {
    _user.setActiveBlueprint(blueprintID);
  }
}

class User {
  Blueprint? _activeBlueprint;
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
    return _activeBlueprint;
  }

  void setActiveBlueprint(String blueprintID) {
    Blueprint? newActiveBlueprint = getAvailableBlueprints().firstWhere(
        (blueprint) => blueprint.getBlueprintID() == blueprintID, orElse: () {
      if (_activeBlueprint != null) {
        print('No matching element. Keeping currently active bluprint active');
        return _activeBlueprint!;
      } else {
        print('No matching element called $blueprintID. Doing nothing');
        return Blueprint("", "");
      }
    });
    if (newActiveBlueprint != null && newActiveBlueprint._blueprintID != "") {
      print("New active blueprint is: " + newActiveBlueprint._name);
      _activeBlueprint = newActiveBlueprint;
    }
  }

//Returns a copy of the blueprints list
  List<Blueprint> getAvailableBlueprints() {
    return _availableBlueprints.toList();
  }

  void setBlueprints(List<Blueprint> newBlueprints) {
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

  Blueprint.fromMap(String bluePrintID, Map<String, dynamic> data) {
    _blueprintID = bluePrintID;
    //_name = data["name"];

    List<ColoredTile> newTilesList = [];
    //Loop through each tile
    data.forEach((geohash, colorMap) {
      newTilesList.add(ColoredTile.fromMap(geohash, colorMap));
    });
    _blueprintTiles = newTilesList;
  }

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

  Group.fromMap(String iD, Map<String, dynamic> data) {
    id = iD;
    name = data["name"];
    memberCount = data["membercount"];
    description = data["description"];
  }
}
