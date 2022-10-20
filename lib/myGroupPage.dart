import 'package:flutter/material.dart';
import 'groups.dart';



class MyGroupPage extends StatefulWidget {
  const MyGroupPage({super.key});


  @override
  State<MyGroupPage> createState() => _MyGroupPageState();
}

class _MyGroupPageState extends State<MyGroupPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My groups"),
      ),
      body: SingleChildScrollView(
        child: Column(
            children: const [
              JoinGroup(),
              //CreateGroup(),
              GroupCard(),
              GroupCard(),
            ]
        ),
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
  }
}
