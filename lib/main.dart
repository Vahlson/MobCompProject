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
  int _counter = 0;
  late MapChangeNotifier mapNotifier;
  final MapController _mapController = MapController();
  late Stream<MapEvent> _mapStream;
  late GeoMap geomap;
  Color selectedColor = Colors.blue;
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

/*
  static var colourPaletteHex = [
    '8F4D7F','993538','994A00','997923','537917',
    'EF81D3','FF595E','FF7B00','FFCA3A','8AC926',
    'F9CDED','FFBDBF','FFCA99','FFEAB0','D0E9A8',
    '112871','106D74','402E58','828282','000000',
    '1D43BC','1AB5C1','6A4C93','CDCDCD','FFFFFF',
    'A5B4E4','A3E1E6','C3B7D4','F0F0F0','',
  ];
*/

  //Move this
  GeoHasher _geoHasher = GeoHasher();

  //TODO Remove?
  bool isBlueprintEditing = false;

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
          if (!isBlueprintEditing) {
            Provider.of<MapChangeNotifier>(context, listen: false).addTile(
                selectedColor,
                _geoHasher.encode(
                    tap.tapPosition.longitude, tap.tapPosition.latitude,
                    precision: 8));
          } else {
            Provider.of<BlueprintChangeNotifier>(context, listen: false)
                .addTileToActive(
                    selectedColor,
                    _geoHasher.encode(
                        tap.tapPosition.longitude, tap.tapPosition.latitude,
                        precision: 8));
          }
        }
        //});
      } else {
        setState(() {
          geomap.onMapMove();
        });
      }
    });
  }

  void _paletteModalBottomSheet2(context) {
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
          return Padding(
            padding: const EdgeInsets.all(32.0),
            child: GridView.builder(
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

  @override
  void dispose() {
    Provider.of<MapChangeNotifier>(context, listen: false).unsubscribe();
    Provider.of<BlueprintChangeNotifier>(context, listen: false).unsubscribe();

    super.dispose();
  }

  void initDatabase() async {
    await Provider.of<MapChangeNotifier>(context, listen: false).initialize();
    await Provider.of<BlueprintChangeNotifier>(context, listen: false)
        .initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("map"),
        backgroundColor: isBlueprintEditing
            ? Color.fromRGBO(0, 0, 255, 1)
            : Color.fromRGBO(255, 0, 0, 1),
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
      bottomNavigationBar: BottomAppBar(
        child: Row(
          children: [
            IconButton(
                icon: Icon(Icons.palette),
                onPressed: () {
                  _paletteModalBottomSheet2(context);
                }),
            IconButton(
                icon: Icon(Icons.architecture),
                onPressed: () {
                  setState(() {
                    isBlueprintEditing = !isBlueprintEditing;
                  });
                }),
            IconButton(
                icon: Icon(Icons.opacity),
                onPressed: () {
                  Provider.of<MapChangeNotifier>(context, listen: false)
                      .dbCom
                      .joinGroup("-NEBsldj8C8UTOeaSnqP");

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
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: selectedColor,
        onPressed: () {
          /* Provider.of<DatabaseCommunicator>(context, listen: false)
              .removeAllTiles(); */

          Provider.of<MapChangeNotifier>(context, listen: false)
              .dbCom
              .addGroup("Cool group", "A cool group you should join");
          //db.clearLocalSafeStorage();
          setState(() {
            if (selectedColor == Colors.black) {
              selectedColor = Colors.blue;
            } else {
              selectedColor = Colors.black;
            }
          });
        },
        child: const Icon(Icons.check),
      ),
    );
  }
}









/*
class DialKey extends StatelessWidget {
  Color colour;
  //final Color color = HexColor.fromHex('#aabbcc');

  DialKey({required this.colour});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 48,
        height: 48,
        child: RadioListTile(value: colour,
          groupValue: _MyHomePageState.selectedColor,
          onChanged: onChanged),


        /*
        FloatingActionButton(
          elevation: 0,
          onPressed: () {

          },
          backgroundColor: colour,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            //children: [
            //],
          ),
        ),
        */
      ),
    );
  }
}
*/