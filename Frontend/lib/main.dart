import 'package:flutter/material.dart';
import 'package:senior_project/Registerpg.dart';

void main() {
  runApp( MyApp());
}
class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Senior Project",
      home: Registerpg(),
    );
  }
}