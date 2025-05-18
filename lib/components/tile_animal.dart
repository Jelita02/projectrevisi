import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
// ignore: library_prefixes
import 'package:firebase_auth/firebase_auth.dart' as userFire;
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
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
        height: 110,
        margin: const EdgeInsets.only(bottom: 16, left: 2, right: 2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        width: double.infinity,
        child: Row(
          children: [
            Container(
              width: 110,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  bottomLeft: Radius.circular(15),
                ),
                color: Colors.grey.shade100,
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
                child: FutureBuilder<Uint8List?>(
                  future: _getImage(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF1D91AA),
                          strokeWidth: 2,
                        ),
                      );
                    }
                    var image = snapshot.data;
                    if (image != null) {
                      return Image.memory(
                        image,
                        fit: BoxFit.cover,
                        height: double.infinity,
                        width: double.infinity,
                      );
                    }
                    return Image.asset(
                      "assets/images/login-logo.jpg",
                      fit: BoxFit.cover,
                      height: double.infinity,
                      width: double.infinity,
                    );
                  },
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      doc.data()?["nama"] ?? "",
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: Color(0xFF333333),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildInfoItem(
                          icon: (doc.data()?["jenis_kelamin"] ?? "") == "Jantan"
                              ? Icons.male
                              : Icons.female,
                          text: doc.data()?["jenis_kelamin"] ?? "",
                          iconColor: (doc.data()?["jenis_kelamin"] ?? "") == "Jantan"
                              ? Colors.blue
                              : Colors.pink,
                        ),
                        const SizedBox(width: 12),
                        _buildInfoItem(
                          icon: Icons.healing,
                          text: doc.data()?["status_kesehatan"] ?? "",
                          iconColor: (doc.data()?["status_kesehatan"] ?? "") == "Sehat"
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildInfoItem(
                          icon: Icons.monitor_weight_outlined,
                          text: "${doc.data()?["bobot"] ?? ""} kg",
                          iconColor: const Color(0xFF1D91AA),
                        ),
                        const SizedBox(width: 12),
                        _buildInfoItem(
                          icon: Icons.cottage_outlined,
                          text: doc.data()?["kandang"] ?? "",
                          iconColor: const Color(0xFF1D91AA),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String text,
    required Color iconColor,
  }) {
    return Expanded(
      child: Row(
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 18,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
