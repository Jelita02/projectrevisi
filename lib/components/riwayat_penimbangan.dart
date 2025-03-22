import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RiwayatPenimbangan extends StatelessWidget {
  final DocumentSnapshot<Map<String, dynamic>> doc;
  const RiwayatPenimbangan({
    super.key,
    required this.doc,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color.fromRGBO(0, 0, 0, 0.1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text.rich(
            TextSpan(
              style: const TextStyle(
                fontSize: 17,
              ),
              children: [
                const WidgetSpan(
                  child: Icon(Icons.balance),
                ),
                TextSpan(
                  text: doc.data()?["bobot_akhir"],
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
    );
  }
}
