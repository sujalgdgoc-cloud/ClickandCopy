import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:websocket_example/entrypage.dart';

import 'homepage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDqxu1_Oq_7qIQJgLHMPXnQR1sodBMqxtM",
      appId: "1:279876606036:web:9819eff87d80bef7bab5c1",
      messagingSenderId: "279876606036",
      projectId: "auth-dc7dc",
      databaseURL: "https://auth-dc7dc-default-rtdb.firebaseio.com/"
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Flutter Demo', home: EntryPage());
  }
}
