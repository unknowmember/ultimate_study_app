import 'package:flutter/material.dart';

abstract class StudyModule {
  String get id;
  String get title;
  IconData get icon;

  Widget buildView(BuildContext context, {Function(int)? onNavigate});
}