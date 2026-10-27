import 'package:flutter/material.dart';
import 'screens/home.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
      title: 'Word Contacts',
      theme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true),
      home: const Home());
}
