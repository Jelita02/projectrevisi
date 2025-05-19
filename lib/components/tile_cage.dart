import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ternak/cage_detail.dart';
import 'package:firebase_auth/firebase_auth.dart' as fire;

class TileCage extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final String total;
  final Function refresh;
  final fire.User user;

  const TileCage(
      {super.key,
      required this.doc,
      required this.total,
      required this.refresh,
      required this.user});
  //data yang dibutuhkan

  Future<Uint8List?> _getImage() async {
    String imageFile = doc.data()["image"];
    var value = await Supabase.instance.client.storage
        .from('terdom')
        .download("kandang/$imageFile");

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
                user: user,
                doc: doc,
                total: total,
              ),
            )).then((value) {
          refresh();
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        width: double.infinity,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF2AA3BC),
                    Color(0xFF1D91AA),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: FutureBuilder<Uint8List?>(
                future: _getImage(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
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
                        fit: BoxFit.cover,
                        height: double.infinity,
                        width: double.infinity,
                      ),
                    );
                  }
                  return ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    child: Image.asset(
                      "assets/images/Kandangr.png",
                      fit: BoxFit.cover,
                      height: double.infinity,
                      width: double.infinity,
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 20,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 1,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.category_outlined,
                        size: 18,
                        color: Color(0xFF1D91AA),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "Kategori:",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F4F8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF1D91AA).withOpacity(0.3))
                    ),
                    child: Text(
                      doc.data()["kategori"] ?? "",
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1D91AA),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                vertical: 14,
                horizontal: 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.home_outlined,
                          size: 20,
                          color: Color(0xFF1D91AA),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            doc.data()["nama"] ?? "",
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              overflow: TextOverflow.ellipsis
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D91AA).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        // const Icon(
                        //   Icons.pets_rounded,
                        //   size: 16,
                        //   color: Color(0xFF1D91AA),
                        // ),
                        const SizedBox(width: 4),
                        Text(
                          "$total/${doc.data()["kapasitas"] ?? ""} Ekor",
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Color(0xFF1D91AA),
                          ),
                        ),
                      ],
                    ),
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
