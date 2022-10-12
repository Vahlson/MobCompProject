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
        create: (context) => BlueprintChangeNotifier(dbCom),
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
  late MapChangeNotifier mapNotifier;
  final MapController _mapController = MapController();
  late Stream<MapEvent> _mapStream;
  late GeoMap geomap;
  Color selectedColor = Colors.black;
  num selectedOpacity = 1;
  final List<Color> colourPaletteHex = [
    Color(0xff8F4D7F),
    Color(0xff993538),
    Color(0xff994A00),
    Color(0xff997923),
    Color(0xff537917),
    Color(0xffEF81D3),
    Color(0xffFF595E),
    Color(0xffFF7B00),
    Color(0xffFFCA3A),
    Color(0xff8AC926),
    Color(0xffF9CDED),
    Color(0xffFFBDBF),
    Color(0xffFFCA99),
    Color(0xffFFEAB0),
    Color(0xffD0E9A8),
    Color(0xff112871),
    Color(0xff106D74),
    Color(0xff402E58),
    Color(0xff828282),
    Color(0xff000000),
    Color(0xff1D43BC),
    Color(0xff1AB5C1),
    Color(0xff6A4C93),
    Color(0xffCDCDCD),
    Color(0xffFFFFFF),
    Color(0xffA5B4E4),
    Color(0xffA3E1E6),
    Color(0xffC3B7D4),
    Color(0xffF0F0F0),
    Color(0xffF0F0F0).withOpacity(0),
  ];

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

          //TODO REMOVE!
          Provider.of<BlueprintChangeNotifier>(context, listen: false)
              .createNewBlueprint();

          Provider.of<BlueprintChangeNotifier>(context, listen: false).addTile(
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
    await Provider.of<BlueprintChangeNotifier>(context, listen: false)
        .initialize();
  }

  void _paletteModalBottomSheet(context) {
    showModalBottomSheet(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            // <-- SEE HERE
            topLeft: Radius.circular(20.0),
            topRight: Radius.circular(20.0),
          ),
        ),
        isScrollControlled: true,
        context: context,
        builder: (BuildContext bc) {
          return Padding(
            padding: const EdgeInsets.all(32.0),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              //gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 48),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5),
              itemCount: colourPaletteHex.length,
              itemBuilder: (context, index) {
                return colorButton(colourPaletteHex[index]);
                //DialKey(colour: colourPaletteHex[index]);
              },
            ),
          );
        });
  }

  Widget colorButton(Color colorOnButton) {
    return InkWell(
      onTap: () {
        setState(() {
          selectedColor = colorOnButton;
          Navigator.pop(context);
        });
      },
      customBorder: const CircleBorder(),
      child: Container(
        width: 48,
        height: 48,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorOnButton,
          shape: BoxShape.circle,
          border: Border.all(
              color: Colors.grey.withOpacity(0.6),
              width: (colorOnButton == selectedColor) ? 5 : 0),
        ),
      ),
    );
  }

  void _showNavMenu(context) {
    showModalBottomSheet(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            // <-- SEE HERE
            topLeft: Radius.circular(20.0),
            topRight: Radius.circular(20.0),
          ),
        ),
        context: context,
        builder: (BuildContext bc) {
          return Wrap(
            children: [Container(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(onPressed: (){}, icon: const Icon(Icons.map))
                ],
              ),
            )],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("map"),
        actions: [
          IconButton(
              icon: Icon((selectedOpacity == 1) ? Icons.water_drop : ((selectedOpacity == 0.5) ? Icons.opacity : Icons.water_drop_outlined)),
              onPressed: () {
                setState(() {
                  if (selectedOpacity == 1) {
                    selectedOpacity = 0.5;
                  } else if (selectedOpacity == 0.5) {
                    selectedOpacity = 0;
                  } else {
                    selectedOpacity = 1;
                  }
                });
              }),
        ],
      ),
      body: Center(
        child: Container(
          height: 900,
          child: Consumer<MapChangeNotifier>(
            builder: (context, changeNotifier, child) {
              return geomap.showMap(changeNotifier.dbCom.model);
            },
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        child: Row(
          children: [
            IconButton(icon: const Icon(Icons.menu), onPressed: () {
              _showNavMenu(context);
            }),
            const Spacer(),
            IconButton(icon: const Icon(Icons.architecture), onPressed: () {}),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: selectedColor,
        onPressed: () {
          _paletteModalBottomSheet(context);
        },
        child: const Icon(Icons.palette),
      ),
    floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}