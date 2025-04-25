import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
// ignore: library_prefixes
import 'package:firebase_auth/firebase_auth.dart' as userFire;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ternak/animal_detail.dart';

class TileAnimal extends StatelessWidget {
  final userFire.User user;
  final DocumentSnapshot<Map<String, dynamic>> doc;
  final Function refresh;
  final bool isForHealthy;
  const TileAnimal({
    super.key,
    required this.user,
    required this.doc,
    required this.refresh,
    this.isForHealthy = false,
  });

  Future<Uint8List?> _getImage() async {
    var value = await Supabase.instance.client.storage
        .from('terdom')
        .download("hewan/${doc.id}.jpg");
    return value;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        isForHealthy
            ? Navigator.pop(context, doc)
            : Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AnimalDetail(doc: doc, user: user),
                )).then((value) => refresh());
      },
      child: Container(
        height: 90,
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            bottomRight: Radius.circular(15),
            topRight: Radius.circular(15),
          ),
          border: Border.all(color: Colors.black),
        ),
        width: double.infinity,
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: FutureBuilder<Uint8List?>(
                future: _getImage(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  var image = snapshot.data;
                  if (image != null) {
                    return Image.memory(
                      image,
                      fit: BoxFit.fill,
                    );
                  }
                  return Image.asset(
                    "assets/images/login-logo.jpg",
                    height: 93,
                    width: 97,
                    fit: BoxFit.cover,
                  );
                },
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.data()?["nama"] ?? "",
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: Row(
                              children: [
                                (doc.data()?["jenis_kelamin"] ?? "") == "Jantan"
                                    ? const Icon(
                                        Icons.male,
                                        // size: 28,
                                      )
                                    : const Icon(
                                        Icons.female,
                                        // size: 28,
                                      ),
                                Text(doc.data()?["jenis_kelamin"] ?? ""),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Row(
                              children: [
                                const Icon(Icons.healing),
                                Text(doc.data()?["status_kesehatan"] ?? ""),
                              ],
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: Row(
                              children: [
                                const Icon(Icons.monitor_weight_outlined),
                                Text((doc.data()?["bobot"] ?? "") + " kg"),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Row(
                              children: [
                                const Icon(Icons.cottage_outlined),
                                Expanded(
                                  child: Text(
                                    doc.data()?["kandang"] ?? "",
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
