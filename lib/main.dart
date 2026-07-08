import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'routes/app_router.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  GoogleFonts.config.allowRuntimeFetching = false;

  runApp(const IntellektApp());
}

class IntellektApp extends StatelessWidget {
  const IntellektApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [

        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
        ),

      ],

      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,

        title: "INTELLEKT",

        theme: AppTheme.lightTheme,

        routerConfig: AppRouter.router,
      ),
    );
  }
}