import 'package:artmap/DatabaseCommunicator.dart';
import 'package:artmap/myGroupPage.dart';
import 'package:dart_geohash/dart_geohash.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';
import 'model/Model.dart';
import 'customIcons.dart';
import 'myGroupPage.dart';
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
        create: (context) => ActiveBlueprintChangeNotifier(dbCom),
      ),
      ChangeNotifierProvider(
        create: (context) => GroupsChangeNotifier(dbCom),
      ),
      ChangeNotifierProvider(
        create: (context) => AvailableBlueprintsNotifier(dbCom),
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
      title: 'blot',
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
  bool penMode = true;

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
    Color(0xff000000),
    Color(0xffCDCDCD),
    Color(0xff1D43BC),
    Color(0xff1AB5C1),
    Color(0xff6A4C93),
    Color(0xff494949),
    Color(0xffF0F0F0),
    Color(0xffA5B4E4),
    Color(0xffA3E1E6),
    Color(0xffC3B7D4),
    Color(0xff828282),
    Color(0xffFFFFFF),
  ];

  //Move this
  GeoHasher _geoHasher = GeoHasher();

  //TODO Remove?

  initMap() {
    _mapStream = _mapController.mapEventStream;
    geomap = GeoMap(_mapController);

    geomap.initGeoMap().then((_) => geomap.centerMapOnUser());

    //Checks for user taps
    _mapStream.listen((event) async {
      if (event.source == MapEventSource.tap) {
        MapEventTap tap = event as MapEventTap;
        //setState(() {
        //Change this to just publishing tile to database
        if (geomap.isValidTilePosition(
            tap.tapPosition.latitude, tap.tapPosition.longitude)) {
          if (!Provider.of<ActiveBlueprintChangeNotifier>(context, listen: false).getIsBluePrintEditing()) {
            Provider.of<MapChangeNotifier>(context, listen: false).addTile(
                selectedColor,
                _geoHasher.encode(
                    tap.tapPosition.longitude, tap.tapPosition.latitude,
                    precision: 8),
                penMode);
          } else {
            Provider.of<ActiveBlueprintChangeNotifier>(context, listen: false)
                .addTileToActiveBlueprint(
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

  void setUpFirebase() async {
    await Firebase.initializeApp();
  }

  @override
  void initState() {
    initMap();

    initDatabase();

    super.initState();
    //setUpFirebase();
  }

  @override
  void dispose() {
    Provider.of<MapChangeNotifier>(context, listen: false).unsubscribe();
    Provider.of<ActiveBlueprintChangeNotifier>(context, listen: false)
        .unsubscribe();
    Provider.of<GroupsChangeNotifier>(context, listen: false).unsubscribe();
    Provider.of<AvailableBlueprintsNotifier>(context, listen: false)
        .unsubscribe();

    super.dispose();
  }

  void initDatabase() async {
    await Provider.of<MapChangeNotifier>(context, listen: false).initialize();
    await Provider.of<ActiveBlueprintChangeNotifier>(context, listen: false)
        .initialize();
    await Provider.of<GroupsChangeNotifier>(context, listen: false)
        .initialize();
    await Provider.of<AvailableBlueprintsNotifier>(context, listen: false)
        .initialize();
  }

  void _paletteModalBottomSheet(context) {
    showModalBottomSheet(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.0),
            topRight: Radius.circular(20.0),
          ),
        ),
        isScrollControlled: true,
        context: context,
        builder: (BuildContext bc) {
          return Padding(
            padding: const EdgeInsets.only(
                top: 16.0, bottom: 24.0, left: 24.0, right: 24.0),
            child: Wrap(
              children: [
                Row(
                  children: const [
                    Icon(
                      Icons.palette_rounded,
                    ),
                    SizedBox(
                      width: 8,
                    ),
                    Text(
                      "Palette",
                      style: TextStyle(fontSize: 22),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 48,
                ),
                GridView.builder(
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
              ],
            ),
          );
        });
  }

  Widget colorButton(Color colorOnButton) {
    return InkWell(
      onTap: () {
        setState(() {
          selectedColor = colorOnButton;
          penMode = true;
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
            topLeft: Radius.circular(20.0),
            topRight: Radius.circular(20.0),
          ),
        ),
        context: context,
        builder: (BuildContext context) {
          return Wrap(
            children: [Container(
              padding: const EdgeInsets.only(top: 16.0, bottom: 24.0, left: 24.0, right: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset("assets/icon.png", height: 22, width: 22,),
                      const SizedBox(width: 8,),
                      const Text("blot", style: TextStyle(fontSize: 22),),
                    ],
                  ),
                  const SizedBox(height: 16,),
                  //const Text("Navigate to"),
                  TextButton.icon(
                      onPressed: (){
                        setState(() {
                          Provider.of<ActiveBlueprintChangeNotifier>(context, listen: false).setIsBluePrintEditing(false);
                        });
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Provider.of<ActiveBlueprintChangeNotifier>(context, listen: false).getIsBluePrintEditing() ? Colors.black54 : Colors.black,
                      ),
                      icon: const Icon(Icons.map),
                      label: Row(children: const [Text("Map")])),
                  TextButton.icon(
                      onPressed: (){
                        Navigator.pop(context);
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const MyGroupPage(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.black54,
                      ),
                      icon: const Icon(Icons.group),
                      label: Row(children: const [Text("Groups")])),
                  TextButton.icon(
                      onPressed: (){
                        setState(() {
                          Provider.of<ActiveBlueprintChangeNotifier>(context, listen: false).setIsBluePrintEditing(true);
                        });
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Provider.of<ActiveBlueprintChangeNotifier>(context, listen: false).getIsBluePrintEditing() ? Colors.black : Colors.black54,
                      ),
                      icon: const Icon(Icons.architecture),
                      label: Row(children: const [Text("Edit blueprints")])),
                ],
              ),
            )],
          );
        });
  }

  void _showBlueprintMenu(parentContext) {
    showModalBottomSheet(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.0),
            topRight: Radius.circular(20.0),
          ),
        ),
        context: parentContext,
        builder: (BuildContext context) {
          return Consumer2<AvailableBlueprintsNotifier,
              ActiveBlueprintChangeNotifier>(
            builder: (context, availableBlueprintsNotifier,
                activeBlueprintChangeNotifier, child) {
              print("REBUILDING");
              return StatefulBuilder(builder:
                  (BuildContext context, StateSetter setActiveBlueprintState) {
                return Wrap(
                  children: [
                    Container(
                      padding: const EdgeInsets.only(
                          top: 16.0, bottom: 24.0, left: 24.0, right: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(
                                Icons.architecture,
                              ),
                              SizedBox(
                                width: 8,
                              ),
                              Text(
                                "Active blueprint",
                                style: TextStyle(fontSize: 22),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 16,
                          ),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            child: DropdownButtonFormField(
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Active blueprint',
                                ),
                                items: availableBlueprintsNotifier
                                    .getAvailableBlueprints()
                                    .map((Blueprint bp) {
                                  print("A blueprint yo: ${bp.getName()}");

                                  return DropdownMenuItem(
                                      value: bp.getBlueprintID(),
                                      child: Container(
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 8),
                                          child: Text(bp.getName())));
                                }).toList(),
                                value: activeBlueprintChangeNotifier
                                        .getActiveBlueprint()
                                        ?.getBlueprintID() ??
                                    "",
                                isExpanded: true,
                                onChanged: (value) {
                                  activeBlueprintChangeNotifier
                                      .changeActiveBlueprint(value!);
                                }),
                          ),
                          CheckboxListTile(
                              title: const Text("Show blueprint"),
                              value: activeBlueprintChangeNotifier
                                  .shouldShowBlueprint(),
                              onChanged: (value) {
                                setActiveBlueprintState(() {
                                  activeBlueprintChangeNotifier
                                      .setShowBlueprint(value!);
                                });
                              }),
                    ],
                  ),
                )],
              );
            },
          );
        });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Provider.of<ActiveBlueprintChangeNotifier>(context, listen: false).dbCom.model.getIsBluePrintEditing() ? Container(
          margin: const EdgeInsets.all(16.0),
          child: DropdownButtonFormField(
              decoration: const InputDecoration(
                labelText: 'Edit blueprint',
              ),
              items: Provider.of<ActiveBlueprintChangeNotifier>(context, listen: false).dbCom.model.getCurrentUser()!.getAvailableBlueprints().map((Blueprint bp) {
                return DropdownMenuItem(value: bp.getBlueprintID(), child: Container(margin: const EdgeInsets.symmetric(horizontal: 8), child: Text(bp.getName())));
              }).toList(),
              value: Provider.of<ActiveBlueprintChangeNotifier>(context, listen: false).dbCom.model.getCurrentUser()!.getActiveBlueprint()!.getBlueprintID(),
              isExpanded: true,
              onChanged: (value) {
                Provider.of<ActiveBlueprintChangeNotifier>(context, listen: false).dbCom.model.setActiveBlueprint(value!);
              }
          ),
        ) : const Text("Map"),
        actions: [
          IconButton(
              icon: const Icon(Icons.my_location),
              onPressed: () {
                geomap.centerMapOnUser();
              }),
          IconButton(
            //CHANGE TO THE CORRECT ICONS (Humidity high & low), NOT WATER DROPS
              icon: Icon((geomap.selectedOpacity == 1) ? CustomIcons.humidity_high : ((geomap.selectedOpacity == 0.5) ? CustomIcons.humidity_mid : CustomIcons.humidity_low),),
              onPressed: () {
                setState(() {
                  if (geomap.selectedOpacity == 1) {
                    geomap.selectedOpacity = 0.5;
                  } else if (geomap.selectedOpacity == 0.5) {
                    geomap.selectedOpacity = 0;
                  } else {
                    geomap.selectedOpacity = 1;
                  }
                });
              }),
        ],
        backgroundColor: Provider.of<ActiveBlueprintChangeNotifier>(context, listen: false).dbCom.model.getIsBluePrintEditing()
            ? Colors.lightBlue
            : Colors.black,
      ),
      body: Center(
        child: Container(
          height: 800,
          child: Consumer2<MapChangeNotifier, ActiveBlueprintChangeNotifier>(
              builder: (context, mapChangeNotifier, blueprintChangeNotifier,
                  widget) {
            //This consumes the notifying of two different notifiers. Splitting them up like this allows for more flexibility in what to rebuild, when.
            print("REBUILDING");
            return geomap.showMap(mapChangeNotifier.dbCom.model);
          }),
          /* //OLD
          Consumer<MapChangeNotifier>(
            builder: (context, changeNotifier, child) {
              print("REBUILDING");
              return geomap.showMap(changeNotifier.dbCom.model);
            },
          ), */
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        child: Row(
          children: [
            IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  _showNavMenu(context);
                }),
            const Spacer(),
            IconButton(
                icon: Center(
                  child: Stack(
                    children: <Widget>[
                      const Center(child: Icon(CustomIcons.eraser, size: 18)),
                      Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          height: penMode ? 0 : 36,
                          width: penMode ? 0 : 36,
                          decoration: const BoxDecoration(
                            color: Colors.black26,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                onPressed: () {
                  setState(() {
                    penMode = !penMode;
                  });
                }),
            IconButton(
                icon: const Icon(Icons.architecture),
                onPressed: () {
                  _showBlueprintMenu(context);
                }),
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
