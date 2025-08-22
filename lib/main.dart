import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/birds_provider.dart';
import 'providers/global_colors_provider.dart';
import 'screens/home_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/bird.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(BirdTypeAdapter());
  Hive.registerAdapter(GenderAdapter());
  Hive.registerAdapter(BandColorAdapter());
  Hive.registerAdapter(SourceTypeAdapter());
  Hive.registerAdapter(BirdAdapter());
  await Hive.openBox<Bird>('birds');
  runApp(const ByrdApp());
}

class ByrdApp extends StatelessWidget {
  const ByrdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BirdsProvider()),
        ChangeNotifierProvider(create: (_) => GlobalColorsProvider()),
      ],
      child: Consumer<GlobalColorsProvider>(
        builder: (context, globalColors, child) {
          return MaterialApp(
            title: 'cluckers',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primarySwatch: Colors.green,
              colorScheme: ColorScheme.fromSwatch(
                primarySwatch: Colors.green,
                accentColor: Colors.brown,
                backgroundColor: Colors.brown,
              ),
              scaffoldBackgroundColor: Colors.white,
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}