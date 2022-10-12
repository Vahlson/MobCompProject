import 'package:flutter/material.dart';
import 'groups.dart';


class MyGroupPage extends StatefulWidget {
  const MyGroupPage({super.key, required this.title});
  final String title;

  @override
  State<MyGroupPage> createState() => _MyGroupPageState();
}

class _MyGroupPageState extends State<MyGroupPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Column(
            children: const <Widget>[
              JoinGroup(),
              GroupCard(),
              GroupCard(),
              GroupCard(),
              GroupCard(),
              GroupCard(),
            ]
        ),
      ),
    );
  }
}
