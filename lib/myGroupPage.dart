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
/* 
    SingleChildScrollView(
        child: Consumer<GroupsChangeNotifier>(
          builder: (context, groupsChangeNotifier, child) {
            List<Group>? availableGroups = groupsChangeNotifier.dbCom.model
                .getCurrentUser()
                ?.getAvailableGroups();
            List<Widget> groupsList = [];

            //Get all
            if (availableGroups != null) {
              groupsList =
                  availableGroups.map((group) => GroupCard(group)).toList();
            }

            groupsList.insert(0,JoinGroup());

            return Column(children: const [groupsList]);
          },
        ),
      ), */

    return Consumer<GroupsChangeNotifier>(
      builder: (context, groupsChangeNotifier, child) {
        List<Group>? availableGroups = groupsChangeNotifier.dbCom.model
            .getCurrentUser()
            ?.getAvailableGroups();

        availableGroups ??= [];
        /* List<Widget> groupsList = [];

            //Get all
            if (availableGroups != null) {
              groupsList =
                  availableGroups.map((group) => GroupCard(group)).toList();
            }

            groupsList.insert(0,JoinGroup()); */

        return Scaffold(
          appBar: AppBar(
            title: const Text("My groups"),
          ),
          body: ListView.builder(
            itemCount: availableGroups.length + 1,
            /* prototypeItem: ListTile(
              title: Text(availableGroups?.first.name ?? "Is null"),
            ), */
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
