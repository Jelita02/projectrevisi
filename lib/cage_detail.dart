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
                          // Container(
                          //   padding: const EdgeInsets.symmetric(
                          //       horizontal: 12, vertical: 6),
                          //   decoration: BoxDecoration(
                          //     color: Colors.white.withOpacity(0.9),
                          //     borderRadius: BorderRadius.circular(20),
                          //   ),
                            // child: Row(
                            //   children: [
                            //     const Icon(
                            //       Icons.calendar_today_rounded,
                            //       size: 14,
                            //       color: Color(0xFF1D91AA),
                            //     ),
                            //     const SizedBox(width: 6),
                            //     Text(
                            //       doc.data()?["tanggal_dibuat"] ?? "",
                            //       style: const TextStyle(
                            //         color: Color(0xFF1D91AA),
                            //         fontWeight: FontWeight.w600,
                            //         fontSize: 14,
                            //       ),
                            //     ),
                            //   ],
                            // ),
                          // ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            //Date section
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
                    "Tanggal Dibuat:",
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
                              // Container(
                              //   padding: const EdgeInsets.all(8),
                              //   decoration: BoxDecoration(
                              //     color:
                              //         const Color(0xFF1D91AA).withOpacity(0.1),
                              //     borderRadius: BorderRadius.circular(8),
                              //   ),
                              //   // child: const Icon(
                                  // Icons.pets,
                              //   //   size: 20,
                              //   //   color: Color(0xFF1D91AA),
                              //   // ),
                              // ),
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
                              // Container(
                              //   padding: const EdgeInsets.all(8),
                              //   decoration: BoxDecoration(
                              //     color:
                              //         const Color.fromRGBO(189, 148, 26, 0.1),
                              //     borderRadius: BorderRadius.circular(8),
                              //   ),
                              //   child: const Icon(
                              //     Icons.add_circle_outline_rounded,
                              //     size: 20,
                              //     color: Color.fromRGBO(189, 148, 26, 1),
                              //   ),
                              // ),
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
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
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
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // const Text(
                                  //   "Lihat detail blok",
                                  //   style: TextStyle(
                                  //     fontSize: 14,
                                  //     fontWeight: FontWeight.w500,
                                  //   ),
                                  //),
                                  const Text(
                                  "Detail Blok",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1D91AA),
                                  ),
                                ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Terdapat $totalBlok blok ",
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
                                horizontal: 18, vertical: 10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                "Lihat Blok",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 6),
                              Icon(
                                Icons.arrow_forward,
                                size: 16,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1D91AA).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.history_rounded,
                            color: Color(0xFF1D91AA),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
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
                              SizedBox(height: 4),
                              Text(
                                "Daftar perubahan pada kandang",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Divider
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: Colors.grey.withOpacity(0.1),
                  ),
                  
                  // Content
                  FutureBuilder(
                    future: _getListLog(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Container(
                          height: 150,
                          alignment: Alignment.center,
                          child: const CircularProgressIndicator(
                            color: Color(0xFF1D91AA),
                            strokeWidth: 3,
                          ),
                        );
                      }
                      
                      if (snapshot.data == null || snapshot.data!.isEmpty) {
                        return Container(
                          height: 180,
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.history_toggle_off_rounded,
                                  size: 40,
                                  color: Colors.grey[500],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Belum ada riwayat perubahan",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Perubahan pada kandang akan muncul di sini",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      // Reverse the list to show newest edits first
                      var dataList = snapshot.data?.toList() ?? [];
                                            // Sort the list by date, most recent first                      dataList.sort((a, b) {                        // Parse date strings to ensure proper date comparison                        var aDateStr = a.data()["created_at"] ?? '';                        var bDateStr = b.data()["created_at"] ?? '';                                                // Try to parse dates if possible (format: dd/MM/yyyy)                        DateTime? aDate;                        DateTime? bDate;                                                try {                          var aParts = aDateStr.split('/');                          if (aParts.length == 3) {                            aDate = DateTime(                              int.parse(aParts[2]), // year                              int.parse(aParts[1]), // month                              int.parse(aParts[0]), // day                            );                          }                        } catch (e) {                          // Fallback to string comparison if parsing fails                        }                                                try {                          var bParts = bDateStr.split('/');                          if (bParts.length == 3) {                            bDate = DateTime(                              int.parse(bParts[2]), // year                              int.parse(bParts[1]), // month                              int.parse(bParts[0]), // day                            );                          }                        } catch (e) {                          // Fallback to string comparison if parsing fails                        }                                                // Compare dates if both were parsed successfully                        if (aDate != null && bDate != null) {                          return bDate.compareTo(aDate); // Newest first                        }                                                // Fallback to string comparison                        return bDateStr.compareTo(aDateStr); // Reverse order: newest first                      });
                      
                      var data = dataList.map(
                        (el) {
                          var e = el.data();
                          return _buildHistoryItem(
                            iconName: e["icon"] ?? '',
                            title: e["title"] ?? '',
                            description: e["text"] ?? '',
                            date: e["created_at"] ?? '',
                            iconColor: const Color(0xFF1D91AA),
                            showDivider: el != dataList.last,
                          );
                        },
                      ).toList();
                      
                      return Column(
                        children: [
                          Container(
                            height: 300,
                            padding: const EdgeInsets.fromLTRB(20, 5, 20, 0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: RawScrollbar(
                              thumbColor: const Color(0xFF1D91AA).withOpacity(0.2),
                              radius: const Radius.circular(20),
                              thickness: 5,
                              thumbVisibility: true,
                              child: ListView(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                physics: const BouncingScrollPhysics(),
                                children: data ?? [],
                              ),
                            ),
                          ),
                          // Scroll indicator
                          Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.keyboard_arrow_up,
                                  size: 16,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "Scroll untuk melihat lebih banyak",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.keyboard_arrow_down,
                                  size: 16,
                                  color: Colors.grey[400],
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
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
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 20,
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
                            fontSize: 16,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            date,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(),
      ],
    );
  }
}
