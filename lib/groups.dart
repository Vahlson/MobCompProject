import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class JoinGroup extends StatefulWidget {
  const JoinGroup({super.key});
  @override
  State<JoinGroup> createState() => _JoinGroupState();
}

TextEditingController textController = TextEditingController();
String groupID = "";

class _JoinGroupState extends State<JoinGroup> {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      margin: const EdgeInsets.fromLTRB(32, 32, 32, 16),
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
                    FilteringTextInputFormatter.allow(RegExp("[0-9a-zA-Z]")),
                  ],
                  style: const TextStyle(fontSize: 16),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Group code',
                    hintText: 'Enter your group code',
                  ),
                  controller: textController,
                ),
              ),
            ),
            ElevatedButton(
                onPressed: () {
                  setState(() {
                    //Todo: Add join group action
                    groupID = textController.text;
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

class GroupCard extends StatelessWidget {
  const GroupCard({super.key});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        elevation: 5,
        margin: const EdgeInsets.fromLTRB(32, 16, 32, 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Image.network(
                'https://thumbs.gfycat.com/NiftyFlusteredAstarte-size_restricted.gif'),
            ExpansionTile(
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              title: const Text(
                'Group Name',
                style: TextStyle(fontSize: 22),
              ),
              subtitle: Text(
                'Member: 56',
                style: TextStyle(
                  color: Colors.black.withOpacity(0.4),
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                  child: Text(
                    'Greyhound divisively hello coldly wonderfully marginally far upon excluding.Greyhound divisively hello coldly wonderfully marginally far upon excluding.Greyhound divisively hello coldly wonderfully marginally far upon excluding.',
                    style: TextStyle(color: Colors.black.withOpacity(0.8)),
                  ),
                ),
                ButtonBar(
                  alignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Group Code: ABCDEFGHIJKLMNOPQRST',
                        style: TextStyle(
                            color: Colors.black.withOpacity(0.4),
                            fontSize: 11)),
                    OutlinedButton(
                        style: OutlinedButton.styleFrom(
                            //minimumSize: const Size(3,40),
                            ),
                        onPressed: () {
                          // Perform some action
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
