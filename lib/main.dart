import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'utils/app_theme.dart';
import 'utils/app_routes.dart';
import 'providers/providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const WardlyApp());
}

class WardlyApp extends StatelessWidget {
  const WardlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => NoteProvider()),
        ChangeNotifierProvider(create: (_) => PatientProvider()),
        ChangeNotifierProvider(create: (_) => WardProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()..load()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            key: ValueKey(themeProvider.isDark),
            title: 'Wardly',
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeProvider.mode,
            initialRoute: AppRoutes.splash,
            routes: AppRoutes.routes,
            onGenerateRoute: AppRoutes.generateRoute,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
