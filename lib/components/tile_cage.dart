import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:ternak/cage_detail.dart';

class TileCage extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final String total;

  const TileCage({super.key, required this.doc, required this.total});

  Future<Uint8List?> _getImage() async {
    final storageRef = FirebaseStorage.instance.ref();
    var value =
        await storageRef.child("kandang/${doc.id}").getData(1024 * 1024);

    return value;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CageDetail(
                doc: doc,
                total: total,
              ),
            ));
      },
      child: Container(
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black),
        ),
        width: double.infinity,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 100,
              decoration: const BoxDecoration(
                color: Color.fromRGBO(29, 145, 170, 0.75),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
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
                    return ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      child: Image.memory(
                        image,
                        fit: BoxFit.fill,
                      ),
                    );
                  }
                  return Image.asset(
                    "assets/images/icon-cage.png",
                    fit: BoxFit.fill,
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                vertical: 10,
                horizontal: 20,
              ),
              decoration: const BoxDecoration(
                color: Color.fromRGBO(217, 217, 217, 0.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Kategori"),
                  Text(doc.data()["kategori"] ?? ""),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                vertical: 10,
                horizontal: 20,
              ),
              decoration: const BoxDecoration(
                color: Color.fromRGBO(217, 217, 217, 1),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    doc.data()["nama"] ?? "",
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Text(
                    // ignore: prefer_interpolation_to_compose_strings
                    total + "/" + (doc.data()["kapasitas"] ?? "") + " Ekor",
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
