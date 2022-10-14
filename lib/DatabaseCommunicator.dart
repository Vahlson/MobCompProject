import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';

import 'model/Model.dart';

class BlueprintChangeNotifier extends ChangeNotifier {
  DatabaseCommunicator dbCom;
  BlueprintChangeNotifier(this.dbCom);

  void _listenToBlueprintChange() {
    dbCom.listenToDataChange(dbCom.blueprintsPath, _saveBlueprintTileToModel);
  }

  Future<void> initialize() async {
    await dbCom.initFirebase();
    //TODO enable
    //_listenToBlueprintChange();
  }

  void _saveBlueprintTileToModel(Map<String, dynamic> data) {
    List<ColoredTile> newBlueprintTilesList = [];

    data.forEach((key, value) {
      if (value != null && key != null) {
        Map<String, dynamic> tile = Map<String, dynamic>.from(value);
        //The assumption here is that "value" is another map.
        newBlueprintTilesList.add(ColoredTile.fromMap(key, tile));
      }
    });

    //Update active blueprint in model
    dbCom.model.getActiveBlueprint()?.setTiles(newBlueprintTilesList);
  }

  void createNewBlueprint() async {
    String? blueprintID =
        await dbCom._createNewDatabaseEntryUnderPath(dbCom.blueprintsPath);
    if (blueprintID != null) {
      Blueprint newBlueprint = Blueprint(blueprintID);
      dbCom.model.addBlueprint(newBlueprint);

      //Set this as the active one if we dont have an active blueprint
      if (dbCom.model.getActiveBlueprint() == null) {
        dbCom.model.setActiveBlueprint(newBlueprint);
      }
    }
  }

//Adds a tile to the active blueprint's database
  void addTile(Color color, String geohash) async {
    FirebaseDatabase database = FirebaseDatabase.instance;
    DatabaseReference ref = database.ref().child(dbCom.blueprintsPath);

    //reference blueprint ID.
    String? activeBlueprintID =
        dbCom.model.getActiveBlueprint()?.getBlueprintID();

    //Add tile to database if we have a valid active blueprint
    if (activeBlueprintID != null) {
      DatabaseReference activeBlueprintRef = ref.child(activeBlueprintID);

      DatabaseReference newTileRef = activeBlueprintRef.child(geohash);
      //print("newtile: " + newTileRef.path);

      await newTileRef.set({"r": color.red, "g": color.green, "b": color.blue});
    }
  }
}

//Notifies the consumer of changes to the map database as well
class MapChangeNotifier extends ChangeNotifier {
  DatabaseCommunicator dbCom;
  MapChangeNotifier(this.dbCom);

  Future<void> initialize() async {
    await dbCom.initFirebase();
    _listenToTilesChange();
  }

  void _listenToTilesChange() {
    dbCom.listenToDataChange(dbCom.tilesPath, _saveTilesToModel);
  }

  void _saveTilesToModel(Map<String, dynamic> data) {
    List<ColoredTile> newTilesList = [];

    data.forEach((key, value) {
      if (value != null && key != null) {
        Map<String, dynamic> tile = Map<String, dynamic>.from(value);
        //The assumption here is that "value" is another map.
        newTilesList.add(ColoredTile.fromMap(key, tile));
      }
    });

    dbCom.model.setTiles(newTilesList);
    //Notify everything that the database has changed.
    notifyListeners();
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
    if(penMode){
      await newTileRef.set({"r": color.red, "g": color.green, "b": color.blue});
    } else {
      await newTileRef.remove();
    }
  }

