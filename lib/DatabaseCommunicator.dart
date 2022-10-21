import 'dart:async';

import 'package:artmap/groups.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';

import 'model/Model.dart';

class ActiveBlueprintChangeNotifier extends ChangeNotifier {
  DatabaseCommunicator dbCom;
  ActiveBlueprintChangeNotifier(this.dbCom);
  StreamSubscription<DatabaseEvent>? databaseSubscription;

  void _listenToActiveBlueprintChange(String? blueprintID) {
    if (blueprintID != null) {
      unsubscribe();
      databaseSubscription = dbCom.listenToActiveBlueprintChange(blueprintID,
          uiCallback: notifyListeners);
    } else {
      //print("LALALALALALALALA");
    }
  }

  Future<void> initialize() async {
    await dbCom.initFirebase();
    _listenToActiveBlueprintChange(
        dbCom.model.getActiveBlueprint()?.getBlueprintID());
    //print(dbCom.model.getActiveBlueprint()?.getBlueprintID());
  }

  //Change which blueprint is active and therefore also from which we are listening to changes.
  Future<void> changeActiveBlueprint(String blueprintID) async {
    String? userID = dbCom.model.getCurrentUser()?.getUserID();
    if (userID != null) {
      await dbCom.changeActiveBlueprint(userID, blueprintID);
      _listenToActiveBlueprintChange(blueprintID);
    }
  }

  bool shouldShowBlueprint() {
    return dbCom.model.shouldShowBlueprint();
  }

  void setShowBlueprint(bool value) {
    dbCom.model.setShowBlueprint(value);
    notifyListeners();
  }

  Blueprint? getActiveBlueprint() {
    return dbCom.model.getCurrentUser()!.getActiveBlueprint();
  }

  void unsubscribe() {
    databaseSubscription?.cancel();
  }

//Adds a tile to the active blueprint's database
  void addTileToActiveBlueprint(Color color, String geohash) async {
    FirebaseDatabase database = FirebaseDatabase.instance;
    DatabaseReference ref = database.ref().child(dbCom.blueprintsPath);
    //print("HERE");

    //reference blueprint ID.
    String? activeBlueprintID =
        dbCom.model.getActiveBlueprint()?.getBlueprintID();
    //print("HERE2: $activeBlueprintID");
    //print("HERE3: ${dbCom.model.getCurrentUser()?.getAvailableBlueprints()}");

    if (activeBlueprintID != null)
      print("The active blueprint ID: $activeBlueprintID");

    //Add tile to database if we have a valid active blueprint
    if (activeBlueprintID != null) {
      DatabaseReference activeBlueprintRef = ref.child(activeBlueprintID);

      DatabaseReference newTileRef =
          activeBlueprintRef.child("tiles").child(geohash);
      //print("newtile: " + newTileRef.path);

      await newTileRef.set({"r": color.red, "g": color.green, "b": color.blue});
    }

    //notifyListeners();
  }
}

//Notifies the consumer of changes to the map database as well
class MapChangeNotifier extends ChangeNotifier {
  DatabaseCommunicator dbCom;
  MapChangeNotifier(this.dbCom);
  StreamSubscription<DatabaseEvent>? databaseSubscription;

  Future<void> initialize() async {
    await dbCom.initFirebase();
    _listenToTilesChange();
  }

  void _listenToTilesChange() {
    databaseSubscription =
        dbCom.listenToMapTilesChange(uiCallback: notifyListeners);
  }

  void unsubscribe() {
    databaseSubscription?.cancel();
  }

  //Uses transactions to change data that might get corrupted due to concurrent changes.
  //SUCH AS: editing a blot on the map.
  //It seems that a transaction can both get and post data in one go which should be CHEAPER $$$$$$ and also handles concurrency issues.
  void addTile(Color color, String geohash, bool penMode) async {
    FirebaseDatabase database = FirebaseDatabase.instance;
    DatabaseReference ref = database.ref().child(dbCom.tilesPath);
    DatabaseReference newTileRef = ref.child(geohash);
    //print("newtile: " + newTileRef.path);

    //Check if user wants to color or clear tile
    if (penMode) {
      await newTileRef.set({"r": color.red, "g": color.green, "b": color.blue});
    } else {
      await newTileRef.remove();
    }
  }

