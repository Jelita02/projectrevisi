import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ternak/block_detail.dart';
import 'package:ternak/cage_edit.dart';
import 'package:firebase_auth/firebase_auth.dart' as fire;

class CageDetail extends StatefulWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final String total;
  final fire.User user;
  const CageDetail(
      {super.key, required this.doc, required this.total, required this.user});

  @override
  State<CageDetail> createState() => _CageDetailState();
}

class _CageDetailState extends State<CageDetail> {
  var canUse = 0;
  var totalBlok = 0;

  late DocumentSnapshot<Map<String, dynamic>> doc;

  void getTotal() {
    FirebaseFirestore.instance
        .collection("blok")
        .where("kandang_id", isEqualTo: doc.id)
        .count()
        .get()
        .then((value) => setState(() {
              totalBlok = value.count ?? 0;
            }));
  }

  @override
  void initState() {
    super.initState();
    doc = widget.doc;

    getTotal();

    var kapasitasInt = int.tryParse(doc.data()?["kapasitas"] ?? "");
    var totalInt = int.tryParse(widget.total);

    if (kapasitasInt != null && totalInt != null) {
      canUse = max(0, kapasitasInt - totalInt);
    }
  }

  Future<Uint8List?> _getImage() async {
    String imageFile = doc.data()?["image"];
    var value = await Supabase.instance.client.storage
        .from('terdom')
        .download("kandang/$imageFile");

    return value;
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Konfirmasi Hapus"),
          content: const Text("Apakah kamu yakin ingin menghapus ini?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Tutup dialog
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () {
                FirebaseFirestore.instance
                    .collection("kandang")
                    .doc(doc.id)
                    .delete()
                    .then((value) {
                  Navigator.of(context).pop(); // Tutup dialog
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Berhasil dihapus")),
                  );
                }).catchError((value) {
                  Navigator.of(context).pop(); // Tutup dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Gagal menghapus")),
                  );
                });
              },
              child: const Text("Hapus"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(29, 145, 170, 0.5),
        title: const Text(
          "Detail Kandang",
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          Align(
            alignment: Alignment.centerRight,
            child: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == "delete") {
                  _showDeleteConfirmation(context);
                }

                if (value == "edit") {
                  Navigator.push<DocumentSnapshot<Map<String, dynamic>>>(
                    context,
                    MaterialPageRoute(
                        builder: (context) => CageEdit(
                              doc: doc,
                              user: widget.user,
                            )),
                  ).then((value) {
                    setState(() {
                      getTotal();
                      doc = value!;
                    });
                  });
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: "edit", child: Text("Edit")),
                const PopupMenuItem(value: "delete", child: Text("Hapus")),
              ],
              icon: const Icon(Icons.more_vert), // Titik tiga vertikal
            ),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 1,
            child: Container(
              width: double.infinity,
              color: const Color.fromRGBO(29, 145, 170, 0.75),
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
                    "assets/images/Kandangr.png",
                    fit: BoxFit.fill,
                  );
                },
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Transform.translate(
              offset: const Offset(0, -70),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(20),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.grey,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Kandang"),
                            Text("Kategori"),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              doc.data()?["nama"] ?? "",
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(doc.data()?["kategori"] ?? ""),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                                // ignore: prefer_interpolation_to_compose_strings
                                "${widget.total + "/" + (doc.data()?["kapasitas"] ?? "")} Ekor"),
                            Text(
                              "Muat ${canUse.toString()} Ekor Lagi",
                              style: const TextStyle(
                                color: Color.fromRGBO(189, 148, 26, 1),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(20),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(217, 217, 217, 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Detail Blok",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(0),
                                horizontalTitleGap: 1,
                                title: const Text(
                                  "Jumlah Blok",
                                  style: TextStyle(fontSize: 14),
                                ),
                                subtitle: Text(
                                  "$totalBlok Blok",
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900),
                                ),
                                leading: Image.asset(
                                  "assets/images/icon-block.png",
                                  fit: BoxFit.fill,
                                  height: 40,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Center(
                                  child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color.fromRGBO(48, 130, 148, 0.45),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => BlockDetail(
                                          kandangId: doc.id,
                                          total: widget.total,
                                          totalBlok: totalBlok.toString(),
                                        ),
                                      )).then((value) => setState(() {}));
                                },
                                child: const Text(
                                  "Lihat Blok",
                                  style: TextStyle(
                                    color: Color.fromRGBO(26, 107, 125, 1),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              )),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
