import 'package:citizen_complaints_list_web/firebase_setup/firbase_config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseServices {
  // Tickets
  static final ticketsFirestore = FirebaseFirestore.instanceFor(
      app: Firebase.app('Tickets'), databaseId: dbName);
}
