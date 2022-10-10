import 'package:artmap/DatabaseCommunicator.dart';
import 'package:dart_geohash/dart_geohash.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';
import 'model/Model.dart';

import 'map.dart';

void main() {
  Model model = Model();
  DatabaseCommunicator dbCom = DatabaseCommunicator(model);

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (context) => MapChangeNotifier(dbCom),
      ),
      ChangeNotifierProvider(
        create: (context) => BlueprintsChangeNotifier(dbCom),
      ),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Map test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  late MapChangeNotifier mapNotifier;
  final MapController _mapController = MapController();
  late Stream<MapEvent> _mapStream;
  late GeoMap geomap;
  Color selectedColor = Colors.blue;

  //Move this
  GeoHasher _geoHasher = GeoHasher();

  initMap() {
    _mapStream = _mapController.mapEventStream;
    geomap = GeoMap(_mapController);

    geomap.initGeoMap().then((_) => geomap.centerMapOnUser());

    //Checks for user taps
    _mapStream.listen((event) {
      if (event.source == MapEventSource.tap) {
        MapEventTap tap = event as MapEventTap;
        //setState(() {
        //Change this to just publishing tile to database
        if (geomap.isValidTilePosition(
            tap.tapPosition.latitude, tap.tapPosition.longitude)) {
          Provider.of<MapChangeNotifier>(context, listen: false).addTile(
              selectedColor,
              _geoHasher.encode(
                  tap.tapPosition.longitude, tap.tapPosition.latitude,
                  precision: 8));
        }
        //});
      } else {
        setState(() {
          geomap.onMapMove();
        });
      }
    });
  }

  /* void initDatabase() async{
    await Provider.of<DatabaseCommunicator>(context, listen: false).addTile
  } */

  void setUpFirebase() async {
    await Firebase.initializeApp();
  }

  @override
  void initState() {
    //db = DatabaseCommunicator();
    //db.initFirebase();

    // TODO: implement initState
    initMap();

    initDatabase();

    super.initState();
    //setUpFirebase();
  }

  void initDatabase() async {
    await Provider.of<MapChangeNotifier>(context, listen: false).initialize();
    await Provider.of<BlueprintsChangeNotifier>(context, listen: false)
        .initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("map"),
      ),
      body: Center(
        child: Container(
          height: 800,
          child: Consumer<MapChangeNotifier>(
            builder: (context, changeNotifier, child) {
              return geomap.showMap(changeNotifier.dbCom.model);
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: selectedColor,
        onPressed: () {
          /* Provider.of<DatabaseCommunicator>(context, listen: false)
              .removeAllTiles(); */

          //db.clearLocalSafeStorage();
          setState(() {
            if (selectedColor == Colors.black) {
              selectedColor = Colors.blue;
            } else {
              selectedColor = Colors.black;
            }
          });
        },
        child: const Icon(Icons.palette),
      ),
    );
  }
}
