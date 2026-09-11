import 'package:flutter/material.dart';
import '../../core/study_module.dart';
import 'focus_screen.dart';

class FocusModule extends StudyModule {
  @override
  String get id => 'focus';
  
  @override
  String get title => 'Chế độ Tập trung';
  
  @override
  IconData get icon => Icons.center_focus_strong;

  @override
  Widget buildView(BuildContext context, {Function(int)? onNavigate}) {
    return const FocusScreen();
  }
}