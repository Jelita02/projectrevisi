import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fire;
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CageEdit extends StatefulWidget {
  final fire.User user;
  final DocumentSnapshot<Map<String, dynamic>> doc;
  const CageEdit({super.key, required this.user, required this.doc});

  @override
  State<CageEdit> createState() => _CageEditState();
}

class _CageEditState extends State<CageEdit> {
  final _formKey = GlobalKey<FormState>();

  File? _image;

  late String _kategori;
  TextEditingController _namaController = TextEditingController();
  TextEditingController _kapasitasController = TextEditingController();
  TextEditingController _tanggalController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(DateTime.now()));

  List<Map<String, dynamic>> blok = [];

  final picker = ImagePicker();
  String urlgambar = "";

  Future _getImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      }
    });
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
        _tanggalController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  var kandang = FirebaseFirestore.instance.collection('kandang');
  var blokStore = FirebaseFirestore.instance.collection('blok');

  void _log({
    dynamic before,
    dynamic after,
    required String textInitial,
    required String icon,
    String textPrefix = "",
    String textSufix = "",
  }) {
    if (before != after) {
      var text =
          "$textInitial berubah dari $textPrefix $before $textSufix menjadi $textPrefix $after $textSufix";
      FirebaseFirestore.instance.collection('kandang_log').add({
        "kandang_id": widget.doc.id,
        "text": text,
        "created_at": DateTime.now().toString().substring(0, 10),
        "title": "Perubahan $textInitial",
        "icon": icon,
      });
    }
  }

  void _editCage(context) {
    kandang.doc(widget.doc.id).update({
      "nama": _namaController.text,
      "nama_lower": _namaController.text.toLowerCase(),
      "kapasitas": _kapasitasController.text,
      "kategori": _kategori,
      "tanggal_update": _tanggalController.text,
    }).then((value) async {
      _log(
          before: widget.doc.data()?["nama"],
          after: _namaController.text,
          textInitial: "Nama",
          textPrefix: "Kandang",
          icon: 'pets_rounded');
      _log(
          before: widget.doc.data()?["kategori"],
          after: _kategori,
          textInitial: "Kategori",
          icon: 'category_rounded');
      if (_image != null) {
        // Ambil ekstensi file asli
        String extension = path.extension(_image!.path);

        // Buat nama file unik dengan UUID
        String fileName = '${widget.doc.id}$extension';
        await Supabase.instance.client.storage
            .from('terdom') // Ganti dengan nama bucket
            .remove(['kandang/$fileName']);
        await Supabase.instance.client.storage
            .from('terdom') // Ganti dengan nama bucket
            .upload('kandang/$fileName', _image!);
        kandang.doc(widget.doc.id).update({
          "image": fileName,
        });
      }

      int kapasitasKandang = 0;
      Map<String, String> listId = {};
      for (var v in blok) {
        kapasitasKandang += int.tryParse(v["kapasitas"] ?? 0) ?? 0;
        if (v['id'].toString() != 'null') {
          await blokStore.doc(v['id'].toString()).update({
            "user_uid": widget.user.uid,
            "kandang_id": widget.doc.id,
            "nama": v["nama"] ?? "",
            "kapasitas": v["kapasitas"] ?? "",
          });

          listId[v['id'].toString()] = v['id'].toString();
        } else {
          var doc = await blokStore.add({
            "user_uid": widget.user.uid,
            "kandang_id": widget.doc.id,
            "nama": v["nama"] ?? "",
            "kapasitas": v["kapasitas"] ?? "",
          });

          listId[doc.id] = doc.id;
        }
      }

      WriteBatch batch = FirebaseFirestore.instance.batch();
      var querySnapshot =
          await blokStore.where('kandang_id', isEqualTo: widget.doc.id).get();
      for (var doc in querySnapshot.docs) {
        if (!listId.containsValue(doc.id)) {
          batch.delete(doc.reference);
        }
      }
      batch.commit();

      kandang
          .doc(widget.doc.id)
          .update({"kapasitas": kapasitasKandang.toString()});
      _log(
        icon: 'edit_rounded',
        before: int.tryParse(widget.doc.data()?["kapasitas"] ?? 0) ?? 0,
        after: kapasitasKandang,
        textInitial: "Kapasitas",
        textSufix: "Ekor",
      );

      var value = await kandang.doc(widget.doc.id).get();
      Navigator.pop(
        context,
        value,
      );
    });
  }

  void _showPicker(context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext bc) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1D91AA).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.photo_library,
                          color: Color(0xFF1D91AA)),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Pilih Sumber Gambar",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.photo_library, color: Colors.blue),
                  ),
                  title: const Text('Galeri'),
                  subtitle: const Text('Pilih dari galeri foto'),
                  onTap: () {
                    _getImage(ImageSource.gallery);
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.photo_camera, color: Colors.green),
                  ),
                  title: const Text('Kamera'),
                  subtitle: const Text('Ambil gambar dengan kamera'),
                  onTap: () {
                    _getImage(ImageSource.camera);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddBlok(context) {
    final blokKey = GlobalKey<FormState>();
    final TextEditingController namaBlokController = TextEditingController();
    final TextEditingController kapasitasBlokController =
        TextEditingController();

    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext bc) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: blokKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1D91AA).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.dashboard_customize,
                                color: Color(0xFF1D91AA)),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            "Tambah Blok Kandang",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: namaBlokController,
                              maxLength: 20,
                              decoration: InputDecoration(
                                labelText: 'Nama Blok',
                                hintText: 'Masukkan nama blok',
                                isDense: true,
                                filled: true,
                                fillColor: Colors.grey[100],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: Colors.grey.shade300, width: 1),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: Color(0xFF1D91AA), width: 1),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 16, horizontal: 16),
                              ),
                              keyboardType: TextInputType.name,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Masukan nama";
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: kapasitasBlokController,
                              decoration: InputDecoration(
                                labelText: 'Kapasitas',
                                hintText: 'Jumlah kapasitas',
                                isDense: true,
                                filled: true,
                                fillColor: Colors.grey[100],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: Colors.grey.shade300, width: 1),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: Color(0xFF1D91AA), width: 1),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 16, horizontal: 16),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Masukan kapasitas";
                                }
                                int? nilai = int.tryParse(value);
                                if (nilai != null) {
                                  if (nilai <= 0 || nilai >= 16) {
                                    return "Input dari 1-15";
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1D91AA),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          minimumSize: const Size(double.infinity, 48),
                          elevation: 0,
                        ),
                        onPressed: () {
                          if (blokKey.currentState?.validate() == true) {
                            setState(() {
                              blok.add({
                                "nama": namaBlokController.text,
                                "kapasitas": kapasitasBlokController.text,
                              });
                              Navigator.of(context).pop();
                            });
                          }
                        },
                        child: const Text(
                          'Tambah Blok',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();

    _kategori = widget.doc.data()?["kategori"];
    _namaController = TextEditingController(text: widget.doc.data()?["nama"]);
    _kapasitasController =
        TextEditingController(text: widget.doc.data()?["kapasitas"]);

    blokStore.where("kandang_id", isEqualTo: widget.doc.id).get().then((value) {
      value.docs.map((e) {
        Map<String, dynamic> data = e.data();
        data["id"] = e.id;

        setState(() {
          blok.add(data);
        });
        return data;
      }).toList();
    });

    urlgambar = Supabase.instance.client.storage
        .from('terdom')
        .getPublicUrl("kandang/${widget.doc.data()?['image']}");
  }

  @override
  Widget build(BuildContext context) {
    var dropdownKategori = <String>['Pembiakan', 'Penggemukan'];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D91AA),
        elevation: 0,
        title: const Text(
          "Edit Kandang",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo section

            // Form section
            Container(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1D91AA).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF1D91AA).withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.edit_note,
                            color: Color(0xFF1D91AA),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Data Kandang",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF1D91AA),
                                ),
                              ),
                              Text(
                                "Ubah informasi kandang",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Nama field
                    TextFormField(
                      controller: _namaController,
                      maxLength: 20,
                      decoration: InputDecoration(
                        labelText: 'Nama Kandang',
                        hintText: 'Masukkan nama kandang',
                        prefixIcon: const Icon(Icons.home_outlined,
                            color: Color(0xFF1D91AA)),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: Colors.grey.shade300, width: 1),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: Colors.grey.shade300, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFF1D91AA), width: 1.5),
                        ),
                      ),
                      keyboardType: TextInputType.name,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Masukan nama";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Kategori dropdown
                    DropdownButtonFormField(
                      decoration: InputDecoration(
                        labelText: 'Kategori',
                        hintText: 'Pilih kategori kandang',
                        prefixIcon: const Icon(Icons.category_outlined,
                            color: Color(0xFF1D91AA)),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: Colors.grey.shade300, width: 1),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: Colors.grey.shade300, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFF1D91AA), width: 1.5),
                        ),
                      ),
                      validator: (value) =>
                          value == null ? 'Pilih kategori' : null,
                      items: dropdownKategori
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      value: dropdownKategori.contains(_kategori)
                          ? (_kategori)
                          : null,
                      onChanged: (value) {
                        setState(() {
                          if (value != null) {
                            _kategori = value;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 20),

                    // Tanggal field
                    TextFormField(
                      controller: _tanggalController,
                      readOnly: true,
                      enabled: false,
                      decoration: InputDecoration(
                        labelText: 'Tanggal Update',
                        prefixIcon: const Icon(Icons.calendar_today,
                            color: Color(0xFF1D91AA)),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: Colors.grey.shade300, width: 1),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: Colors.grey.shade300, width: 1),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: Colors.grey.shade300, width: 1),
                        ),
                        suffixIcon: const Icon(Icons.date_range_outlined),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Blok section header
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1D91AA).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF1D91AA).withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.dashboard_outlined,
                                color: Color(0xFF1D91AA),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Blok Kandang",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Color(0xFF1D91AA),
                                    ),
                                  ),
                                  Text(
                                    "Tambah atau hapus blok",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1D91AA),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            onPressed: () => _showAddBlok(context),
                            // icon: const Icon(Icons.add, size: 20),
                            child: const Text("tambah"),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Blok list
                    blok.isEmpty
                        ? Container(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            alignment: Alignment.center,
                            child: Column(
                              children: [
                                Icon(
                                  Icons.dashboard_outlined,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "Belum ada blok",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Tekan 'Tambah' untuk menambahkan blok",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: blok.length,
                            itemBuilder: (context, index) {
                              var item = blok[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 4),
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1D91AA)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.dashboard_outlined,
                                      color: Color(0xFF1D91AA),
                                    ),
                                  ),
                                  title: Text(
                                    "Blok: ${item["nama"] ?? ""}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    "Kapasitas: ${item["kapasitas"] ?? ""} Ekor",
                                    style: const TextStyle(
                                      fontSize: 14,
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.redAccent),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext dialogContext) {
                                          return AlertDialog(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            title: Row(
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: Colors.red
                                                        .withOpacity(0.1),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                      Icons.delete_outline,
                                                      color: Colors.red),
                                                ),
                                                const SizedBox(width: 16),
                                                const Text("Konfirmasi Hapus"),
                                              ],
                                            ),
                                            content: const Text(
                                                "Apakah kamu yakin ingin menghapus blok ini?"),
                                            actions: [
                                              TextButton(
                                                child: const Text("Batal"),
                                                onPressed: () {
                                                  Navigator.of(dialogContext)
                                                      .pop();
                                                },
                                              ),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red,
                                                  foregroundColor: Colors.white,
                                                  elevation: 0,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                ),
                                                child: const Text("Hapus"),
                                                onPressed: () {
                                                  setState(() {
                                                    blok.removeAt(index);
                                                  });
                                                  Navigator.of(dialogContext)
                                                      .pop();
                                                },
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                    const SizedBox(height: 30),

                    // Main submit button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1D91AA),
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shadowColor: const Color(0xFF1D91AA).withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: const Size(double.infinity, 54),
                      ),
                      onPressed: () {
                        if (_formKey.currentState?.validate() == true) {
                          _editCage(context);
                        }
                      },
                      // icon: const Icon(Icons.save),
                      child: const Text(
                        'Simpan Perubahan',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
