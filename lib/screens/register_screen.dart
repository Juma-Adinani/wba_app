import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:imei_plugin/imei_plugin.dart';
import 'package:wba_mu/api/address.dart';
import 'package:wba_mu/models/user.dart';
import 'package:wba_mu/screens/home_screen.dart';

class RegisterPage extends StatefulWidget {
  RegisterPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  TextEditingController regNumberController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  List<String> deviceImeis;
  var _message;
  User user;

  final _registerFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    getImei();
    readDetails();
  }

  Future<void> getImei() async {
    try {
      deviceImeis = await ImeiPlugin.getImeiMulti(
          shouldShowRequestPermissionRationale: true);
      print("Device IMEI's found: $deviceImeis");
    } on PlatformException {
      print("Failed to acquire device details, please allow ");
    }
  }

  /// Read user's details from Shared Preferences
  Future<void> readDetails() async {
    var prefs = await SharedPreferences.getInstance();
    setState(() {
      user = User.fromSharedPrefs(prefs);
      //prefs.getString("registration");
    });
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        height: double.infinity,
        child: Column(
          children: <Widget>[
            SafeArea(
              child: Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.all(18),
                child: Text(
                  'LOGIN',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber[800],
                    fontSize: 22.0,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: size.height * .1,
            ),
            Align(
              alignment: Alignment.center,
              child: Container(
                margin: EdgeInsets.only(top: 16),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/mu_logo.png',
                      height: 100,
                      width: 100,
                    ),
                    SizedBox(
                      height: size.height * 0.035,
                      child: Align(
                        alignment: Alignment.center,
                        child: Text(
                          (_message == null) ? '' : _message,
                          style: TextStyle(color: Colors.red.shade600),
                        ),
                      ),
                    ),
                    Form(
                      key: _registerFormKey,
                      child: Column(
                        children: <Widget>[
                          TextFormField(
                            validator: (value) {
                              if (value.isEmpty) {
                                return 'Please enter your registration.';
                              }
                              return null;
                            },
                            controller: regNumberController,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderSide: BorderSide(width: .5),
                                gapPadding: 1.0,
                              ),
                              labelText: 'Registration',
                              prefixIcon: Icon(Icons.person),
                            ),
                          ),
                          SizedBox(height: 10),
                          TextFormField(
                            obscureText: true,
                            validator: (value) {
                              if (value.isEmpty) {
                                return 'Please enter your password.';
                              }
                              return null;
                            },
                            controller: passwordController,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderSide: BorderSide(width: .5),
                                gapPadding: 1.0,
                              ),
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.lock),
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.only(top: 16),
                            child: Container(
                              width: double.infinity,
                              child: RaisedButton(
                                padding: EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 16,
                                ),
                                highlightColor: Colors.amber[800],
                                child: Text('REGISTER'),
                                onPressed: () {
                                  if (_registerFormKey.currentState
                                      .validate()) {
                                    _confirmRegNumber().whenComplete(
                                      () => {
                                        if (user?.name != null)
                                          {
                                            setState(() {
                                              _message = null;
                                            }),
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      HomePage()),
                                            )
                                          }
                                      },
                                    );
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  /// After confirming user's registration number, store user's details in shared preferences.
  Future<void> _register() async {
    var prefs = await SharedPreferences.getInstance();
    prefs.setString('name', user.name);
    prefs.setString('registration', user.registration);
    prefs.setString('role', user.role);
    prefs.setStringList('imeis', deviceImeis);
    prefs.setString('programme', user?.programme ?? null);
    prefs.setString('year_of_study', user?.yearOfStudy ?? null);
    prefs.setString('semester', user?.semester ?? null);
  }

  /// Confirm user's registration number if exists in the database
  Future<void> _confirmRegNumber() async {
    if (deviceImeis == null) {
      setState(() {
        _message = "Please allow permissions.";
      });
      getImei();
      return;
    }

    setState(() {
      _message = "Please wait...";
    });

    var response = await http.post(
      Uri.parse(ApiAddress.REGISTRATION_API),
      body: {
        'reg_no': regNumberController.text,
        'password': passwordController.text
      },
    );

    // print("Response got: " + response.body['data']);

    if (response.body.isNotEmpty) {
      Map<String, dynamic> result = json.decode(response.body);

      setState(() {
        _message = result['message'];
      });

      if (result['status'].toString().contains("Ok")) {
        setState(() {
          user = User.fromJson(result);
          _register();
        });
      } else {
        passwordController.clear();
      }
    } else {
      setState(() {
        _message =
            'Something went wrong\nPlease check your internet connection';
      });
    }
  }
}
