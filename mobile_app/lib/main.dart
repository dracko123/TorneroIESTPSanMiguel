import 'package:flutter/material.dart';
import 'config/theme.dart';
import 'services/auth_service.dart';
import 'views/auth/login_screen.dart';
import 'views/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final auth = AuthService();
  await auth.initSession();

  runApp(const TorneoDeportivoApp());
}

class TorneoDeportivoApp extends StatelessWidget {
  const TorneoDeportivoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Torneo Deportivo - Mesa de Control',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkStadiumTheme,
      home: AuthService().isAuthenticated ? const HomeScreen() : const LoginScreen(),
    );
  }
}
