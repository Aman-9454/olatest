// // import 'dart:developer';
// import 'package:flutter/material.dart';
// import 'package:ola_maps/ola_maps.dart';

// void main() {
//   Olamaps.instance.initialize('hsTXqp1dSR4JBPsQlw46vE2RSWj1Q7k1CfPtbgx6');
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'Ola Maps Demo',
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//         useMaterial3: true,
//       ),
//       home: const MyHomePage(title: 'Ola Maps Demo'),
//     );
//   }
// }

// class MyHomePage extends StatefulWidget {
//   const MyHomePage({super.key, required this.title});
//   final String title;

//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.title),
//         backgroundColor: Theme.of(context).colorScheme.inversePrimary,
//       ),
//       body: Center(
//         child: Text('Ola Maps will display here'),
//       ),
//     );
//   }
// }



import 'package:flutter/material.dart';
import 'package:ola_maps/ola_maps.dart';
import 'package:olamap/copy%20folder/tracking_screen%20copy.dart';
import 'package:olamap/working%20or%20main%20folder/route_tracking_screen.dart';
// import 'tracking_screen.dart';

void main() {
  // Initialize Ola Maps with your API key
  Olamaps.instance.initialize('hsTXqp1dSR4JBPsQlw46vE2RSWj1Q7k1CfPtbgx6');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ola Maps Tracking',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // home: const TrackingScreen(),
      home:  RouteTrackingScreen(),
    );
  }
}
