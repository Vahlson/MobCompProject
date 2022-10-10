import 'package:artmap/DatabaseCommunicator.dart';
import 'package:dart_geohash/dart_geohash.dart';
import 'package:flutter/material.dart';
import 'model/Model.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';

import 'map.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => DatabaseCommunicator(),
      child: const MyApp(),
    ),
  );
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
  late DatabaseCommunicator db;
  final MapController _mapController = MapController();
  late Stream<MapEvent> _mapStream;
  late GeoMap geomap;
  Color selectedColor = Colors.blue;

  //Move this
  GeoHasher _geoHasher = GeoHasher();

  initMap() {
    _mapStream = _mapController.mapEventStream;
    geomap = GeoMap(_mapController);

    geomap.initGeoMap();

    //Checks for user taps
    _mapStream.listen((event) {
      if (event.source == MapEventSource.tap) {
        MapEventTap tap = event as MapEventTap;
        setState(() {
          //Change this to just publishing tile to database
          //geomap.addPolygon(tap.tapPosition, selectedColor);
          Provider.of<DatabaseCommunicator>(context, listen: false).addTile(
              selectedColor,
              _geoHasher.encode(
                  tap.tapPosition.longitude, tap.tapPosition.latitude));
        });
      } else {
        setState(() {
          geomap.onMapMove();
        });
      }
    });
  }

  @override
  void initState() {
    //db = DatabaseCommunicator();
    //db.initFirebase();

    // TODO: implement initState
    initMap();

    super.initState();
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
          child: Consumer<DatabaseCommunicator>(
            builder: (context, dbCommunicator, child) {
              return geomap.showMap();
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: selectedColor,
        onPressed: () {
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
