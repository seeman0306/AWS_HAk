import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/user_model.dart';
import 'services/api_service.dart';
import 'widgets/custom_widgets.dart';
import 'screens/login_screen.dart';
import 'screens/citizen_screen.dart';
import 'screens/officer_screen.dart';
import 'screens/admin_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Edge-to-edge system UI styling (No top or bottom gaps)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  final user = await ApiService.getCurrentUser();
  runApp(CivicEyeApp(initialUser: user));
}

class CivicEyeApp extends StatelessWidget {
  final UserModel? initialUser;

  const CivicEyeApp({super.key, this.initialUser});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CivicEye AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: CivicColors.primary,
          primary: CivicColors.primary,
          secondary: CivicColors.accentEmerald,
        ),
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
        ),
      ),
      home: _getInitialScreen(),
    );
  }

  Widget _getInitialScreen() {
    if (initialUser == null) {
      return const LoginScreen();
    }

    switch (initialUser!.role) {
      case 'ROAD_OFFICER':
        return const OfficerScreen(
          deptTitle: 'Road Department',
          departmentCode: 'ROAD',
        );
      case 'STREET_LIGHT_OFFICER':
        return const OfficerScreen(
          deptTitle: 'Street Light Department',
          departmentCode: 'STREET_LIGHT',
        );
      case 'TRAFFIC_OFFICER':
        return const OfficerScreen(
          deptTitle: 'Traffic Department',
          departmentCode: 'TRAFFIC',
        );
      case 'OVERALL_ADMIN':
        return const AdminScreen();
      case 'CITIZEN':
      default:
        return const CitizenScreen();
    }
  }
}
