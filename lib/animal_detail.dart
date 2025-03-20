import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ternak/animal_edit.dart';
import 'package:ternak/components/riwayat_kesehatan.dart';

class AnimalDetail extends StatefulWidget {
  final User user;
  final DocumentSnapshot<Map<String, dynamic>> doc;
  const AnimalDetail({super.key, required this.doc, required this.user});

  @override
  State<AnimalDetail> createState() => _AnimalDetailState();
}

class _AnimalDetailState extends State<AnimalDetail> {
  final GlobalKey _globalKey = GlobalKey();
  TextEditingController _textController = TextEditingController();
  bool _readOnlyFinalWeight = true;
  IconData _icon = Icons.rebase_edit;

  Future<void> _captureAndSaveQrCode() async {
    // Meminta izin penyimpanan
    var status = await Permission.photos.request();
    if (status.isGranted) {
      RenderRepaintBoundary boundary = _globalKey.currentContext!
          .findRenderObject()! as RenderRepaintBoundary;
      var image = await boundary.toImage(pixelRatio: 5.0);
      ByteData? byteData = await image.toByteData(format: ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final directory = (await getTemporaryDirectory()).path;
      final filePath = '$directory/${widget.doc.id}.jpg';
      final file = File(filePath);
      await file.writeAsBytes(pngBytes);

      // Simpan ke galeri
      await ImageGallerySaver.saveFile(filePath);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR Code saved to gallery')));
    } else {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Permission denied')));
    }
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _getHealthyData() {
    return FirebaseFirestore.instance
        .collection("kesehatan")
        .where("hewan_id", isEqualTo: widget.doc.id)
        .get();
  }

  void _showQrcode() {
    showDialog(
      context: context,
      barrierDismissible:
          false, // Dialog tidak dapat ditutup dengan menyentuh di luar dialog
      builder: (BuildContext context) {
        return AlertDialog(
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox(
                  height: MediaQuery.of(context).size.width * 0.7,
                  width: MediaQuery.of(context).size.height * 0.4,
                  child: Center(
                    child: RepaintBoundary(
                      key: _globalKey,
                      child: Container(
                        color: Colors.white,
                        child: QrImageView(
                          data: widget.doc.id,
                          size: 300,
                          version: QrVersions.auto,
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Download'),
              onPressed: () {
                _captureAndSaveQrCode();
              },
            ),
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();

    _textController =
        TextEditingController(text: widget.doc.data()?["bobot_akhir"] ?? "");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(29, 145, 170, 0.5),
        title: const Text(
          "Detail Hewan",
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: Colors.black87,
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.qr_code,
              size: 24,
            ),
            onPressed: () {
              // Tambahkan logika untuk logout di sini
              _showQrcode();
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Container(
                        decoration: BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.all(5),
                        margin: const EdgeInsets.only(right: 20),
                        child: const Center(
                          child: Text(
                            "DOM 1",
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Expanded(
                      flex: 2,
                      child: Text(
                        "Domba Jenis",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == "edit") {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => AnimalEdit(
                                        doc: widget.doc,
                                        user: widget.user,
                                      )),
                            );
                          } else if (value == "delete") {}
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                              value: "edit", child: Text("Edit")),
                          const PopupMenuItem(
                              value: "delete", child: Text("Hapus")),
                        ],
                        icon:
                            const Icon(Icons.more_vert), // Titik tiga vertikal
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        margin: const EdgeInsets.only(right: 20),
                        child: Center(
                          child: Row(
                            children: [
                              Icon(
                                (widget.doc.data()?["jenis_kelamin"]) ==
                                        "Jantan"
                                    ? Icons.male
                                    : Icons.female,
                              ),
                              Text(
                                widget.doc.data()?["jenis_kelamin"] ?? "",
                                style: const TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          Icon(Icons.healing),
                          Text(
                            "Sehat",
                            style: TextStyle(
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
          dash(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Lokasi Hewan",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        tile(
                          text: "Kandang",
                          icon: Icons.cabin,
                          value: widget.doc.data()?["kandang"] ?? "",
                        ),
                        const SizedBox(width: 70),
                        tile(
                          text: "Blok",
                          icon: Icons.account_tree_outlined,
                          value: widget.doc.data()?["blok"] ?? "",
                        ),
                      ],
                    ),
                  ],
                )
              ],
            ),
          ),
          dash(),
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text(
                  "Informasi Hewan",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                form(text: "Nama", value: widget.doc.data()?["nama"] ?? ""),
                form(text: "Usia", value: widget.doc.data()?["usia"] ?? ""),
                form(
                    text: "Kategori Hewan",
                    value: widget.doc.data()?["kategori"] ?? ""),
                form(
                    text: "Bobot Masuk",
                    value: widget.doc.data()?["bobot"] ?? ""),
                form(
                  iconSuffix: GestureDetector(
                    onTap: () {
                      if (_icon == Icons.save_rounded) {
                        FirebaseFirestore.instance
                            .collection("hewan")
                            .doc(widget.doc.id)
                            .update({"bobot_akhir": _textController.text});
                      }
                      setState(() {
                        _readOnlyFinalWeight = !_readOnlyFinalWeight;
                        _icon = _readOnlyFinalWeight
                            ? Icons.rebase_edit
                            : Icons.save_rounded;
                      });
                    },
                    child: Icon(_icon),
                  ),
                  text: "Bobot Terkini",
                  readOnly: _readOnlyFinalWeight,
                  autoFocus: !_readOnlyFinalWeight,
                ),
                form(
                    text: "Day On Feed",
                    value: widget.doc.data()?["day_on_feed"] ?? ""),
              ],
            ),
          ),
          dash(),
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text(
                  "Riwayat Penimbangan",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                form(text: "Timbangan", value: ""),
              ],
            ),
          ),
          dash(),
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text(
                  "Riwayat Kesehatan",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 20),
                FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  future: _getHealthyData(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (snapshot.data != null) {
                      if (snapshot.data!.docs.isEmpty) {
                        return const Text("Tidak Terdapat Riwayat Kesehatan");
                      }
                      return Column(
                        children: snapshot.data!.docs
                            .map((e) => RiwayatKesehatan(doc: e))
                            .toList(),
                      );
                    }

                    return const Text("Tidak Terdapat Riwayat Kesehatan");
                  },
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  TextFormField form({
    required String text,
    String? value,
    Widget? iconSuffix,
    bool readOnly = true,
    bool autoFocus = false,
  }) {
    return TextFormField(
      autofocus: autoFocus,
      keyboardType: TextInputType.number,
      controller: value == null ? _textController : null,
      decoration: InputDecoration(
        labelText: text,
        suffix: iconSuffix,
      ),
      readOnly: readOnly,
      initialValue: value,
    );
  }

  Container dash() {
    return Container(
      height: 4,
      decoration: const BoxDecoration(
        color: Color.fromRGBO(0, 0, 0, 0.1),
      ),
    );
  }

  Row tile({
    required IconData icon,
    required String text,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 45),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: const TextStyle(fontSize: 10),
            ),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
