import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ternak/animal_edit.dart';
import 'package:ternak/components/riwayat_kesehatan.dart';
import 'package:ternak/components/riwayat_penimbangan.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AnimalDetail extends StatefulWidget {
  final auth.User user;
  final DocumentSnapshot<Map<String, dynamic>> doc;
  const AnimalDetail({super.key, required this.doc, required this.user});

  @override
  State<AnimalDetail> createState() => _AnimalDetailState();
}

class _AnimalDetailState extends State<AnimalDetail> {
  late DocumentSnapshot<Map<String, dynamic>> doc;
  final GlobalKey _globalKey = GlobalKey();
  TextEditingController _textController = TextEditingController();
  final TextEditingController _tanggalBobotController = TextEditingController();
  final TextEditingController _textStatusController = TextEditingController();
  final TextEditingController _textStatus_kesehatanController =
      TextEditingController();

  late bool status = true;

  bool _readOnlyFinalWeight = true;
  bool _readOnlyStatus = true;
  bool _readOnlyKondisi = true;
  IconData _icon = Icons.rebase_edit;
  IconData _iconKondisi = Icons.rebase_edit;
  IconData _iconStatus = Icons.rebase_edit;
  final _formKey = GlobalKey<FormState>();

  Future<void> requestStoragePermission({required String type}) async {
    var status = await Permission.storage.status;
    var status2 = await Permission.photos.status;

    if (!status.isGranted || !status2.isGranted) {
      status = await Permission.storage.request();

      if (status.isGranted || status2.isGranted) {
        print("Izin storage diberikan.");
        if (type == "image") {
          _captureAndSave();
        }
        if (type == "qrcode") {
          _captureAndSaveQrCode();
        }
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
    final filePath = '$directory/${widget.doc.id}.jpg';
    final file = File(filePath);
    await file.writeAsBytes(pngBytes);

    // Simpan ke galeri
    await ImageGallerySaver.saveFile(filePath);

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Image saved to gallery')));
  }

  Future<void> _captureAndSaveQrCode() async {
    // Meminta izin penyimpanan
    RenderRepaintBoundary boundary =
        _globalKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    var image = await boundary.toImage(pixelRatio: 5.0);
    ByteData? byteData = await image.toByteData(format: ImageByteFormat.png);
    Uint8List pngBytes = byteData!.buffer.asUint8List();

    final directory = (await getTemporaryDirectory()).path;
    final filePath = '$directory/${doc.id}.jpg';
    final file = File(filePath);
    await file.writeAsBytes(pngBytes);

    // Simpan ke galeri
    await ImageGallerySaver.saveFile(filePath);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('QR Code saved to gallery')));
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _getHealthyData() {
    return FirebaseFirestore.instance
        .collection("kesehatan")
        .where("hewan_id", isEqualTo: doc.id)
        .orderBy("tanggal", descending: true)
        .get();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _getWeightData() {
    return FirebaseFirestore.instance
        .collection("bobot")
        .where("hewan_id", isEqualTo: doc.id)
        .orderBy("tanggal", descending: true)
        .get();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _getEditHistory() {
    return FirebaseFirestore.instance
        .collection("riwayat_edit")
        .where("hewan_id", isEqualTo: doc.id)
        .orderBy("tanggal", descending: true)
        .get();
  }

  void _showQrcode() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "QR Code Hewan",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D91AA),
            ),
          ),
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
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: Colors.grey.withOpacity(0.2)),
                        ),
                        child: QrImageView(
                          data: doc.id,
                          size: 300,
                          version: QrVersions.auto,
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF1D91AA),
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
              child: const Text(
                'Download',
                style: TextStyle(
                  color: Color(0xFF1D91AA),
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                requestStoragePermission(type: "qrcode");
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D91AA),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Tutup'),
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

    doc = widget.doc;
    status = doc.data()?['status'] == "Hidup";

    _textController =
        TextEditingController(text: doc.data()?["bobot_akhir"] ?? "");
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "Konfirmasi Hapus",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D91AA),
            ),
          ),
          content: const Text(
            "Apakah kamu yakin ingin menghapus data hewan ini?",
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                "Batal",
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onPressed: () {
                FirebaseFirestore.instance
                    .collection("hewan")
                    .doc(doc.id)
                    .delete()
                    .then((value) {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Colors.green,
                      content: Text("Berhasil dihapus"),
                    ),
                  );
                }).catchError((value) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Colors.red,
                      content: Text("Gagal menghapus"),
                    ),
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

  void _showImage() async {
    String imageUrl = Supabase.instance.client.storage
        .from('terdom')
        .getPublicUrl("hewan/${widget.doc.id}.jpg");

    print("DEBUG:: $imageUrl");

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "Foto Hewan",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D91AA),
            ),
          ),
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
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: double.infinity,
                              height: 250,
                              color: Colors.grey[200],
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.broken_image,
                                    size: 50,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    "Gambar tidak tersedia",
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: double.infinity,
                              height: 250,
                              color: Colors.grey[100],
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: const Color(0xFF1D91AA),
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
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
              onPressed: () {
                requestStoragePermission(type: "image");
              },
              child: const Text(
                'Download',
                style: TextStyle(
                  color: Color(0xFF1D91AA),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D91AA),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Tutup'),
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
    var dropdownStatus = <String>['Hidup', 'Mati', 'Terjual'];
    var dropdownStatus_kesehatan = <String>['Sehat', 'Sakit'];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D91AA),
        elevation: 0,
        title: const Text(
          "Detail Hewan",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: Colors.white,
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.qr_code,
              size: 24,
              color: Colors.white,
            ),
            onPressed: () {
              _showQrcode();
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          // Header with sheep info
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF1D91AA),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
            child: Column(
              children: [
                Row(
                  children: [
                    // View animal image button
                    GestureDetector(
                      onTap: () => _showImage(),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          FontAwesomeIcons.image,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    // Sheep name
                    Expanded(
                      flex: 2,
                      child: Text(
                        doc.data()?["nama"] ?? "Detail Hewan",
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    // Action menu
                    Align(
                      alignment: Alignment.centerRight,
                      child: PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_vert,
                          color: Colors.white,
                        ),
                        onSelected: (value) {
                          if (value == "edit") {
                            Navigator.push<
                                DocumentSnapshot<Map<String, dynamic>>>(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => AnimalEdit(
                                        doc: doc,
                                        user: widget.user,
                                      )),
                            ).then((value) {
                              setState(() {
                                doc = value!;
                              });
                            });
                          } else if (value == "delete") {
                            _showDeleteConfirmation(context);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            enabled: status ? true : false,
                            value: "edit",
                            child: const Row(
                              children: [
                                Icon(Icons.edit, size: 18),
                                SizedBox(width: 8),
                                Text("Edit"),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: "delete",
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                Text("Hapus",
                                    style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                // Gender and health status
                Row(
                  children: [
                    // Gender indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            (doc.data()?["jenis_kelamin"]) == "Jantan"
                                ? Icons.male
                                : Icons.female,
                            color: (doc.data()?["jenis_kelamin"]) == "Jantan"
                                ? Colors.lightBlue
                                : Colors.pink,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            doc.data()?["jenis_kelamin"] ?? "",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Health status
                    if (doc.data()?["status_kesehatan"] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: doc.data()?["status_kesehatan"] == "Sehat"
                              ? Colors.green.withOpacity(0.3)
                              : Colors.red.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              doc.data()?["status_kesehatan"] == "Sehat"
                                  ? Icons.favorite
                                  : Icons.healing,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              doc.data()?["status_kesehatan"] ?? "",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(width: 10),
                    // Animal status (alive, sold, etc)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _getStatusColor(doc.data()?["status"]),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getStatusIcon(doc.data()?["status"]),
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            doc.data()?["status"] ?? "",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
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
                          value: doc.data()?["kandang"] ?? "",
                        ),
                        const SizedBox(width: 70),
                        tile(
                          text: "Blok",
                          icon: Icons.account_tree_outlined,
                          value: doc.data()?["blok"] ?? "",
                        ),
                      ],
                    ),
                  ],
                )
              ],
            ),
          ),
          dash(),
          // Separator
          Container(
            margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            height: 1,
            color: Colors.grey.withOpacity(0.2),
          ),

          // Animal Information Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Color(0xFF1D91AA),
                      size: 22,
                    ),
                    SizedBox(width: 8),
                    Text(
                      "Informasi Hewan",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: Color(0xFF1D91AA),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                // Date
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Tanggal Masuk: ${doc.data()?["tanggal_masuk"] ?? "-"}",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),

                // Information Cards
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
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
                      // Name
                      _buildInfoRow(
                          icon: FontAwesomeIcons.paw,
                          label: "Nama",
                          value: doc.data()?["nama"] ?? "-"),
                      const Divider(height: 20),

                      // Age
                      _buildInfoRow(
                          icon: Icons.access_time,
                          label: "Usia",
                          value: doc.data()?["usia"] ?? "-"),
                      const Divider(height: 20),

                      // Type
                      _buildInfoRow(
                          icon: Icons.category,
                          label: "Jenis Hewan",
                          value: doc.data()?["jenis"] ?? "-"),
                      const Divider(height: 20),

                      // Category
                      _buildInfoRow(
                          icon: Icons.layers,
                          label: "Kategori Hewan",
                          value: doc.data()?["kategori"] ?? "-"),
                      const Divider(height: 20),

                      // Health Condition Dropdown
                      Row(
                        children: [
                          Container(
                            height: 36,
                            width: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1D91AA).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.healing,
                              color: Color(0xFF1D91AA),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: formDropdown(
                              iconSuffix: GestureDetector(
                                onTap: () {
                                  if (_iconKondisi == Icons.save_rounded) {
                                    FirebaseFirestore.instance
                                        .collection("hewan")
                                        .doc(doc.id)
                                        .update({
                                      "status_kesehatan":
                                          _textStatus_kesehatanController.text
                                    });
                                  }
                                  setState(() {
                                    _readOnlyKondisi = !_readOnlyKondisi;
                                    _iconKondisi = _readOnlyKondisi
                                        ? Icons.rebase_edit
                                        : Icons.save_rounded;
                                  });
                                },
                                child: Icon(_iconKondisi),
                              ),
                              text: "Kondisi Kesehatan",
                              dropdown: dropdownStatus_kesehatan,
                              textController: _textStatus_kesehatanController,
                              readOnly: _readOnlyKondisi,
                              value: doc.data()?["status_kesehatan"] ?? "",
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),

                      // Status Dropdown
                      Row(
                        children: [
                          Container(
                            height: 36,
                            width: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1D91AA).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.insights,
                              color: Color(0xFF1D91AA),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: formDropdown(
                              iconSuffix: GestureDetector(
                                onTap: () async {
                                  if (_iconStatus == Icons.save_rounded) {
                                    await FirebaseFirestore.instance
                                        .collection("hewan")
                                        .doc(doc.id)
                                        .update({
                                      "status": _textStatusController.text
                                    });
                                    doc.data()?["status"] =
                                        _textStatusController.text;
                                    status =
                                        _textStatusController.text == "Hidup";
                                  }
                                  setState(() {
                                    _readOnlyStatus = !_readOnlyStatus;
                                    _iconStatus = _readOnlyStatus
                                        ? Icons.rebase_edit
                                        : Icons.save_rounded;
                                  });
                                },
                                child: Icon(_iconStatus),
                              ),
                              text: "Status",
                              dropdown: dropdownStatus,
                              textController: _textStatusController,
                              readOnly: _readOnlyStatus,
                              value: doc.data()?["status"] ?? "",
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Weight Information
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
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
                        "Informasi Bobot",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Color(0xFF1D91AA),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Initial weight
                      Row(
                        children: [
                          Container(
                            height: 36,
                            width: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1D91AA).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.monitor_weight,
                              color: Color(0xFF1D91AA),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Bobot Awal",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      "${doc.data()?["bobot"] ?? "-"} Kg",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      doc.data()?["tanggal_update"] ?? "",
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Current weight with edit function
                      Form(
                        key: _formKey,
                        child: Row(
                          children: [
                            Container(
                              height: 36,
                              width: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1D91AA).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.scale,
                                color: Color(0xFF1D91AA),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Bobot Terkini",
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        TextFormField(
                                          autofocus: !_readOnlyFinalWeight,
                                          keyboardType: TextInputType.number,
                                          controller: _textController,
                                          decoration: InputDecoration(
                                            hintText: "Masukkan bobot",
                                            suffixText: "Kg",
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 12),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: BorderSide(
                                                  color: Colors.grey[300]!),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: BorderSide(
                                                  color: Colors.grey[300]!),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: const BorderSide(
                                                  color: Color(0xFF1D91AA)),
                                            ),
                                          ),
                                          readOnly: _readOnlyFinalWeight,
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return "Bobot Kosong";
                                            }
                                            return null;
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_readOnlyFinalWeight && status)
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: Color(0xFF1D91AA)),
                                      onPressed: () {
                                        setState(() {
                                          _readOnlyFinalWeight = false;
                                          _icon = Icons.save_rounded;
                                        });
                                      },
                                    )
                                  else if (!_readOnlyFinalWeight)
                                    IconButton(
                                      icon: const Icon(Icons.save_rounded,
                                          color: Color(0xFF1D91AA)),
                                      onPressed: () {
                                        if (_formKey.currentState?.validate() ==
                                            true) {
                                          FirebaseFirestore.instance
                                              .collection("hewan")
                                              .doc(doc.id)
                                              .update({
                                            "bobot_akhir": _textController.text
                                          });
                                          FirebaseFirestore.instance
                                              .collection("bobot")
                                              .add({
                                            "hewan_id": doc.id,
                                            "bobot_akhir": _textController.text,
                                            "tanggal": DateFormat('yyyy-MM-dd')
                                                .format(DateTime.now()),
                                          });
                                          setState(() {
                                            _readOnlyFinalWeight = true;
                                            _icon = Icons.rebase_edit;
                                          });
                                        }
                                      },
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
              ],
            ),
          ),
          dash(),
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1D91AA).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.monitor_weight,
                        color: Color(0xFF1D91AA),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Riwayat Penimbangan",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: Color(0xFF1D91AA),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  future: _getWeightData(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF1D91AA),
                          strokeWidth: 3,
                        ),
                      );
                    }

                    if (snapshot.data != null) {
                      if (snapshot.data!.docs.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.history,
                                size: 40,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Tidak Terdapat Riwayat Penimbangan",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return Column(
                        children: snapshot.data!.docs
                            .map((e) => RiwayatPenimbangan(doc: e))
                            .toList(),
                      );
                    }

                    return Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.history,
                            size: 40,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Tidak Terdapat Riwayat Penimbangan",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          dash(),
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1D91AA).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.health_and_safety,
                        color: Color(0xFF1D91AA),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Riwayat Keterangan",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: Color(0xFF1D91AA),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  future: _getHealthyData(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF1D91AA),
                          strokeWidth: 3,
                        ),
                      );
                    }

                    if (snapshot.data != null) {
                      if (snapshot.data!.docs.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.healing,
                                size: 40,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Tidak Terdapat Riwayat Keterangan",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return Column(
                        children: snapshot.data!.docs
                            .map((e) =>
                                RiwayatKesehatan(doc: e, globalKey: _globalKey))
                            .toList(),
                      );
                    }

                    return Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.healing,
                            size: 40,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Tidak Terdapat Riwayat Keterangan",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  TextFormField form(
      {required String text,
      String? value,
      Widget? iconSuffix,
      bool readOnly = true,
      bool autoFocus = false,
      String? validatorMessage,
      void Function()? onTap,
      TextEditingController? textController}) {
    return TextFormField(
      autofocus: autoFocus,
      keyboardType: TextInputType.number,
      controller:
          value != null ? TextEditingController(text: value) : textController,
      decoration: InputDecoration(
        labelText: text,
        suffixIcon: iconSuffix,
        filled: true,
        fillColor: readOnly ? Colors.grey[50] : Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF1D91AA)),
        ),
      ),
      readOnly: readOnly,
      onTap: onTap,
      validator: (value) {
        if (value == null || value.isEmpty) {
          if (validatorMessage != null) {
            return validatorMessage;
          }
        }

        return null;
      },
    );
  }

  DropdownButtonFormField formDropdown(
      {required String text,
      required List<String> dropdown,
      String? value,
      Widget? iconSuffix,
      bool readOnly = true,
      TextEditingController? textController}) {
    return DropdownButtonFormField(
      decoration: InputDecoration(
        labelText: text,
        suffixIcon: status ? iconSuffix : null,
        isDense: true,
        filled: true,
        fillColor: readOnly ? Colors.grey[50] : Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF1D91AA)),
        ),
      ),
      value: dropdown.contains(value) ? (value) : null,
      dropdownColor: Colors.white,
      icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF1D91AA)),
      items: dropdown.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: readOnly
          ? null
          : (value) {
              setState(() {
                if (value != null) {
                  textController?.text = value;
                }
              });
            },
    );
  }

  Container dash() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 1,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.2),
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

  // Helper method to get status color
  Color _getStatusColor(String? status) {
    switch (status) {
      case "Hidup":
        return Colors.green.withOpacity(0.3);
      case "Mati":
        return Colors.red.withOpacity(0.3);
      case "Terjual":
        return Colors.blue.withOpacity(0.3);
      default:
        return Colors.grey.withOpacity(0.3);
    }
  }

  // Helper method to get status icon
  IconData _getStatusIcon(String? status) {
    switch (status) {
      case "Hidup":
        return Icons.check_circle;
      case "Mati":
        return Icons.cancel;
      case "Terjual":
        return Icons.monetization_on;
      default:
        return Icons.help;
    }
  }

  // Helper method to build information rows
  Widget _buildInfoRow(
      {required IconData icon, required String label, required String value}) {
    return Row(
      children: [
        Container(
          height: 36,
          width: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF1D91AA).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF1D91AA),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