  //notifyListeners();
}

class GroupsChangeNotifier extends ChangeNotifier {
  DatabaseCommunicator dbCom;
  GroupsChangeNotifier(this.dbCom);
  StreamSubscription<DatabaseEvent>? databaseSubscription;

  Future<void> initialize() async {
    await dbCom.initFirebase();
    _listenToTilesChange();
  }

  void _listenToTilesChange() {
    String? userID = dbCom.model.getCurrentUser()?.getUserID();
    if (userID != null) {
      databaseSubscription = dbCom.listenToAvailableGroupsChange(userID,
          uiCallback: notifyListeners);
    }
  }

  void unsubscribe() {
    databaseSubscription?.cancel();
  }

  //Uses transactions to change data that might get corrupted due to concurrent changes.
  //SUCH AS: editing a blot on the map.
  //It seems that a transaction can both get and post data in one go which should be CHEAPER $$$$$$ and also handles concurrency issues.
  void createGroup(String groupName, String groupDescription) async {
    dbCom.addGroup(groupName, groupDescription);
  }

  void joinGroup(String groupID) async {
    dbCom.joinGroup(groupID);
  }

  void leaveGroup(String groupID) async {
    dbCom.leaveGroup(groupID);
  }

  //notifyListeners();
}

class AvailableBlueprintsNotifier extends ChangeNotifier {
  DatabaseCommunicator dbCom;
  AvailableBlueprintsNotifier(this.dbCom);
  StreamSubscription<DatabaseEvent>? databaseSubscription;

  Future<void> initialize() async {
    await dbCom.initFirebase();
    _listenToTilesChange();
  }

  void _listenToTilesChange() {
    String? userID = dbCom.model.getCurrentUser()?.getUserID();
    if (userID != null) {
      databaseSubscription = dbCom.listenToAvailableBlueprintsChange(userID,
          uiCallback: notifyListeners);
    }
  }

  void unsubscribe() {
    databaseSubscription?.cancel();
  }

  List<Blueprint> getAvailableBlueprints() {
    return dbCom.model.getCurrentUser()!.getAvailableBlueprints();
  }

  Blueprint? getActiveBlueprint() {
    return dbCom.model.getCurrentUser()!.getActiveBlueprint();
  }
}

//https://firebase.google.com/docs/flutter/setup?platform=android
//https://firebase.google.com/docs/database/flutter/start
//https://firebase.google.com/docs/database/flutter/structure-data
//This is the base communicator which has all functionality needed to communicate with the firebase database.
class DatabaseCommunicator {
  late final secureLocalStorage;
  //We instantiate the model here.
  late final Model model;

  final String tilesPath = "Tiles";
  final String usersPath = "Users";
  final String groupsPath = "Groups";
  final String blueprintsPath = "Blueprints";

  bool _hasBeenInitialized = false;

  final String _personalBlueprintName = "Personal Blueprint";

  //TODO USE THIS.
  //List<StreamSubscription<DatabaseEvent>> databaseSubscriptions = [];

  DatabaseCommunicator(this.model) {
    secureLocalStorage = FlutterSecureStorage();
  }

  Future<void> initFirebase() async {
    if (_hasBeenInitialized) return;
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    print("Inititializing database.");
    await _initUser();
    _hasBeenInitialized = true;

    //_listenToTilesChange();
  }

