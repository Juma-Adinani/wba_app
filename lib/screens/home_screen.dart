import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:wba_mu/api/address.dart';
import 'package:wba_mu/models/session.dart';
import 'package:wba_mu/models/user.dart';
import 'package:wifi_info_flutter/wifi_info_flutter.dart';
import 'package:connectivity/connectivity.dart';

class HomePage extends StatefulWidget {
  @override
  HomePageState createState() {
    return HomePageState();
  }
}

class HomePageState extends State<HomePage> {
  StreamSubscription connectivitySubscription;

  List<String> deviceImeis;
  User user;
  Session session;
  var message;
  bool _isWifiConnected = false;
  var _wifiName;

  @override
  void initState() {
    super.initState();

    readDetails();

    listenForWifiConnection();
  }

  @override
  void dispose() {
    super.dispose();
    if (connectivitySubscription != null) {
      connectivitySubscription.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(user?.name ?? ''),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Container(
                  margin: EdgeInsets.only(bottom: 8),
                  child: Column(
                    children: <Widget>[
                      Container(
                        margin: EdgeInsets.only(bottom: 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "User Details",
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: Theme.of(context)
                                    .textTheme
                                    .headline6
                                    .fontSize),
                          ),
                        ),
                      ),
                      Table(
                        children: [
                          TableRow(children: [
                            Text("Name: "),
                            Text(user.name ?? '')
                          ]),
                          TableRow(children: [
                            Text("ID: "),
                            Text(user.registration ?? '')
                          ]),
                          TableRow(
                            children: (user.role.toString().contains('student'))
                                ? [
                                    Text("Programme: "),
                                    Text(user.programme ?? '')
                                  ]
                                : [Text(''), Text('')],
                          ),
                          TableRow(
                            children: (user.role.toString().contains('student'))
                                ? [
                                    Text("Year of Study: "),
                                    Text(user.yearOfStudy ?? '')
                                  ]
                                : [Text(''), Text('')],
                          ),
                          TableRow(
                            children: (user.role.toString().contains('student'))
                                ? [
                                    Text("Semester: "),
                                    Text(user.semester ?? '')
                                  ]
                                : [Text(''), Text('')],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(bottom: 8),
                  child: Column(
                    children: <Widget>[
                      Container(
                        margin: EdgeInsets.only(bottom: 8),
                        child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text("Wifi Connection",
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: Theme.of(context)
                                        .textTheme
                                        .headline6
                                        .fontSize))),
                      ),
                      Table(
                        children: [
                          TableRow(children: [
                            Text("Status: "),
                            Text(
                                _isWifiConnected ? "Connected" : "Disconnected")
                          ]),
                          TableRow(children: [
                            Text("Name: "),
                            Text((_wifiName != null) ? _wifiName : '')
                          ]),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(bottom: 8),
                  child: Column(
                    children: <Widget>[
                      Container(
                        margin: EdgeInsets.only(bottom: 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Session Details",
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: Theme.of(context)
                                    .textTheme
                                    .headline6
                                    .fontSize),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: (message != null),
                        child: Align(
                          alignment: Alignment.center,
                          child: Text(
                            message ?? ' ',
                            style: TextStyle(color: Colors.red.shade600),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: (session != null),
                        child: Table(
                          children: [
                            TableRow(children: [
                              Text("Venue: "),
                              Text(session?.venue ?? ''),
                            ]),
                            TableRow(children: [
                              Text("Subject: "),
                              Text(session?.subject ?? ''),
                            ]),
                            TableRow(children: [
                              Text("Programmes: "),
                              Text(session?.programme ?? ''),
                            ]),
                            TableRow(children: [
                              Text("Start: "),
                              Text(session?.start ?? ''),
                            ]),
                            TableRow(children: [
                              Text("End: "),
                              Text(session?.end ?? ''),
                            ]),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                Row(
                  children: [
                    Text(
                      session != null
                          ? session.isBelong
                              ? 'Attendance Status: '
                              : ''
                          : '',
                    ),
                    SizedBox(
                      width: 20,
                    ),
                    Text(
                      session != null
                          ? session.isBelong
                              ? session.isPresent
                                  ? 'Present'
                                  : 'Absent'
                              : ''
                          : '',
                    )
                  ],
                ),
                Visibility(
                  visible: (session != null),
                  child: Container(
                    margin: EdgeInsets.only(top: 16),
                    child: ElevatedButton(
                      onPressed: () {
                        // _confirmAttendance(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Hurraaaay!")));
                      },
                      child: Text('Confirm your attendance'),
                    ),
                  ),
                )
              ],
            ),
          ),
        ));
  }

  /// Read user's details from Shared Preferences
  Future<void> readDetails() async {
    var prefs = await SharedPreferences.getInstance();
    setState(() {
      user = User.fromSharedPrefs(prefs);
      print("user from prefs: $user");
    });
  }

  /// Listen for wifi connectivity
  Future<void> listenForWifiConnection() async {
    connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult connectivityResult) {
      if (connectivityResult == ConnectivityResult.none) {
        setState(() {
          _isWifiConnected = false;
          _wifiName = null;
          message = 'Please connect to WiFi to proceed.';
        });
      } else if (connectivityResult == ConnectivityResult.wifi) {
        setState(
          () {
            _isWifiConnected = true;
          },
        );

        wifiDetails()
            .then(
              (value) => {
                setState(
                  () {
                    _wifiName = value;
                  },
                )
              },
            )
            .whenComplete(
              () => {
                if (_wifiName != null) {_checkVenue()}
              },
            );
      }
    });
  }

  /// Get wifi name
  Future<String> wifiDetails() async {
    return await WifiInfo().getWifiName();
  }

  /// Confirm venue and fetch timetable
  Future<void> _checkVenue() async {
    setState(() {
      message = "Please wait...";
    });

    var response = await http.post(
      Uri.parse(ApiAddress.VENUE_API),
      body: {
        'reg_no': user.registration,
        'venue': _wifiName,
        'imeis': user.imeis,
        // 'timetable_id': session.timetableId
      },
    );

    print("Response: ${response.body}");
    if (response.body.isNotEmpty) {
      Map<String, dynamic> result = json.decode(response.body);

      setState(() {
        message = result['message'];
      });

      if (result['status'].toString().contains("Ok")) {
        setState(() {
          message = null;
          session = Session.fromJson(result);
          print(session.toString());
        });
      }
    } else {
      setState(() {
        message = 'Something went wrong..';
      });
    }
  }

  /// Update user's attendance
  Future<void> _confirmAttendance(BuildContext context) async {
    var response = await http.post(
      Uri.parse(ApiAddress.ATTENDANCE_API),
      body: {
        'reg_no': user.registration,
        'timetable_id': session.timetableId,
        'imeis': user.imeis,
      },
    );

    if (response.body.isNotEmpty) {
      Map<String, dynamic> result = json.decode(response.body);
      if (result['status'].toString().contains("Ok")) {
        setState(() {
          session.isPresent = true;
        });
      } else if (result['status'].toString().contains("Error")) {
        print(result['message']);
      }
    }
  }
}
