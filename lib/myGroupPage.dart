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
            title: const Text("My groups"),
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
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateGroup()),
              );
            },
            backgroundColor: Colors.blue,
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}
