import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RiwayatKesehatan extends StatefulWidget {
  final DocumentSnapshot<Map<String, dynamic>> doc;
  final GlobalKey globalKey;
  const RiwayatKesehatan({
    super.key,
    required this.doc,
    required this.globalKey,
  });

  @override
  State<RiwayatKesehatan> createState() => _RiwayatKesehatanState();
}

class _RiwayatKesehatanState extends State<RiwayatKesehatan> {
  Future<void> _captureAndSave(imageUrl) async {
    // Meminta izin penyimpanan
    var status = await Permission.photos.request();
    if (status.isGranted) {
      RenderRepaintBoundary boundary = widget.globalKey.currentContext!
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
          const SnackBar(content: Text('Image saved to gallery')));
    } else {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Permission denied')));
    }
  }

  void _showImage() async {
    String imageUrl = Supabase.instance.client.storage
        .from('terdom')
        .getPublicUrl("kesehatan/${widget.doc.data()?['image']}");

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
                      key: widget.globalKey,
                      child: Container(
                        color: Colors.white,
                        child: Image.network(
                          imageUrl,
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
                _captureAndSave(imageUrl);
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
  Widget build(BuildContext context) {
    List<dynamic> gejala = [];
    if (widget.doc.data() != null) {
      gejala = widget.doc.data()!["gejala"] as List<dynamic>;
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text.rich(
                TextSpan(
                  style: const TextStyle(
                    fontSize: 17,
                  ),
                  children: [
                    TextSpan(
                      text: gejala.join(", "),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.archive),
                onPressed: () {
                  _showImage();
                },
              )
            ],
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
                widget.doc.data()?["tanggal"] ?? "",
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
