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
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Image.asset('assets/images/mu_logo.png', height: 100, width: 100),
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
          Align(
            alignment: Alignment.center,
            child: Container(
              margin: EdgeInsets.only(top: 16),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              child: Form(
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
                          border: UnderlineInputBorder(),
                          labelText: 'Registration'),
                    ),
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
                          border: UnderlineInputBorder(),
                          labelText: 'Password'),
                    ),
                    Container(
                        margin: EdgeInsets.only(top: 16),
                        child: ElevatedButton(
                          onPressed: () {
                            if (_registerFormKey.currentState.validate()) {
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
                                            builder: (context) => HomePage()),
                                      )
                                    }
                                },
                              );
                              // .onError(
                              //   (error, stackTrace) =>
                              //       print("Something fishy"),
                              // );
                            }
                          },
                          child: Text('Register'),
                        )),
                  ],
                ),
              ),
            ),
          )
        ],
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
