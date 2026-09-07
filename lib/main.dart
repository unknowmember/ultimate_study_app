import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/services/auth_service.dart';
import 'core/module_registry.dart';
import 'features/auth/login_screen.dart';
import 'package:auto_updater/auto_updater.dart'; // <--- THÊM DÒNG NÀY

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // ==================== BẮT ĐẦU CODE THÊM MỚI ====================
  // Đường dẫn tới file appcast.xml trên Server/GitHub của bạn
  const String feedUrl = 'https://raw.githubusercontent.com/username/repository/main/appcast.xml';
  
  await autoUpdater.setFeedURL(feedUrl);
  await autoUpdater.setScheduledCheckInterval(3600); // Tự động kiểm tra mỗi 1 giờ
  await autoUpdater.checkForUpdates(); // Kiểm tra ngay khi khởi động
  // ==================== KẾT THÚC CODE THÊM MỚI ====================
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const UltimateStudyApp());
}

class UltimateStudyApp extends StatelessWidget {
  const UltimateStudyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ultimate Study App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1E1E2E),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),
      home: StreamBuilder(
        stream: AuthService().authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          // Đã đăng nhập -> Vào MainLayout chính
          if (snapshot.hasData) {
            return const MainLayout();
          }
          // Chưa đăng nhập -> Hiện màn hình Login
          return const LoginScreen();
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

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final modules = ModuleRegistry.modules;

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() => _selectedIndex = index);
            },
            labelType: NavigationRailLabelType.selected,
            // Nút đăng xuất ở góc dưới thanh Sidebar
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: IconButton(
                    icon: const Icon(Icons.logout, color: Colors.redAccent),
                    tooltip: 'Đăng xuất',
                    onPressed: () async {
                      await AuthService().signOut();
                    },
                  ),
                ),
              ),
            ),
            destinations: modules.map((m) {
              return NavigationRailDestination(
                icon: Icon(m.icon),
                label: Text(m.title),
              );
            }).toList(),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: modules.isNotEmpty
                ? modules[_selectedIndex].buildView(
                    context,
                    onNavigate: (index) {
                      setState(() => _selectedIndex = index);
                    },
                  )
                : const Center(child: Text('Chưa có module nào')),
          ),
        ],
      ),
    );
  }
}