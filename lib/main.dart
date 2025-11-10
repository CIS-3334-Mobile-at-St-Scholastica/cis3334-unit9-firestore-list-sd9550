import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firestore List',
      theme: ThemeData(colorSchemeSeed: const Color(0xFF2962FF)),
      home: const ItemListApp(),
    );
  }
}

class ItemListApp extends StatefulWidget {
  const ItemListApp({super.key});

  @override
  State<ItemListApp> createState() => _ItemListAppState();
}

class _ItemListAppState extends State<ItemListApp> {
  // Controller for the input field
  final TextEditingController _newItemTextField = TextEditingController();

  // Firestore collection reference
  late final CollectionReference<Map<String, dynamic>> items;

  @override
  void initState() {
    super.initState();
    items = FirebaseFirestore.instance.collection('ITEMS');
  }

  // ACTION: add one item from the TextField to Firestore
  Future<void> _addItem() async {
    final newItem = _newItemTextField.text.trim();
    if (newItem.isEmpty) return;

    try {
      await items.add({
        'item_name': newItem,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _newItemTextField.clear();
    } catch (e) {
      // Handle error (you could show a snackbar or dialog here)
      print('Error adding item: $e');
    }
  }

  // ACTION: remove the item with the given id from Firestore
  void _removeItemAt(String id) {
    items.doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Firestore List Demo')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
        child: Column(
          children: [
            // Item Input
            Row(
              children: [
                // Item Name TextField
                Expanded(
                  child: TextField(
                    controller: _newItemTextField,
                    onSubmitted: (_) => _addItem(),
                    decoration: const InputDecoration(
                      labelText: 'New Item Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                // Spacer for formating
                const SizedBox(width: 12),
                // Add Item Button
                FilledButton(onPressed: _addItem, child: const Text('Add')),
              ],
            ),
            // Spacer for formating
            const SizedBox(height: 24),
            Expanded(
              // Item List with StreamBuilder
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: items.snapshots(),
                builder: (BuildContext context, AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snap) {
                  // Error checking
                  if (snap.hasError) {
                    return Center(
                      child: Text('Error: ${snap.error}'),
                    );
                  }

                  // Loading state
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  // Check if data is null or empty
                  if (snap.data == null || snap.data!.docs.isEmpty) {
                    return const Center(
                      child: Text('No items found. Add some items!'),
                    );
                  }

                  // Item List
                  return ListView.builder(
                    itemCount: snap.data!.docs.length,
                    itemBuilder: (context, i) {
                      final doc = snap.data!.docs[i];
                      final String id = doc.id;
                      final String name = (doc.data()['item_name'] ?? '') as String;

                      return Dismissible(
                        key: ValueKey(id),
                        background: Container(color: Colors.red),
                        onDismissed: (_) => _removeItemAt(id),
                        // Item Tile
                        child: ListTile(
                          leading: const Icon(Icons.check_box),
                          title: Text(name),
                          onTap: () => _removeItemAt(id),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
