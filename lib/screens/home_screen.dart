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
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  StreamSubscription connectivitySubscription;

  List<String> deviceImeis;
  User user;
  Session session;
  var message;
  bool _isWifiConnected = false;
  var _wifiName;

  Future<User> readDetailsFuture;
  Future<dynamic> checkVenueFuture;

  @override
  void initState() {
    super.initState();
    readDetailsFuture = readDetails();
    checkVenueFuture = _checkVenue();
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
      body:
          _selectedIndex == 0 ? userDetails(context) : sessionDetails(context),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
              icon: Icon(Icons.verified_user), label: 'Profile'),
          BottomNavigationBarItem(
              icon: Icon(Icons.library_books), label: 'Session'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
    );
  }

  Column sessionDetails(BuildContext context) {
    return Column(
      children: [
        SafeArea(
          child: Container(
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.all(18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SESSION',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber[800],
                    fontSize: 22.0,
                  ),
                ),
                IconButton(
                  padding: const EdgeInsets.all(0.0),
                  icon: Icon(
                    Icons.refresh,
                    color: Colors.amber.shade800,
                  ),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
        Container(
          margin: EdgeInsets.all(18),
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
                    Text(_isWifiConnected ? "Connected" : "Disconnected")
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
          margin: EdgeInsets.all(18),
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
                        fontSize:
                            Theme.of(context).textTheme.headline6.fontSize),
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
              buildSessionDetailsTable(),
            ],
          ),
        ),
      ],
    );
  }

  Column userDetails(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: EdgeInsets.all(18),
          child: Column(
            children: <Widget>[
              SafeArea(
                child: Container(
                  alignment: Alignment.centerLeft,
                  // padding: EdgeInsets.all(18),
                  child: Text(
                    'PROFILE',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber[800],
                      fontSize: 22.0,
                    ),
                  ),
                ),
              ),
              buildUserDetailsTable()
            ],
          ),
        ),
      ],
    );
  }

  FutureBuilder buildSessionDetailsTable() {
    return FutureBuilder(
      future: checkVenueFuture,
      builder: (ctx, snapshot) {
        Widget output = Text("Something went wrong!");

        if (snapshot.hasData) {
          if (snapshot.data['status'].toString().contains("Ok")) {
            session = Session.fromJson(snapshot.data);
            output = Column(
              children: [
                Table(
                  children: [
                    TableRow(children: [
                      Text("Venue: "),
                      Text(session.venue),
                    ]),
                    TableRow(children: [
                      Text("Subject: "),
                      Text(session.subject),
                    ]),
                    TableRow(children: [
                      Text("Programmes: "),
                      Text(session.programme),
                    ]),
                    TableRow(children: [
                      Text("Start: "),
                      Text(session.start),
                    ]),
                    TableRow(children: [
                      Text("End: "),
                      Text(session.end),
                    ]),
                    TableRow(children: [
                      Text("Attendance Status: "),
                      Text(session.isPresent ? 'Present' : 'Absent'),
                    ]),
                  ],
                ),
                SizedBox(height: 40),
                (!session.isPresent)
                    ? Container(
                        margin: EdgeInsets.only(top: 16),
                        child: ElevatedButton(
                          onPressed: () {
                            _confirmAttendance(context);
                          },
                          child: Text('Confirm your attendance'),
                        ),
                      )
                    : Container(),
              ],
            );
          } else if (snapshot.data['status'].toString().contains("Error")) {
            output = Text(snapshot.data['message']);
          } else if (snapshot.hasError) {
            output = Text(snapshot.data['message']);
          } else {
            output = Center(
              child: CircularProgressIndicator(),
            );
          }
        }

        return output;
      },
    );
  }

  FutureBuilder buildUserDetailsTable() {
    return FutureBuilder(
      future: readDetailsFuture,
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 25),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person,
                    size: 50.0,
                    color: Colors.amber[800],
                  ),
                  SizedBox(height: 20),
                  Text(
                    user.registration,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18.0,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    user.name.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22.0,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 30),
              Text(
                'Programme',
                style: TextStyle(color: Colors.grey),
              ),
              SizedBox(height: 5),
              Text(
                user.programme,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20.0,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Year of Study',
                style: TextStyle(color: Colors.grey),
              ),
              SizedBox(height: 5),
              Text(
                user.yearOfStudy,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20.0,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Semester',
                style: TextStyle(color: Colors.grey),
              ),
              SizedBox(height: 5),
              Text(
                user.role.toString().contains('student') ? user.semester : '',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20.0,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Role',
                style: TextStyle(color: Colors.grey),
              ),
              SizedBox(height: 10),
              Text(
                user.role.toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20.0,
                ),
              ),
            ],
          );
        } else {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }

  /// Read user's details from Shared Preferences
  Future<User> readDetails() async {
    var prefs = await SharedPreferences.getInstance();
    user = User.fromSharedPrefs(prefs);
    print("user from prefs: $user");
    return user;
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
            .whenComplete(() => checkVenueFuture = _checkVenue());
      }
    });
  }

  /// Get wifi name
  Future<String> wifiDetails() async {
    return await WifiInfo().getWifiName();
  }

  /// Confirm venue and fetch timetable
  Future<dynamic> _checkVenue() async {
    var response = await http.post(
      Uri.parse(ApiAddress.VENUE_API),
      body: {
        'reg_no': user.registration,
        'venue': _wifiName,
        'imeis': user.imeis.toString(),
      },
    );

    print("Response: ${response.body}");

    if (response.body.isNotEmpty) {
      Map<String, dynamic> result = json.decode(response.body);
      if (result['status'].toString().contains("Ok")) {
        setState(() {
          session = Session.fromJson(result);
        });
        return result;
      }
    }

    return null;
  }

  /// Update user's attendance
  Future<void> _confirmAttendance(BuildContext context) async {
    var response = await http.post(
      Uri.parse(ApiAddress.ATTENDANCE_API),
      body: {
        'reg_no': user.registration,
        'timetable_id': session.timetableId.toString(),
        'imeis': user.imeis.toString(),
      },
    );

    if (response.body.isNotEmpty) {
      Map<String, dynamic> result = json.decode(response.body);
      if (result['status'].toString().contains("Ok")) {
        setState(() {
          session = session;
          session.isPresent = true;
        });
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result['message'])));
    }
  }
}
