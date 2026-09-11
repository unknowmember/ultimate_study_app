import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:ui';
import 'firebase_options.dart';
import 'core/services/auth_service.dart';
import 'core/module_registry.dart';
import 'features/auth/login_screen.dart';
import 'features/focus/widgets/yt_music_mini_player.dart';
import 'package:auto_updater/auto_updater.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Kiểm tra cập nhật ngầm khi khởi động app
  try {
    String feedURL = 'https://raw.githubusercontent.com/unknowmember/ultimate_study_app/main/appcast.xml'; //
    await autoUpdater.setFeedURL(feedURL); //[cite: 2]
    await autoUpdater.checkForUpdates(inBackground: true); //[cite: 2]
  } catch (e) {
    print('Auto update silent check error: $e'); //[cite: 2]
  }

  // Bắt mọi lỗi Flutter UI
  FlutterError.onError = (details) {
    FlutterError.dumpErrorToConsole(details); //[cite: 2]
  };

  // Bắt mọi lỗi Bất đồng bộ
  PlatformDispatcher.instance.onError = (error, stack) {
    return true; //[cite: 2]
  };

  // Khởi tạo Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, //[cite: 2]
  );

  // Khởi tạo window_manager
  await windowManager.ensureInitialized(); //[cite: 2]
  WindowOptions windowOptions = const WindowOptions(
    size: Size(1280, 720), //[cite: 2]
    center: true, //[cite: 2]
    title: 'Ultimate Study App', //[cite: 2]
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show(); //[cite: 2]
    await windowManager.focus(); //[cite: 2]
    await windowManager.setPreventClose(true); // Bắt sự kiện tắt app thủ công[cite: 2]
  });

  runApp(const UltimateStudyApp()); //[cite: 2]
}

class UltimateStudyApp extends StatelessWidget {
  const UltimateStudyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ultimate Study App', //[cite: 2]
      debugShowCheckedModeBanner: false, //[cite: 2]
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1E1E2E), //[cite: 2]
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple, //[cite: 2]
          brightness: Brightness.dark, //[cite: 2]
        ),
      ),
      home: StreamBuilder(
        stream: AuthService().authStateChanges, //[cite: 2]
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()), //[cite: 2]
            );
          }
          if (snapshot.hasData) {
            return const MainLayout(); //[cite: 2]
          }
          return const LoginScreen(); //[cite: 2]
        },
      ),
    );
  }
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> with WindowListener {
  int _selectedIndex = 0; //[cite: 2]

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this); //[cite: 2]
  }

  @override
  void dispose() {
    windowManager.removeListener(this); //[cite: 2]
    super.dispose();
  }

  // Giải phóng toàn bộ tài nguyên Native C++ trước khi đóng hẳn app
  @override
  void onWindowClose() async {
    bool isPreventClose = await windowManager.isPreventClose(); //[cite: 2]
    if (isPreventClose) {
      await windowManager.destroy(); //[cite: 2]
    }
  }

  // Hàm kiểm tra cập nhật thủ công do người dùng chủ động bấm nút
  Future<void> _checkUpdateManual() async {
    try {
      String feedURL = 'https://raw.githubusercontent.com/unknowmember/ultimate_study_app/main/appcast.xml'; //[cite: 2]
      await autoUpdater.setFeedURL(feedURL);
      // Gọi checkForUpdates không truyền inBackground để bật cửa sổ thông báo trực tiếp
      await autoUpdater.checkForUpdates();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi kết nối máy chủ cập nhật: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final modules = ModuleRegistry.modules; //[cite: 2]

    return Scaffold(
      body: Stack(
        children: [
          Row(
            children: [
              NavigationRail(
                selectedIndex: _selectedIndex, //[cite: 2]
                onDestinationSelected: (int index) {
                  setState(() => _selectedIndex = index); //[cite: 2]
                },
                labelType: NavigationRailLabelType.selected, //[cite: 2]
                trailing: Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16.0), //[cite: 2]
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Nút Kiểm tra cập nhật thủ công
                          IconButton(
                            icon: const Icon(Icons.system_update_alt, color: Colors.blueAccent),
                            tooltip: 'Kiểm tra cập nhật',
                            onPressed: _checkUpdateManual,
                          ),
                          const SizedBox(height: 8),
                          // Nút Đăng xuất
                          IconButton(
                            icon: const Icon(Icons.logout, color: Colors.redAccent), //[cite: 2]
                            tooltip: 'Đăng xuất', //[cite: 2]
                            onPressed: () async {
                              await AuthService().signOut(); //[cite: 2]
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                destinations: modules.map((m) {
                  return NavigationRailDestination(
                    icon: Icon(m.icon), //[cite: 2]
                    label: Text(m.title), //[cite: 2]
                  );
                }).toList(),
              ),
              const VerticalDivider(thickness: 1, width: 1), //[cite: 2]
              Expanded(
                child: modules.isNotEmpty
                    ? IndexedStack(
                        index: _selectedIndex, //[cite: 2]
                        children: modules.map((m) {
                          return m.buildView(
                            context,
                            onNavigate: (index) {
                              setState(() => _selectedIndex = index); //[cite: 2]
                            },
                          );
                        }).toList(),
                      )
                    : const Center(child: Text('Chưa có module nào')), //[cite: 2]
              ),
            ],
          ),
          const Positioned(
            right: 24, //[cite: 2]
            bottom: 24, //[cite: 2]
            child: YtMusicMiniPlayer(), //[cite: 2]
          ),
        ],
      ),
    );
  }
}