  //You can use the DatabaseEvent to read the data at a given path, as it exists at the time of the event. This event is triggered once when the listener is attached and again every time the data, including any children, changes.
  //Important: A DatabaseEvent is fired every time data is changed at the specified database reference, including changes to children. To limit the size of your snapshots, attach only at the highest level needed for watching changes. For example, attaching a listener to the root of your database is not recommended.
  //PREFER USING THIS OVER GET BECAUSE ITS CHEAPER (IN MONEY IT DOESN'T COST AS MUCH)
  //This is called once when the listener is attached and then everytime it changes.
  StreamSubscription<DatabaseEvent> listenToDataChange(String databasePath,
      Function(String?, Map<String, dynamic>, Function?) customCallback,
      {String? key, Function? uiCallback}) {
    FirebaseDatabase database = FirebaseDatabase.instance;
    DatabaseReference databaseRef = database.ref(databasePath);
    if (key != null) databaseRef = databaseRef.child(key);

    var subscription = databaseRef.onValue.listen((DatabaseEvent event) {
      //Do something when the data at this path changes.
      final data = event.snapshot.value;

      if (data != null && data != false) {
        Map<String, dynamic> dataMap = Map<String, dynamic>.from(data as Map);

        //Do something with the data
        customCallback(key, dataMap, uiCallback);
      } else if (uiCallback != null) {
        //If the data is null or false meaning, EMPTY, still update the UI because things could have been removed.
        uiCallback();
      }
    });

    return subscription;
  }

  //Listens to any changes in the user's database and updates both the groups list and the blueprints list in the model.
  Future<StreamSubscription<DatabaseEvent>> listenToUserChanges(String userID,
      {Function? uiCallback}) async {
    StreamSubscription<DatabaseEvent> newSub = listenToDataChange(
        usersPath, _updateUserModel,
        key: userID, uiCallback: uiCallback);
    //databaseSubscriptions.add(newSub);
    return newSub;
  }

  //Listens to changes to the user's set active blueprint ID and
  /* StreamSubscription<DatabaseEvent> listenToUserActiveBlueprintChange(String userID,
      {Function? uiCallback}) {
    StreamSubscription<DatabaseEvent> newSub = listenToDataChange(
        "$usersPath/$userID/activeBlueprintID", _updateUserGroups,
        uiCallback: uiCallback);
    //databaseSubscriptions.add(newSub);
    return newSub;
  } */

//Listens to changes in the current user's groups list and updates only the groups list in the model.
  StreamSubscription<DatabaseEvent> listenToAvailableGroupsChange(String userID,
      {Function? uiCallback}) {
    StreamSubscription<DatabaseEvent> newSub = listenToDataChange(
        "$usersPath/$userID/groups", _updateUserGroups,
        uiCallback: uiCallback);
    //databaseSubscriptions.add(newSub);
    return newSub;
  }

// Listens to changes in the current user's groups list and updates only the blueprints list in the model.
  StreamSubscription<DatabaseEvent> listenToAvailableBlueprintsChange(
      String userID,
      {Function? uiCallback}) {
    StreamSubscription<DatabaseEvent> newSub = listenToDataChange(
        "$usersPath/$userID/groups", _updateUserBlueprintsListModel,
        key: userID, uiCallback: uiCallback);
    //databaseSubscriptions.add(newSub);
    return newSub;
  }

  //Listens to changes in the database of the provided blueprint ID and updates the model with the tiles from this blueprint
  StreamSubscription<DatabaseEvent> listenToActiveBlueprintChange(
      String blueprintID,
      {Function? uiCallback}) {
    StreamSubscription<DatabaseEvent> newSub = listenToDataChange(
        blueprintsPath, _updateActiveBlueprintModel,
        key: blueprintID, uiCallback: uiCallback);
    //databaseSubscriptions.add(newSub);
    return newSub;
  }

