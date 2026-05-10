import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/screens/splash_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/explore/screens/explore_screen.dart';
import 'features/ai_chat/screens/ai_chat_screen.dart';
import 'features/progress/screens/progress_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/roadmap/screens/roadmap_screen.dart';
import 'features/todo/screens/todo_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const AIVAApp());
}

class AIVAApp extends StatelessWidget {
  const AIVAApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AIVA - AI Study Assistant',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
      routes: {
        '/home': (_) => const HomeScreen(),
        '/explore': (_) => const ExploreScreen(),
        '/ai-chat': (_) => const AiChatScreen(),
        '/progress': (_) => const ProgressScreen(),
        '/profile': (_) => const ProfileScreen(),
        '/roadmap': (_) => const RoadmapScreen(),
        '/todo': (_) => const TodoScreen(),
      },
    );
  }
}
