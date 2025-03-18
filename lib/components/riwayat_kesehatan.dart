import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RiwayatKesehatan extends StatelessWidget {
  final DocumentSnapshot<Map<String, dynamic>> doc;
  const RiwayatKesehatan({
    super.key,
    required this.doc,
  });

  @override
  Widget build(BuildContext context) {
    List<dynamic> gejala = [];
    if (doc.data() != null) {
      gejala = doc.data()!["gejala"] as List<dynamic>;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color.fromRGBO(0, 0, 0, 0.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            gejala.join(", "),
            style: const TextStyle(
              fontSize: 17,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text.rich(
                TextSpan(
                  style: TextStyle(
                    fontSize: 17,
                  ),
                  children: [
                    WidgetSpan(
                      child: Icon(Icons.healing),
                    ),
                    TextSpan(
                      text: 'Sakit',
                    ),
                  ],
                ),
              ),
              Text(
                doc.data()?["tanggal"] ?? "",
                style: const TextStyle(
                  fontSize: 17,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