  //Listens to changes in the database for the map tiles and updates the model with these tiles.
  StreamSubscription<DatabaseEvent> listenToMapTilesChange(
      {Function? uiCallback}) {
    StreamSubscription<DatabaseEvent> newSub = listenToDataChange(
        tilesPath, _updateTilesModel,
        uiCallback: uiCallback);
    //databaseSubscriptions.add(newSub);
    return newSub;
  }

// FUNCTIONS THAT POPULATE THE MODEL WITH DATA ----------------------------------------------------
  Future<void> _initUserModel(String userID) async {
    User currentUser = User(userID);
    model.setCurrentUser(currentUser);
    _saveSecureStringLocally("uID", userID);

    DatabaseReference ref =
        FirebaseDatabase.instance.ref(usersPath + "/" + userID);
    // Get the data once
    DatabaseEvent event = await ref.once();
    final data = event.snapshot.value;
    if (data != null) {
      Map<String, dynamic> dataMap = Map<String, dynamic>.from(data as Map);
      //Do something with the data
      await _updateUserModel(userID, dataMap, () {});
    }
  }

  Future<void> _updateUserModel(String? userID, Map<String, dynamic> data,
      Function? onModelUpdateCallback) async {
    //print("What is this:" + data.keys.toString());

    if (data != null) {
      Map<String, dynamic> dataMap = Map<String, dynamic>.from(data);
      //print("USERDATAMAP $dataMap");
      //GROUPS
      Map<String, dynamic> groups = {};
      if (dataMap["groups"] != null && dataMap["groups"] != false) {
        groups = Map<String, dynamic>.from(dataMap["groups"]);
        //print("GROUPS $groups");
      }

      //TODO flytta upp i initUserModel ????? Troligen inte
      if (dataMap["activeBlueprintID"] != null &&
          dataMap["activeBlueprintID"] != false) {
        model.setActiveBlueprint(dataMap["activeBlueprintID"]);
      } else if (userID != null) {
        //changeActiveBlueprint(userID, _personalBlueprintName);
        model.setActiveBlueprint(userID);
      }

      //SAVING TO MODEL
      //Look in other places of the database to gather data and save to model.
      await _updateUserGroups(userID, groups, onModelUpdateCallback);
      await _updateUserBlueprintsListModel(
          userID, groups, onModelUpdateCallback);
    }
  }

//Updates the model of the active blueprint
  Future<void> _updateActiveBlueprintModel(
      String? blueprintIDToListenTo,
      Map<String, dynamic> blueprintData,
      Function? onModelUpdateCallback) async {
    String? blueprintID = blueprintIDToListenTo;
    //print("BLUEPRINT DATA: $blueprintData");
    if (blueprintID != null) {
      //print("The data: " + data.toString());
      //Add the blueprint to the model
      Blueprint blueprint = Blueprint.fromMap(blueprintID, blueprintData);
      //print("DA FOOKIN BLUEPRINT ${blueprint.getBlueprintID()}");

      //create new list with altered entry for the active blueprint.
      List<Blueprint>? availableBlueprints =
          model.getCurrentUser()?.getAvailableBlueprints();
      print(
          "TJAAAAAA1111 ${model.getCurrentUser()?.getAvailableBlueprints().map((e) => "${e.getName()}, ")}");

      if (availableBlueprints != null) {
        availableBlueprints
            .removeWhere((b) => b.getBlueprintID() == blueprintID);

        print(
            "TJAAAAAA2222 ${availableBlueprints.map((e) => "${e.getName()}, ")}");
        availableBlueprints.add(blueprint);

        //print("TILESS YO ${blueprint.getTiles()}");

        //Reset active blueprint to be this new version.
        model.setUserBlueprints(availableBlueprints);
        print(
            "TJAAAAAA ${model.getCurrentUser()?.getAvailableBlueprints().map((e) => "${e.getName()}, ")}");

        if (onModelUpdateCallback != null) onModelUpdateCallback();
      } else {
        print("ERROR: There is no user");
      }

      if (onModelUpdateCallback != null) onModelUpdateCallback();
    }
    //print(data.runtimeType.toString());
  }

