import 'package:flutter/material.dart';

import 'app/melodeia_sleep_app.dart';
import 'features/auth/firebase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final firebaseStatus = await FirebaseBootstrap.initialize();
  runApp(MelodeiaSleepApp(firebaseStatus: firebaseStatus));
}
