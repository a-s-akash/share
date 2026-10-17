import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_config.dart';

class FirebaseServices {
  // Tickets
  static final ticketsFirestore = FirebaseFirestore.instanceFor(
      app: Firebase.app('Tickets'), databaseId: dbName);
}
