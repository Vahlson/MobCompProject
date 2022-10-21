import 'package:artmap/main.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'DatabaseCommunicator.dart';
import 'groups.dart';
import 'model/Model.dart';

class MyGroupPage extends StatefulWidget {
  const MyGroupPage({super.key});

  @override
  State<MyGroupPage> createState() => _MyGroupPageState();
}


class _MyGroupPageState extends State<MyGroupPage> {

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
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const MyHomePage(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.black54,
                      ),
                      icon: const Icon(Icons.map),
                      label: Row(children: const [Text("Map")])),
                  TextButton.icon(
                      onPressed: (){
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.black,
                      ),
                      icon: const Icon(Icons.group),
                      label: Row(children: const [Text("Groups")])),
                  TextButton.icon(
                      onPressed: (){
                        setState(() {
                          Provider.of<ActiveBlueprintChangeNotifier>(context, listen: false).setIsBluePrintEditing(true);
                        });
                        Navigator.pop(context);
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const MyHomePage(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.black54,
                      ),
                      icon: const Icon(Icons.architecture),
                      label: Row(children: const [Text("Edit blueprints")])),
                ],
              ),
            )],
          );
        });
  }

  @override
  Widget build(BuildContext context) {

    return Consumer<GroupsChangeNotifier>(
      builder: (context, groupsChangeNotifier, child) {
        List<Group>? availableGroups = groupsChangeNotifier.dbCom.model
            .getCurrentUser()
            ?.getAvailableGroups();

        availableGroups ??= [];

        return Scaffold(
          appBar: AppBar(
            title: const Text("My groups", style: TextStyle(color: Colors.black),),
            backgroundColor: Colors.white,
          ),
          body: ListView.builder(
            itemCount: availableGroups.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                // return Football-Card
                return JoinGroup();
              } else {
                return ListTile(
                  title: GroupCard(availableGroups?[index-1] ?? Group("", "")),
                );
              }
            },
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
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CreateGroup()),
                      );
                    }),
              ],
            ),
          ),
        );
      },
    );
  }
}
