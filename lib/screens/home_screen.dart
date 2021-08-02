import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:wba_mu/api/address.dart';
import 'package:wba_mu/models/session.dart';
import 'package:wba_mu/models/user.dart';
import 'package:wba_mu/screens/register_screen.dart';
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
  dynamic sessionResult;
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
            padding: const EdgeInsets.only(
              top: 18,
              left: 18,
              right: 18,
              bottom: 8,
            ),
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
                Row(
                  children: [
                    GestureDetector(
                      onTap: _checkVenue,
                      child: Icon(
                        Icons.refresh,
                        color: Colors.amber.shade800,
                      ),
                    ),
                    SizedBox(
                      width: 20,
                    ),
                    GestureDetector(
                      onTap: () {
                        clearDetails().then(
                          (value) => {
                            if (value)
                              {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RegisterPage(),
                                  ),
                                  (route) => false,
                                )
                              }
                          },
                        );
                      },
                      child: Icon(
                        Icons.logout,
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          height: 10,
        ),
        Card(
          elevation: 5,
          child: Container(
            margin: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  "Wifi Connection",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 20.0,
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text("Status: "),
                    Text(
                      _isWifiConnected ? "Connected" : "Disconnected",
                      style: TextStyle(
                        color: _isWifiConnected
                            ? Colors.green[900]
                            : Colors.red[900],
                        fontWeight: FontWeight.bold,
                        fontSize: 18.0,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 5,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text("Name: "),
                    Text(
                      (_wifiName != null) ? _wifiName : '-',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Card(
          elevation: 5,
          child: Container(
            width: double.infinity,
            margin: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  "Session Details",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 20.0,
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                Visibility(
                  visible: (message != null),
                  child: Align(
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Text(
                          message ?? ' ',
                          style: TextStyle(color: Colors.red.shade600),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                      ],
                    ),
                  ),
                ),
                buildSessionDetailsTable(),
              ],
            ),
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'PROFILE',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber[800],
                          fontSize: 22.0,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          clearDetails().then(
                            (value) => {
                              if (value)
                                {
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => RegisterPage(),
                                    ),
                                    (route) => false,
                                  )
                                }
                            },
                          );
                        },
                        child: Icon(
                          Icons.logout,
                          color: Colors.amber.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              buildUserDetailsTable(),
              SizedBox(
                height: 20,
              ),
              Visibility(
                visible: (session != null &&
                    (!session.isPresent && session.isBelong)),
                child: Center(
                  child: Container(
                    margin: EdgeInsets.only(top: 16),
                    child: ElevatedButton(
                      onPressed: () {
                        _confirmAttendance(context);
                      },
                      child: Text('Confirm your attendance'),
                    ),
                  ),
                ),
              ),
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

        switch (snapshot.connectionState) {
          case ConnectionState.active:
          case ConnectionState.none:
          case ConnectionState.waiting:
            output = Center(
              child: CircularProgressIndicator(),
            );
            break;
          case ConnectionState.done:
            if (session != null) {
              output = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text("Venue: "),
                      Text(session.venue),
                    ],
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text("Subject: "),
                      Text(session.subject),
                    ],
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text("Programmes: "),
                      Text(session.programme),
                    ],
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text("Start: "),
                      Text(session.start),
                    ],
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text("End: "),
                      Text(session.end),
                    ],
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text("Attendance Status: "),
                      Text(
                        session.isPresent ? 'PRESENT' : 'ABSENT',
                        style: TextStyle(
                          color: session.isPresent
                              ? Colors.green[900]
                              : Colors.red[900],
                          fontWeight: FontWeight.bold,
                          fontSize: 18.0,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            } else if (sessionResult != null) {
              output = Text('${sessionResult['message']}');
            }
            break;
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
    print("user from prefs: ${user.registration}");
    return user;
  }

  /// Delete user's details from Shared Prefs during Logout
  Future<bool> clearDetails() async {
    var prefs = await SharedPreferences.getInstance();
    return prefs.clear();
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
    setState(() {
      session = null;
      sessionResult = null;
    });

    if (!_isWifiConnected) {
      return;
    }

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
      } else {
        setState(() {
          session = null;
          sessionResult = json.decode(response.body);
        });
      }
      return result;
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
