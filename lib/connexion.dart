import 'package:firebase_database/firebase_database.dart';

class DatabaseService {
  // Singleton
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  // Référence à la Realtime Database (votre schéma)
  final DatabaseReference db = FirebaseDatabase.instance.ref();

  // Sensors - Données DHT22 par étage
  DatabaseReference get sensorsEtage1 => db.child('Greenhouse/etage1/Sensors');
  DatabaseReference get sensorsEtage2 => db.child('Greenhouse/etage2/Sensors');

  // Actuator - Contrôles relais
  DatabaseReference get actuatorsEtage1 =>
      db.child('Greenhouse/etage1/Actions');
  DatabaseReference get actuatorsEtage2 =>
      db.child('Greenhouse/etage2/Actions');

  // Alertes
  DatabaseReference get alerts => db.child('Alerts');

  // Chatbot
  DatabaseReference get chatHistory => db.child('Farmer/ChatHistory');
  DatabaseReference get chatTriggers => db.child('Triggers');

  // Paramètres seuils (temp max, hum min, etc.)
  DatabaseReference get parameters => db.child('Parameters');
}
