import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:firebase_database/firebase_database.dart';

import 'model/Model.dart';

//https://firebase.google.com/docs/flutter/setup?platform=android
//https://firebase.google.com/docs/database/flutter/start
//https://firebase.google.com/docs/database/flutter/structure-data
class DatabaseCommunicator {
  //TODO maybe initialize on constructor.

  Future<void> initFirebase() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  //Overwrites all data at specified location
  Future<void> setUser(User user) async {
    //String? userID = user.getUserID();
    //DatabaseReference ref = database.ref("users/$userID");
    FirebaseDatabase database = FirebaseDatabase.instance;

    DatabaseReference ref = database.ref().child("Users");
    //DatabaseReference ref = FirebaseDatabase.instance.ref("Users/");

    //Probably needs to specify all data at top location.
    await ref.set({
      "name": "Joel",
    }).then((_) {
      // Data saved successfully!
    }).catchError((error) {
      // The write failed...
    });
    ;
  }

/*
  //Updates specified data of user.
  Future<void> updateUserName(User user, String newUserName) async {
    String userID = user.getUserID();
    DatabaseReference ref = database.ref("users/$userID");

    // Only update the one property!
    await ref.update({
      "name": newUserName,
    }).then((_) {
      // Data saved successfully!
    }).catchError((error) {
      // The write failed...
    });
  } */

  /* The update() method accepts a sub-path to nodes, allowing you to update multiple nodes on the database at once:

  DatabaseReference ref = FirebaseDatabase.instance.ref("users");

  await ref.update({
    "123/age": 19,
    "123/address/line1": "1 Mountain View",
  }); */

  //You can use the DatabaseEvent to read the data at a given path, as it exists at the time of the event. This event is triggered once when the listener is attached and again every time the data, including any children, changes.
  //Important: A DatabaseEvent is fired every time data is changed at the specified database reference, including changes to children. To limit the size of your snapshots, attach only at the highest level needed for watching changes. For example, attaching a listener to the root of your database is not recommended.
  //PREFER USING THIS OVER GET BECAUSE ITS CHEAPER (IN MONEY IT DOESN'T COST AS MUCH)
  //This is called once when the listener is attached and then everytime it changes.
  void listenToDataChange(String databasePath) {
    FirebaseDatabase database = FirebaseDatabase.instance;
    DatabaseReference databaseRef = database.ref(databasePath);
    databaseRef.onValue.listen((DatabaseEvent event) {
      //Do something when the data at this path changes.
      final data = event.snapshot.value;
      //updateStarCount(data);
      print(data);
    });
  }

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

  void createNewUser() async {
    FirebaseDatabase database = FirebaseDatabase.instance;
    DatabaseReference ref = database.ref().child("Users");

    //TODO generate a new ID.
    // A post entry.

    // Get a key for a new user.
    final newPostKey = ref.push().key;

    final postData = {
      'groups': "",
    };

    //User newUser = User(name, newPostKey);
    // Write the new post's data simultaneously in the posts list and the
    // user's post list.
    final Map<String, Map> updates = {};
    updates['/Users/$newPostKey'] = postData;
    //updates['/user-posts/$uid/$newPostKey'] = postData;

    return FirebaseDatabase.instance.ref().update(updates);
  }

/*
  void removeData(String databasePath) async {
    final ref = database.ref(databasePath);
    await ref.remove().then((_) {
      // Data removed successfully!
    }).catchError((error) {
      // The remove failed...
    });
  }


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

/*
  //Uses transactions to change data that might get corrupted due to concurrent changes.
  //SUCH AS: editing a blot on the map.
  //It seems that a transaction can both get and post data in one go which should be CHEAPER $$$$$$ and also handles concurrency issues.
  void paintTile(String uid, Color color) async {
    DatabaseReference postRef = FirebaseDatabase.instance.ref("");

    //Create transaction with transaction handler.
    TransactionResult result = await postRef.runTransaction((Object? post) {
      // Ensure a post at the ref exists.
      if (post == null) {
        return Transaction.abort();
      }

      Map<String, dynamic> _post = Map<String, dynamic>.from(post as Map);
      if (_post["texels"] is Map && _post["texels"][uid] != null) {
        //_post["starCount"] = (_post["starCount"] ?? 1) - 1;
        _post["texels"][uid] = null;
      } else {
        //_post["starCount"] = (_post["starCount"] ?? 0) + 1;
        if (!_post.containsKey("texels")) {
          _post["texels"] = {};
        }
        _post["texels"][uid] = true;
      }

      // Return the new data.
      return Transaction.success(_post);
    }
        //, applyLocally: false  USE this if we don't want events raised on each transaction function update but only on completion.
        );

    print('Committed? ${result.committed}'); // true / false
    print('Snapshot? ${result.snapshot}'); // DataSnapshot
/* 
    if (user !== null) {
    return Transaction.abort();
  }
 */
  }

  //Using atomic server-side increments.
  //Doesn't get automatically rerun if conflict but there should not be any conflicts since the increment is run directly on the server.
  void addStar(uid, key) async {
    Map<String, Object?> updates = {};
    updates["posts/$key/stars/$uid"] = true;
    updates["posts/$key/starCount"] = ServerValue.increment(1);
    updates["user-posts/$key/stars/$uid"] = true;
    updates["user-posts/$key/starCount"] = ServerValue.increment(1);
    return FirebaseDatabase.instance.ref().update(updates);
  }

  */
}
