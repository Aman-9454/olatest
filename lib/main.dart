import 'package:flutter/material.dart';
import 'package:olamap/working%20or%20main%20folder/map_screen.dart';
import 'package:olamap/working%20or%20main%20folder/map_tracking.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Origin→Destination Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const MapTrackPage(),
    );
  }
}
