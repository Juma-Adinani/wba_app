import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class User {
  String name;
  String registration;
  String role;
  String programme;
  String yearOfStudy;
  String semester;
  List imeis;

  User({
    @required this.name,
    @required this.registration,
    @required this.role,
    this.programme,
    this.yearOfStudy,
    this.semester,
    this.imeis,
  });

  factory User.fromJson(dynamic json) {
    return User(
      name: json['data']['name'],
      registration: json['data']['reg_no'],
      role: json['data']['role'],
      programme: json['data']['programme'] ?? null,
      yearOfStudy: json['data']['year_of_study'] ?? null,
      semester: json['data']['semester'] ?? null,
    );
  }

  factory User.fromSharedPrefs(SharedPreferences prefs) {
    return User(
      name: prefs.getString('name'),
      registration: prefs.getString('registration'),
      role: prefs.getString('role'),
      programme: prefs.getString('programme') ?? null,
      yearOfStudy: prefs.getString('year_of_study') ?? null,
      semester: prefs.getString('semester') ?? null,
      imeis: prefs.getStringList('imeis'),
    );
  }
}
