import 'package:artmap/myGroupPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'DatabaseCommunicator.dart';
import 'model/Model.dart';

class JoinGroup extends StatefulWidget {
  const JoinGroup({super.key});
  @override
  State<JoinGroup> createState() => _JoinGroupState();
}

TextEditingController textController = TextEditingController();
String groupID = "";

class _JoinGroupState extends State<JoinGroup> {
  TextEditingController joinGroupTxtCtrl = TextEditingController();

  String groupID = "";

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    joinGroupTxtCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 16, 0),
                child: TextFormField(
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(20),
                    //FilteringTextInputFormatter.allow(RegExp("[0-9a-zA-Z]")),
                  ],
                  style: const TextStyle(fontSize: 16),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Enter a group code',
                    //hintText: 'Enter the group code',
                  ),
                  controller: joinGroupTxtCtrl,
                ),
              ),
            ),
            ElevatedButton(
                onPressed: () {
                  setState(() {
                    groupID = joinGroupTxtCtrl.text;

                    Provider.of<GroupsChangeNotifier>(context, listen: false)
                        .joinGroup(groupID);

                    joinGroupTxtCtrl.clear();
                  });
                },
                child: const Text("Join")),
            //Text(displayText,style: const TextStyle(fontSize: 20),),
          ],
        ),
      ),
    );
  }
}

class CreateGroup extends StatefulWidget {
  const CreateGroup({super.key});
  @override
  State<CreateGroup> createState() => _CreateGroupState();
}

class _CreateGroupState extends State<CreateGroup> {
  TextEditingController grpNameTxtCtrl = TextEditingController();
  TextEditingController dscrpTxtCtrl = TextEditingController();
  TextEditingController urlTxtCtrl = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create new group')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: TextFormField(
                  controller: urlTxtCtrl,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Image url',
                    prefixIcon: Icon(Icons.image_rounded),
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: TextFormField(
                  controller: grpNameTxtCtrl,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Group Name',
                    prefixIcon: Icon(Icons.groups_rounded),
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: TextFormField(
                  controller: dscrpTxtCtrl,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Description',
                    prefixIcon: Icon(Icons.description_rounded),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Provider.of<GroupsChangeNotifier>(context, listen: false).createGroup(grpNameTxtCtrl.text, dscrpTxtCtrl.text, urlTxtCtrl.text);
          Navigator.pop(context);
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.check),
      ),
    );
  }
}

class GroupCard extends StatelessWidget {
  final Group group;

  const GroupCard(this.group, {super.key});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        elevation: 5,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Container(
              height: 200,
            decoration: BoxDecoration(
            image: DecorationImage(
              fit: BoxFit.cover,
              alignment: FractionalOffset.center,
              image: NetworkImage(group.url),
                )
              ),
            ),


      ExpansionTile(
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              title: Text(
                group.name,
                style: TextStyle(fontSize: 22),
              ),
              subtitle: Text(
                'Members: ${group.memberCount}',
                style: TextStyle(
                  color: Colors.black.withOpacity(0.4),
                ),
              ),
              children: [
                Padding(
                  //Description
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                  child: Text(
                    group.description,
                    style: TextStyle(color: Colors.black.withOpacity(0.8)),
                  ),
                ),
                ButtonBar(
                  alignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(group.id,
                        style: TextStyle(
                            color: Colors.black.withOpacity(0.4),
                            fontSize: 11)),
                    OutlinedButton(
                        style: OutlinedButton.styleFrom(
                            //minimumSize: const Size(3,40),
                            ),
                        onPressed: () {
                          // Perform some action
                          Provider.of<GroupsChangeNotifier>(context,
                                  listen: false)
                              .leaveGroup(group.id);
                        },
                        child: const FittedBox(
                          fit: BoxFit.fitHeight,
                          child: Text(
                            "Leave",
                            style: TextStyle(letterSpacing: 1, fontSize: 16),
                          ),
                        )),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
