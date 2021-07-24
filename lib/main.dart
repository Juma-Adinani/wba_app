import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wba_mu/screens/home_screen.dart';
import 'package:wba_mu/screens/register_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  // This widget is the root of your application.
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Future<Object> registrationFuture;

  @override
  void initState() {
    super.initState();
    registrationFuture = readDetails();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Attendance App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.amber, fontFamily: 'Quicksand'),
      home: FutureBuilder<Object>(
        future: registrationFuture,
        builder: (ctx, snapshot) {
          Widget output = RegisterPage(title: 'Mzumbe Attendance Management');

          if (snapshot.hasData) {
            output = HomePage();
          }

          return output;
        },
      ),
    );
  }

  /// Read user's details from Shared Preferences
  Future<void> readDetails() async {
    var prefs = await SharedPreferences.getInstance();
    var _registration = prefs.getString("registration");
    return _registration;
  }
}
