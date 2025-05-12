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
                          data: doc.id,
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
                requestStoragePermission(type: "qrcode");
              },
            ),
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop(); //menarik
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

    _textController =
        TextEditingController(text: doc.data()?["bobot_akhir"] ?? "");
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
                    .collection("hewan")
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

  void _showImage() async {
    String imageUrl = Supabase.instance.client.storage
        .from('terdom')
        .getPublicUrl("hewan/${widget.doc.id}.jpg");

    print("DEBUG:: $imageUrl");

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
                          child: Image.network(
                            imageUrl,
                            errorBuilder: (context, error, stackTrace) {
                              // Gambar gagal dimuat, tampilkan widget pengganti
                              return const Icon(Icons.broken_image,
                                  size: 50, color: Colors.grey);
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const CircularProgressIndicator(); // Bisa diganti dengan placeholder
                            },
                          )),
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
              child: const Text('Download'),
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
    var dropdownStatus = <String>['Hidup', 'Mati', 'Terjual'];
    var dropdownStatus_kesehatan = <String>['Sehat', 'Sakit'];

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
                    Center(
                      child: IconButton(
                        iconSize: 18,
                        icon: const Icon(Icons.archive),
                        onPressed: () {
                          _showImage();
                        },
                      ),
                    ),
                    const Expanded(
                      flex: 2,
                      child: Text(
                        "Lihat Hewan",
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
                            Navigator.push< //menumpuk / menambah
                                DocumentSnapshot<Map<String, dynamic>>>(
                              context,
                              MaterialPageRoute(
                                  //
                                  builder: (context) => AnimalEdit(
                                        //mengarah ke halaman enimal edit
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
                              enabled: doc.data()?["status"] == "Hidup"
                                  ? true
                                  : false,
                              value: "edit",
                              child: const Text("Edit")),
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
                                (doc.data()?["jenis_kelamin"]) == "Jantan"
                                    ? Icons.male
                                    : Icons.female,
                              ),
                              Text(
                                doc.data()?["jenis_kelamin"] ?? "",
                                style: const TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (doc.data()?["status_kesehatan"] != null)
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            const Icon(Icons.healing),
                            Text(
                              doc.data()?["status_kesehatan"] ?? "",
                              style: const TextStyle(
                                fontSize: 16,
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
                Text(doc.data()?["nama"] ?? ""),
                form(text: "Nama", value: doc.data()?["nama"] ?? ""),
                form(text: "Usia", value: doc.data()?["usia"] ?? ""),
                form(text: "Jenis Hewan", value: doc.data()?["jenis"] ?? ""),
                form(
                    text: "Kategori Hewan",
                    value: doc.data()?["kategori"] ?? ""),
                formDropdown(
                    // text: "Kondisi Hewan",
                    // value: doc.data()?["status_kesehatan"] ?? ""),
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
                    text: "Kondisi",
                    dropdown: dropdownStatus_kesehatan,
                    textController: _textStatus_kesehatanController,
                    readOnly: _readOnlyKondisi,
                    value: doc.data()?["status_kesehatan"] ?? ""),
                formDropdown(
                    iconSuffix: GestureDetector(
                      onTap: () {
                        if (_iconStatus == Icons.save_rounded) {
                          FirebaseFirestore.instance
                              .collection("hewan")
                              .doc(doc.id)
                              .update({"status": _textStatusController.text});
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
                    value: doc.data()?["status"] ?? ""),
                form(text: "Bobot Masuk", value: doc.data()?["bobot"] ?? ""),
                Form(
                  key: _formKey,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: form(
                          iconSuffix: _readOnlyFinalWeight &&
                                  doc.data()?['status'] == "Hidup"
                              ? GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _readOnlyFinalWeight =
                                          !_readOnlyFinalWeight;
                                      _icon = _readOnlyFinalWeight
                                          ? Icons.rebase_edit
                                          : Icons.save_rounded;
                                    });
                                  },
                                  child: Icon(_icon),
                                )
                              : null,
                          text: "Bobot Terkini",
                          textController: _textController,
                          validatorMessage: "Bobot Kosong",
                          readOnly: _readOnlyFinalWeight,
                          autoFocus: !_readOnlyFinalWeight,
                        ),
                      ),
                      if (!_readOnlyFinalWeight)
                        Expanded(
                          flex: 2,
                          child: form(
                            iconSuffix: doc.data()?['status'] != "Hidup"
                                ? null
                                : GestureDetector(
                                    onTap: () {
                                      if (_formKey.currentState?.validate() ==
                                          true) {
                                        if (_icon == Icons.save_rounded) {
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
                                            "tanggal":
                                                _tanggalBobotController.text,
                                          }).then((value) =>
                                                  _tanggalBobotController
                                                      .clear());
                                        }
                                        setState(() {
                                          _readOnlyFinalWeight =
                                              !_readOnlyFinalWeight;
                                          _icon = _readOnlyFinalWeight
                                              ? Icons.rebase_edit
                                              : Icons.save_rounded;
                                        });
                                      }
                                    },
                                    child: Icon(_icon),
                                  ),
                            text: "Tanggal",
                            textController: _tanggalBobotController,
                            validatorMessage: "Tanggal Kosong",
                            onTap: () => _selectDate(context),
                            value:
                                DateFormat('yyyy-MM-dd').format(DateTime.now()),
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
                const Text(
                  "Riwayat Penimbangan",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 20),
                FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  future: _getWeightData(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (snapshot.data != null) {
                      if (snapshot.data!.docs.isEmpty) {
                        return const Text("Tidak Terdapat Riwayat Penimbangan");
                      }
                      return Column(
                        children: snapshot.data!.docs
                            .map((e) => RiwayatPenimbangan(doc: e))
                            .toList(),
                      );
                    }

                    return const Text("Tidak Terdapat Riwayat Penimbangan");
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
                            .map((e) =>
                                RiwayatKesehatan(doc: e, globalKey: _globalKey))
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
          suffixIcon: doc.data()?['status'] == "Hidup" ? iconSuffix : null,
          isDense: true),
      value: dropdown.contains(value) ? (value) : null,
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != DateTime.now()) {
      setState(() {
        _tanggalBobotController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
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
