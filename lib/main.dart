import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/provider.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screens.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'Vibrant To-Do',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF0F4FD), // Cool white-blue bg
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6200EA), // Deep Purple
          primary: const Color(0xFF6200EA),
          secondary: const Color(0xFF00BFA5), // Teal Accent
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF1D1D35),
          ),
          titleMedium: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF2B2B48),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
      ),
      home: authState.when(
        data: (user) => user != null ? const HomeScreen() : AuthScreen(),
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, s) => Scaffold(body: Center(child: Text('Error: $e'))),
      ),
    );
  }
}