  Future<void> _updateUserBlueprintsListModel(String? userID,
      Map<String, dynamic> groups, Function? onModelUpdateCallback) async {
    final ref = FirebaseDatabase.instance.ref().child(blueprintsPath);

    //BLUEPRINTS
    //The userID is NOT a group however it is a blueprint, so add it here.
    List<String> groupIDs = groups.keys.toList();
    //List<String> blueprintIDs = List.from(groupIDs);
    if (userID != null) groupIDs.add(userID);

    //print("GROUPIDS $groupIDs");

    List<Blueprint> newBlueprintsList = [];

    for (var iD in groupIDs) {
      //print(iD.toString());

      DatabaseReference blueprintRef = ref.child(iD);
      var snapshot = await blueprintRef.get();
      if (snapshot.exists) {
        final data = snapshot.value;

        if (data != null && data != false) {
          Map<String, dynamic> blueprintData =
              Map<String, dynamic>.from(data as Map);
          Blueprint blueprint = Blueprint.fromMap(iD, blueprintData);

          //print("DA FOOKIN BLUEPRINT ${blueprint.getBlueprintID()}");
          newBlueprintsList.add(blueprint);
        }
      }

      /*
      if (model.getActiveBlueprint() != null &&
          iD == model.getActiveBlueprint()?.getBlueprintID()) {
        //If the ID is that of the active blueprint we don't want to remove all its data, just pass it along to new list
        newBlueprintsList.add(model.getActiveBlueprint()!);
      } else {
      
        DatabaseReference blueprintRef = ref.child(iD);
        DatabaseReference nameRef = blueprintRef.child("blueprintName");
        var snapshot = await nameRef.get();
        print("Blueprint with ID: $iD, has a value of ${snapshot.value}");
        if (snapshot.exists) {
          //Do something when the data at this path changes.
          final name = snapshot.value;
          print("This is the data yoooooo: " + name.toString());
          if (name != null && name != false) {
            //Add the blueprint to the model
            Blueprint blueprint = Blueprint(iD, name.toString());
            print("DA FOOKIN BLUEPRINT ${blueprint.getBlueprintID()}");
            newBlueprintsList.add(blueprint);
          }
        } else {
          print('No data available.');
        } 
      }*/
    }

    //Set users blueprint list to these blueprints
    model.setUserBlueprints(newBlueprintsList);
    print(
        "TJOOOO ${model.getCurrentUser()?.getAvailableBlueprints().map((e) => "${e.getName()}, ")}");

    //print("TJOOOOO ${newBlueprintsList}");
    //print(data.runtimeType.toString());
    print("RUNNING THE CALLBACK");
    if (onModelUpdateCallback != null) onModelUpdateCallback();
  }

  Future<void> _updateUserGroups(String? _, Map<String, dynamic> groups,
      Function? onModelUpdateCallback) async {
    final ref = FirebaseDatabase.instance.ref().child(groupsPath);

    List<String> groupIDs = groups.keys.toList();
    List<Group> newGroupsList = [];

    for (var iD in groupIDs) {
      //print(iD.toString());
      DatabaseReference groupRef = ref.child(iD);
      var snapshot = await groupRef.get();

      if (snapshot.exists) {
        //Do something when the data at this path changes.
        final data = snapshot.value;
        if (data != null) {
          //print("The data: " + data.toString());

          Map<String, dynamic> dataMap = Map<String, dynamic>.from(data as Map);

          //Add the blueprint to the model
          Group group = Group.fromMap(iD, dataMap);
          newGroupsList.add(group);
        }
      } else {
        print('No data available.');
      }
    }

    //Set users blueprint list to these blueprints
    model.setUserGroups(newGroupsList);

    //print(data.runtimeType.toString());
    if (onModelUpdateCallback != null) onModelUpdateCallback();
  }

  void _updateTilesModel(
      String? _, Map<String, dynamic> data, Function? onModelUpdateCallback) {
    List<ColoredTile> newTilesList = [];

    data.forEach((key, value) {
      if (value != null && key != null) {
        Map<String, dynamic> tile = Map<String, dynamic>.from(value);
        //The assumption here is that "value" is another map.
        newTilesList.add(ColoredTile.fromMap(key, tile));
      }
    });

    model.setTiles(newTilesList);
    //Notify the ui that the database has changed.
    //print("THE CALLBACK $onModelUpdateCallback");
    if (onModelUpdateCallback != null) onModelUpdateCallback();
  }

//SAFE STORAGE FUNCTIONS --------------------------------------------------------------------------
  void _saveSecureStringLocally(String key, String? userID) async {
    // Write value
    if (userID != null) {
      await secureLocalStorage.write(key: key, value: userID);
    } else {
      print("Could not save since returned key is null");
    }
  }

