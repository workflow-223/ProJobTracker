import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'database_service.dart';
import 'init_db.dart';

import 'starting_page.dart';
import 'login_page.dart';
import 'create_account_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    prepareDatabase();
    await DatabaseService.getInstance();
    await AuthService().init();
    runApp(const MyApp());
  } catch (e, st) {
    runApp(ErrorApp(e, st));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pro Job Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => StartingPage(),
        '/login': (context) => LoginPage(),
        '/create_account': (context) => CreateAccountPage(),
      },
    );
  }
}

class ErrorApp extends StatelessWidget {
  final Object error;
  final StackTrace? stackTrace;

  const ErrorApp(this.error, this.stackTrace, {super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('Initialization Error')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$error', style: const TextStyle(fontSize: 16, color: Colors.red)),
              if (stackTrace != null) ...[
                const SizedBox(height: 16),
                Text('$stackTrace',
                    style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