  void removeAllTiles() {
    dbCom._removeData(dbCom.tilesPath);
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
  final String blueprintsPath = "Blueprints";

  bool _hasBeenInitialized = false;

  DatabaseCommunicator(this.model) {
    secureLocalStorage = FlutterSecureStorage();

    //initFirebase();
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
  void listenToDataChange(
      String databasePath, Function(Map<String, dynamic>) customCallback) {
    FirebaseDatabase database = FirebaseDatabase.instance;
    DatabaseReference databaseRef = database.ref(databasePath);
    databaseRef.onValue.listen((DatabaseEvent event) {
      //Do something when the data at this path changes.
      final data = event.snapshot.value;

      //print(data.runtimeType.toString());
      if (data != null) {
        Map<String, dynamic> dataMap = Map<String, dynamic>.from(data as Map);
        //Do something with the data
        customCallback(dataMap);
      }
    });
  }

  /* void _listenToTilesChange() {
    _listenToDataChange(tilesPath, _saveTilesToModel);
  }

  void _saveTilesToModel(Map<String, dynamic> data) {
    List<ColoredTile> newTilesList = [];
    //print("AAAAAAAAAAAA");

    //print("Found data in database" + data.toString());

    data.forEach((key, value) {
      if (value != null && key != null) {
        //print("val: " + value.runtimeType.toString());
        Map<String, dynamic> tile = Map<String, dynamic>.from(value);
        //The assumption here is that "value" is another map.
        newTilesList.add(ColoredTile.fromMap(key, tile));
        //print(newTilesList);

        //print("tile gathered" + ColoredTile.fromMap(key, tile).toString());
      }
    });

    model.setTiles(newTilesList);
  } */

/*
//WARNING DONT USE THIS, UNLESS ABSOLUTELY NECESSARY.
  void getData(String databasePath) async {
    FirebaseDatabase database = FirebaseDatabase.instance;
    DatabaseReference ref = database.ref().child(databasePath);

    final snapshot = await ref.get();
    if (snapshot.exists) {
      print(snapshot.value);
    } else {
      print('No data available.');
    }
  }

  //For data that changes infrequently, like never, and needs to be fetched once use this
  void getDataOnce(String databasePath) async {
    FirebaseDatabase database = FirebaseDatabase.instance;
    DatabaseReference ref = database.ref().child(databasePath);

    final event = await ref.once(DatabaseEventType.value);
    //final username = event.snapshot.value?.username ?? 'Anonymous';
    //Read the data from the event.
  }
*/

//SAFE STORAGE FUNCTIONS ----------------------------------------------
  void _saveUserIDLocally(String? userID) async {
    // Write value
    if (userID != null) {
      await secureLocalStorage.write(key: "uID", value: userID);
    } else {
      print("Could not save since returned key is null");
    }
  }

  Future<String?> _getLocalUserID() async {
    // Read value
    String? value = await secureLocalStorage.read(key: "uID");

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
    _getAndroidOptions();
    String? userID = await _getLocalUserID();
    if (userID == null) {
      String? generatedKey = await _createNewUser();
      _saveUserIDLocally(generatedKey);
    } else {
      //We have the ID locally, make sure it exists in the database as well?

    }
  }

  Future<String?> _createNewUser() async {
    FirebaseDatabase database = FirebaseDatabase.instance;
    DatabaseReference ref = database.ref().child(usersPath);

    //TODO generate a new ID.
    // A post entry.

    // Get a key for a new user.
    final newPostKey = ref.push().key;

    final postData = {
      'groups': "",
    };

    // Write the new post's data simultaneously in the posts list and the
    // user's post list.
    final Map<String, Map> updates = {};
    updates['/Users/$newPostKey'] = postData;
    //updates['/user-posts/$uid/$newPostKey'] = postData;
    //print("Här");

    FirebaseDatabase.instance.ref().update(updates).then((_) {
      // Data saved successfully!
      print("Data saved Successfully");
    }).catchError((error) {
      // The write failed...
      print("Data write failed");
    });

    //return FirebaseDatabase.instance.ref().update(updates);
    return newPostKey;
  }

  //Returns the key
  Future<String?> _createNewDatabaseEntryUnderPath(String databasePath,
      {Map<String, dynamic> postData = const {}}) async {
    FirebaseDatabase database = FirebaseDatabase.instance;
    DatabaseReference ref = database.ref().child(usersPath);

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
