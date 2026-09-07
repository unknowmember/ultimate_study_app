import 'study_module.dart';
import '../features/home/home_module.dart';
import '../features/flashcards/flashcard_module.dart';
import '../features/pomodoro/pomodoro_module.dart';
import '../features/kanban/kanban_module.dart';
import '../features/notes/notes_module.dart';
import '../features/quick_tools/quick_tools_module.dart';
import '../features/habits/habit_module.dart';
import '../features/countdown/countdown_module.dart'; // Thêm dòng này

class ModuleRegistry {
  static final List<StudyModule> modules = [
    HomeModule(),
    FlashcardModule(),
    PomodoroModule(),
    KanbanModule(),
    NotesModule(),
    QuickToolsModule(),
    HabitModule(),
    CountdownModule(), // Thêm dòng này
  ];
}