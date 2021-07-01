import 'dart:ffi';

import 'package:flutter/material.dart';

class Session {
  int timetableId;
  String venue;
  String subject;
  List programmes;
  String start;
  String end;
  bool isPresent;
  bool isBelong;

  Session({
    @required this.timetableId,
    @required this.venue,
    @required this.subject,
    @required this.programmes,
    @required this.start,
    @required this.end,
    @required this.isPresent,
    @required this.isBelong,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      timetableId: int.parse(json['data']['timetable_id']),
      venue: json['data']['venue'],
      subject: json['data']['subject'],
      start: json['data']['start'],
      end: json['data']['end'],
      isBelong: json['data']['is_belong'],
      programmes: json['data']['programmes'],
      isPresent: json['data']['is_present'],
    );
  }

  String get programme => this.programmes.map((e) => '$e, ').toString();
}
