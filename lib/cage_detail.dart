import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
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

  final GlobalKey _globalKey = GlobalKey();

  late DocumentSnapshot<Map<String, dynamic>> doc;

  void getTotal() {
    FirebaseFirestore.instance
        .collection("blok")
        .where("kandang_id", isEqualTo: doc.id)
        .count()
        .get()
        .then((value) => setState(() {
              var kapasitasInt = int.tryParse(doc.data()?["kapasitas"] ?? "");
              var totalInt = int.tryParse(widget.total);

              if (kapasitasInt != null && totalInt != null) {
                canUse = max(0, kapasitasInt - totalInt);
              }
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline, color: Colors.red),
              ),
              const SizedBox(width: 16),
              const Text("Konfirmasi Hapus"),
            ],
          ),
          content: const Text(
              "Apakah kamu yakin ingin menghapus kandang ini? Tindakan ini tidak dapat dibatalkan."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[700],
              ),
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
                  Navigator.of(context).pop(); // penumpuk
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Berhasil dihapus"),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }).catchError((value) {
                  Navigator.of(context).pop(); // Tutup dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Gagal menghapus"),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text("Hapus"),
            ),
          ],
        );
      },
    );
  }

  Future<void> requestStoragePermission(imageUrl) async {
    var status = await Permission.storage.status;
    var status2 = await Permission.photos.status;

    if (!status.isGranted || !status2.isGranted) {
      status = await Permission.storage.request();

      if (status.isGranted || status2.isGranted) {
        print("Izin storage diberikan.");
        _captureAndSave();
      } else if (status.isDenied || status2.isDenied) {
        print("Izin storage ditolak.");
        if (!mounted) return;

        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Permission denied')));
      } else if (status.isPermanentlyDenied || status2.isPermanentlyDenied) {
        print(
            "Izin storage ditolak permanen, buka pengaturan untuk mengaktifkan.");
        openAppSettings();
      }
    }
  }

  Future<void> _captureAndSave() async {
    // Meminta izin penyimpanan
    RenderRepaintBoundary boundary =
        _globalKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    var image = await boundary.toImage(pixelRatio: 5.0);
    ByteData? byteData = await image.toByteData(format: ImageByteFormat.png);
    Uint8List pngBytes = byteData!.buffer.asUint8List();

    final directory = (await getTemporaryDirectory()).path;
    final filePath = '$directory/${widget.doc.data()['image']}';
    final file = File(filePath);
    await file.writeAsBytes(pngBytes);

    // Simpan ke galeri
    await ImageGallerySaver.saveFile(filePath);

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Image saved to gallery')));
  }

  void _showImage() async {
    String imageUrl = Supabase.instance.client.storage
        .from('terdom')
        .getPublicUrl("kandang/${doc.data()?['image']}");

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.all(16),
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
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            imageUrl,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.broken_image,
                                        size: 50, color: Colors.grey),
                                    SizedBox(height: 10),
                                    Text("Gagal memuat gambar",
                                        style: TextStyle(color: Colors.grey))
                                  ],
                                ),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  color: const Color(0xFF1D91AA),
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
          actions: <Widget>[
            TextButton.icon(
              icon: const Icon(Icons.download, size: 18),
              label: const Text('Download'),
              onPressed: () {
                requestStoragePermission(imageUrl);
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1D91AA),
              ),
            ),
            TextButton.icon(
              icon: const Icon(Icons.close, size: 18),
              label: const Text('Tutup'),
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[700],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      _getListLog() async {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection("kandang_log")
        .where("kandang_id", isEqualTo: widget.doc.id);

    final snapshot = await query.get();
    return snapshot.docs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1D91AA)),
            onPressed: () {
              Navigator.pop(context, 'refresh');
            },
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.image, color: Color(0xFF1D91AA)),
              onPressed: () {
                _showImage();
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Color(0xFF1D91AA)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              offset: const Offset(0, 40),
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
                      ),
                    ),
                  ).then((value) {
                    setState(() {
                      doc = value!;
                      getTotal();
                    });
                  });
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: "edit",
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Color(0xFF1D91AA), size: 20),
                      SizedBox(width: 12),
                      Text("Edit",
                          style: TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: "delete",
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.redAccent, size: 20),
                      SizedBox(width: 12),
                      Text("Hapus",
                          style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.redAccent)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Header image with overlay
            Stack(
              children: [
                SizedBox(
                  height: 280,
                  width: double.infinity,
                  child: FutureBuilder<Uint8List?>(
                    future: _getImage(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
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
                        "assets/images/Kandangr.png",
                        fit: BoxFit.cover,
                        height: double.infinity,
                        width: double.infinity,
                      );
                    },
                  ),
                ),
                // Gradient overlay for better text contrast
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                        stops: const [0.5, 1.0],
                      ),
                    ),
                  ),
                ),
                // Title overlay at bottom of image
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc.data()?["nama"] ?? "",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 1),
                              blurRadius: 3.0,
                              color: Color.fromARGB(150, 0, 0, 0),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1D91AA),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              doc.data()?["kategori"] ?? "",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_rounded,
                                  size: 14,
                                  color: Color(0xFF1D91AA),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  doc.data()?["tanggal_dibuat"] ?? "",
                                  style: const TextStyle(
                                    color: Color(0xFF1D91AA),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Date section
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF1D91AA).withOpacity(0.05),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.withOpacity(0.15),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.today_rounded,
                    size: 18,
                    color: Color(0xFF1D91AA),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Tanggal Masuk:",
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    doc.data()?["tanggal_dibuat"] ?? "-",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Capacity info cards
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  // Left card
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            spreadRadius: 0,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Jumlah Ternak",
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF1D91AA).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.pets,
                                  size: 20,
                                  color: Color(0xFF1D91AA),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "${widget.total}/${doc.data()?["kapasitas"] ?? ""} Ekor",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Color(0xFF1D91AA),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Right card
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            spreadRadius: 0,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Kapasitas Tersisa",
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color:
                                      const Color.fromRGBO(189, 148, 26, 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.add_circle_outline_rounded,
                                  size: 20,
                                  color: Color.fromRGBO(189, 148, 26, 1),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "${canUse.toString()} Ekor",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Color.fromRGBO(189, 148, 26, 1),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Block details card
            Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D91AA).withOpacity(0.05),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1D91AA).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.dashboard_rounded,
                                color: Color(0xFF1D91AA),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Detail Blok",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1D91AA),
                                  ),
                                ),
                                Text(
                                  "Informasi blok dalam kandang",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1D91AA).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF1D91AA).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            "$totalBlok Blok",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF1D91AA),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  "assets/images/icon-block.png",
                                  width: 30,
                                  height: 30,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.dashboard_rounded,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Lihat detail blok",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Terdapat $totalBlok blok pada kandang ini",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BlockDetail(
                                  kandangId: doc.id,
                                  total: widget.total,
                                  totalBlok: totalBlok.toString(),
                                ),
                              ),
                            ).then((value) => setState(() {
                                  doc = value!;
                                  getTotal();
                                }));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1D91AA),
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shadowColor:
                                const Color(0xFF1D91AA).withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                          child: const Text(
                            "Lihat Blok",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Edit history card
            Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D91AA).withOpacity(0.05),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1D91AA).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.history_rounded,
                            color: Color(0xFF1D91AA),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Riwayat Edit",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1D91AA),
                              ),
                            ),
                            Text(
                              "Daftar perubahan pada kandang",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                      padding: const EdgeInsets.all(20),
                      child: FutureBuilder(
                        future: _getListLog(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator(
                              color: Color(0xFF1D91AA),
                            ));
                          }
                          var data = snapshot.data?.map(
                            (el) {
                              var e = el.data();
                              return _buildHistoryItem(
                                iconName: e["icon"] ?? '',
                                title: e["title"] ?? '',
                                description: e["text"] ?? '',
                                date: e["created_at"] ?? '',
                                iconColor: const Color(0xFF1D91AA),
                                showDivider: true,
                              );
                            },
                          ).toList();
                          return ListView(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            children: data ?? [],
                          );
                        },
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem({
    required String iconName,
    required String title,
    required String description,
    required String date,
    required Color iconColor,
    bool showDivider = true,
  }) {
    var icon = Icons.pets_rounded;
    switch (iconName) {
      case 'edit_rounded':
        icon = Icons.edit_rounded;
      case 'category_rounded':
        icon = Icons.edit_rounded;
    }
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 18,
                color: iconColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        date,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (showDivider)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(),
          ),
      ],
    );
  }
}