  Future<String?> _getLocalSecureString(String key) async {
    // Read value
    String? value = await secureLocalStorage.read(key: key);

    return value;
  }

  Future<void> clearLocalSafeStorage() async {
    // Read value
    await secureLocalStorage.deleteAll();
  }

//Make it so that android is using EncryptedSharedPreferenses
  AndroidOptions _getAndroidOptions() => const AndroidOptions(
        encryptedSharedPreferences: true,
      );

//Initializes a new user if needed.
  Future<void> _initUser() async {
    //TODO REMOVE
    /* leaveAllGroups();
    removeAllGroups();
    removeAllBlueprints();
    clearLocalSafeStorage();
    removeAllUsers(); */
    //----------

    _getAndroidOptions();
    String? userID = await _getLocalSecureString("uID");

    if (userID == null) {
      //UserID not found locally, create new user on database and get new user ID
      userID = await _createNewUser();
      if (userID != null) {
        //Retrieve saved data on database (which will be empty) and populate model.
        await _initUserModel(userID);
      }
    } else {
      //We have the ID locally, make sure userID exists in the database as well
      DatabaseReference ref =
          FirebaseDatabase.instance.ref(usersPath + "/" + userID);
      DatabaseEvent event = await ref.once();
      final theUser = event.snapshot.value;
      if (theUser != null) {
        //the user exists BOTH locally and in the database so just initialize the user.
        await _initUserModel(userID);
      } else {
        //The user has been deleted on the database for some reason, perhaps an destructive update.
        print(
            "User not found on database perhaps due to some destructive update, creating new user");

        //delete potential old leftover personal blueprint. IMPORTANT! This cannot be after the next row.
        String oldLostUserID = userID.toString();
        _removeData("$blueprintsPath/$oldLostUserID");

        userID = await _createNewUser();
        if (userID != null) {
          await _initUserModel(userID);
        }
      }

      //Retrieve saved data on database and populate model.

      /* //Try to retrieve old active blueprint
      String? blueprintID = await _getLocalSecureString("activeBlueprintID");
      String? blueprintName =
          await _getLocalSecureString("activeBlueprintName");
      if (blueprintID != null && blueprintName != null) {
        //We found old active blueprint, try to retrieve it
        print(blueprintID + " " + blueprintName);
        changeActiveBlueprint(blueprintID, blueprintName);
      } else {
        //We did not find old active blueprint set to personal
        changeActiveBlueprint(userID, _personalBlueprintName);
      } */
    }

    // listen to changes in the current user's subdatabase
    //Needed to set the listener here and use initUserModel so we could wait on it,
    //Although they do the same thing ones triggered since the listener is triggered directly.

    if (userID != null) {
      await listenToUserChanges(userID);
    }
  }

  Future<void> _initPersonalBlueprint(String userID) async {
    //Blueprint newBlueprint = Blueprint(userID, _personalBlueprintName);
    //print("INIT PERSONAL");

    await _createNewBlueprintOnDatabase(userID, _personalBlueprintName);

    //Set this as the active one as we dont have any active blueprint in the beginning
    await changeActiveBlueprint(userID, userID);
  }

  Future<void> changeActiveBlueprint(String userID, String blueprintID) async {
    //print("CHANGING ACTIVE BLUEPRINT");

    await _pushEntryWithExistingKey(usersPath, userID,
        postData: {"activeBlueprintID": blueprintID});
  }

