import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_page.dart';
import 'main_screen.dart';

class GHListPage extends StatelessWidget {
  const GHListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Please login first")),
      );
    }

    final DatabaseReference ghRef =
        FirebaseDatabase.instance.ref("users/${user.uid}/greenhouses");

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Greenhouses"),
        centerTitle: true,
        backgroundColor: const Color(0xFF336A29),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF336A29),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showCreateGreenhouseDialog(context, ghRef),
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: ghRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.eco, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    "No greenhouses yet",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () =>
                        _showCreateGreenhouseDialog(context, ghRef),
                    icon: const Icon(Icons.add),
                    label: const Text("Add Greenhouse"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF336A29),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          final data =
              Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);

          final ghList = data.entries.toList();

          return ListView.builder(
            itemCount: ghList.length,
            itemBuilder: (context, index) {
              final ghId = ghList[index].key;
              final ghData = Map<String, dynamic>.from(ghList[index].value);

              final name = ghData["name"]?.toString() ?? "Greenhouse";
              final plant = ghData["plant"]?.toString() ?? "";

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF336A29),
                    child: Icon(Icons.eco, color: Colors.white),
                  ),
                  title: Text(name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: plant.isNotEmpty ? Text(plant) : null,
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MainScreen(ghId: ghId),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showCreateGreenhouseDialog(
      BuildContext context, DatabaseReference ghRef) {
    final nameController = TextEditingController();
    final plantController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add New Greenhouse"),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Greenhouse Name",
                  hintText: "e.g., Greenhouse 1",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter a name";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: plantController,
                decoration: const InputDecoration(
                  labelText: "Plant Type",
                  hintText: "e.g., Tomatoes",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                // Generate a unique ID for the new greenhouse
                final newGhRef = ghRef.push();
                final newGhId = newGhRef.key;

                await newGhRef.set({
                  "name": nameController.text.trim(),
                  "plant": plantController.text.trim(),
                  "createdAt": DateTime.now().toIso8601String(),
                });

                // Also initialize default targets and sensors
                await newGhRef.child("targets").set({
                  "temperature": {"min": 18, "max": 30},
                  "humidity": {"min": 40, "max": 80},
                  "soil": {"min": 30, "max": 70},
                  "light": {"min": 100, "max": 1000},
                });

                await newGhRef.child("sensors").set({
                  "temp": {"value": 0},
                  "humidity": {"value": 0},
                  "soil_moisture": {
                    "sensor1": {"value": 0}
                  },
                  "light": {"value": 0},
                });

                await newGhRef.child("actuators").set({
                  "pump": false,
                  "light": false,
                  "fan": false,
                  "vent": false,
                });

                if (context.mounted) {
                  Navigator.pop(context);
                  // Navigate to the new greenhouse
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MainScreen(ghId: newGhId!),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF336A29),
              foregroundColor: Colors.white,
            ),
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }
}
