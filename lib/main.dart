import 'package:flutter/material.dart';

void main() {
  runApp(const HandShakerApp());
}

class HandShakerApp extends StatelessWidget {
  const HandShakerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HandShaker Open',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5B7EF7)),
      ),
      home: const Scaffold(
        body: Center(child: Text('HandShaker Open')),
      ),
    );
  }
}