  Future<void> _createNewBlueprintOnDatabase(String key, String name) async {
    //FirebaseDatabase database = FirebaseDatabase.instance;
    //DatabaseReference ref = database.ref().child(blueprintsPath);
    //print("CREATING NEW");
    _pushEntryWithExistingKey(blueprintsPath, key,
        postData: {"blueprintName": name, "tiles": false});
  }

//Create a new group on the database
  void addGroup(String groupName, String description) async {
    Map<String, dynamic> newGroupData = {
      "name": groupName,
      "description": description,
      "membercount": 0,
    };

    String? gID = await _pushEntryWithUniqeGeneratedKey(groupsPath,
        postData: newGroupData);

    //Also create a matching blueprint for the group
    if (gID != null) {
      _createNewBlueprintOnDatabase(gID, groupName);
    }
  }

  void joinGroup(String groupID) async {
    String? currentUserID = model.getCurrentUser()?.getUserID();
    if (currentUserID != null) {
      //Find out if group exists
      DatabaseReference potentialGroupRef =
          FirebaseDatabase.instance.ref(groupsPath + "/" + groupID);
      DatabaseEvent groupExistsEvent = await potentialGroupRef.once();
      final theGroup = groupExistsEvent.snapshot.value;

      //Only join the group if it actually exists
      if (theGroup != null) {
        //Find if we are a part of the group
        DatabaseReference usersPotentialGroupIDRef = FirebaseDatabase.instance
            .ref("$usersPath/$currentUserID/groups/$groupID");
        DatabaseEvent userIsMemberEvent = await usersPotentialGroupIDRef.once();
        final theUsersGroupID = userIsMemberEvent.snapshot.value;

        //Only join the group if we are not already a part of it.
        if (theUsersGroupID == null) {
          Map<String, Object?> updates = {};
          updates["$groupsPath/$groupID/membercount"] =
              ServerValue.increment(1);
          updates["$usersPath/$currentUserID/groups/$groupID"] = {
            "Joined": true
          };

          FirebaseDatabase.instance.ref().update(updates);

          /* _pushEntryWithExistingKey(
            "$usersPath/$currentUserID/groups", "",
            postData: {groupID: true}); */
        }
      } else {
        print("Group doesn't exist");
      }

      //print(usersPath + "/" + currentUserID + "/groups");
    }
  }

  void leaveGroup(String groupID) async {
    String? uID = model.getCurrentUser()?.getUserID();
    if (uID != null) {
      //Find if we are a part of the group
      DatabaseReference usersPotentialGroupIDRef =
          FirebaseDatabase.instance.ref("$usersPath/$uID/groups/$groupID");
      DatabaseEvent userIsMemberEvent = await usersPotentialGroupIDRef.once();
      final theUsersGroupID = userIsMemberEvent.snapshot.value;

      //Only leave the group if we are already a part of it.
      if (theUsersGroupID != null) {
        Map<String, Object?> updates = {};
        updates["$groupsPath/$groupID/membercount"] = ServerValue.increment(-1);
        FirebaseDatabase.instance.ref().update(updates);

        _removeData("$usersPath/$uID/groups/$groupID");
      }
    }
  }

  void leaveAllGroups() {
    String? uID = model.getCurrentUser()?.getUserID();
    if (uID != null) {
      _removeData(usersPath + "/" + uID + "/groups");
    }
  }

  void removeAllGroups() {
    _removeData(groupsPath);
  }

  void removeAllBlueprints() {
    _removeData(blueprintsPath);
  }

  void removeAllUsers() {
    _removeData(usersPath);
  }

  Future<String?> _createNewUser() async {
    FirebaseDatabase database = FirebaseDatabase.instance;
    DatabaseReference ref = database.ref().child(usersPath);

    //TODO generate a new ID.
    // A post entry.

    // Get a key for a new user.
    final newPostKey = ref.push().key;

    final postData = {"groups": null};
    final Map<String, dynamic> updates = {};
    updates['groups'] = false;
    updates['activeBlueprintID'] = false;

    //Also create a matching blueprint for the group
    if (newPostKey != null) {
      DatabaseReference newEntryRef = ref.child(newPostKey);

      await newEntryRef.update(updates).then((_) {
        // Data saved successfully!
        print("Data saved Successfully");
      }).catchError((error) {
        // The write failed...
        print("Data write failed");
      });

      await _initPersonalBlueprint(newPostKey);
    }

    //return FirebaseDatabase.instance.ref().update(updates);
    return newPostKey;
  }

