import 'package:flutter/material.dart';
class demo extends StatefulWidget {
  const demo({super.key});
  @override
  State<demo> createState() => _demoState();
}

class _demoState extends State<demo> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text("demo")),
      backgroundColor: Colors.green,

    );
  }
}