  //Returns the key
  Future<String?> _pushEntryWithUniqeGeneratedKey(String databasePath,
      {Map<String, dynamic> postData = const {}}) async {
    FirebaseDatabase database = FirebaseDatabase.instance;
    DatabaseReference ref = database.ref().child(databasePath);

    //generate a new ID.
    final newPostKey = ref.push().key;

    // Write the new post's data simultaneously in the posts list and the
    // user's post list.
    final Map<String, Map> updates = {};
    updates['$newPostKey'] = postData;
    //updates['$newPostKey'] = postData;

    ref.update(updates).then((_) {
      // Data saved successfully!
      print("Data saved Successfully");
    }).catchError((error) {
      // The write failed...
      print("Data write failed");
    });

    return newPostKey;
  }

  Future<void> _pushEntryWithExistingKey(String databasePath, String key,
      {Map<String, dynamic> postData = const {}}) async {
    FirebaseDatabase database = FirebaseDatabase.instance;
    DatabaseReference ref = database.ref().child(databasePath);
    DatabaseReference newEntryRef = ref.child(key);
    // Write the new post's data simultaneously in the posts list and the
    // user's post list.
    //final Map<String, Map> updates = {};
    //updates['$key'] = postData;
    //updates['$newPostKey'] = postData;
    //print(databasePath + "/" + key);

    await newEntryRef.update(postData).then((_) {
      // Data saved successfully!
      print("Data saved Successfully");
    }).catchError((error) {
      // The write failed...
      print("Data write failed");
    });
  }

//Just use these to see that we can post anything.
  /* Future<void> connectionTest() async {
    FirebaseDatabase database = FirebaseDatabase.instance;
    DatabaseReference ref = database.ref();
    print("conn test");

    final newPostKey = ref.push().key;
    print(newPostKey);

    final postData = {
      'groups': "",
    };

    // Write the new post's data simultaneously in the posts list and the
    // user's post list.
    final Map<String, Map> updates = {};
    updates['/Test/$newPostKey'] = postData;
    //updates['/user-posts/$uid/$newPostKey'] = postData;

    FirebaseDatabase.instance.ref().update(updates).then((_) {
      // Data saved successfully!
      print("Data saved Successfully");
    }).catchError((error) {
      // The write failed...
      print("Data write failed");
    });
  } */

  void _removeData(String databasePath) async {
    FirebaseDatabase database = FirebaseDatabase.instance;
    DatabaseReference ref = database.ref(databasePath);
    await ref.remove().then((_) {
      // Data removed successfully!
    }).catchError((error) {
      // The remove failed...
    });
    //notifyListeners();
  }
/*

  void removeMultiple(String name) async {
    //TODO generate a new ID.
    // A post entry.
    final postData = {null};

    // Get a key for a new user.
    final newPostKey = database.ref('users').push().key;
    User newUser = User(name, newPostKey);

    final Map<String, Map> updates = {};
    updates['/posts/$newPostKey'] = postData;
    updates['/user-posts/$uid/$newPostKey'] = postData;

    return FirebaseDatabase.instance.ref().update(updates);
  }

    */

  //Using atomic server-side increments.
  //Doesn't get automatically rerun if conflict but there should not be any conflicts since the increment is run directly on the server.
  /* void addStar(uid, key) async {
    Map<String, Object?> updates = {};
    updates["posts/$key/stars/$uid"] = true;
    updates["posts/$key/starCount"] = ServerValue.increment(1);
    updates["user-posts/$key/stars/$uid"] = true;
    updates["user-posts/$key/starCount"] = ServerValue.increment(1);
    return FirebaseDatabase.instance.ref().update(updates);
  } */
}
