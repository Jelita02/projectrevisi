import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
// ignore: library_prefixes
import 'package:firebase_auth/firebase_auth.dart' as userFire;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as path; //
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
class AnimalAdd extends StatefulWidget {
  final userFire.User user;
  const AnimalAdd({super.key, required this.user});

  @override
  State<AnimalAdd> createState() => _AnimalAddState();
}

class _AnimalAddState extends State<AnimalAdd> {
  final _formKey = GlobalKey<FormState>();
  bool _imageError = false; //
  bool _isImgValid = true;

  File? _imgFile;

  List<Map<String, dynamic>> _listKategori = [];
  List<Map<String, dynamic>> _listBlok = [];

  late String _kategori;
  late String _jenis;
  late String _kandangId;
  late String _kandang;
  late String _blokId;
  late String _blok;
  late String _usia;
  late String _statusKesehatan = "Sehat";
  late String _status = "Hidup";
  String _jenisKelamin = "Jantan";

  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _tanggalController = TextEditingController();
  final TextEditingController _bobotController = TextEditingController();

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

  var hewan = FirebaseFirestore.instance.collection('hewan');

  void _ambilGambar() async {
    final ImagePicker picker = ImagePicker();
    final XFile? img = await picker.pickImage(
      source: ImageSource.camera, // alternatively, use ImageSource.gallery
      maxWidth: 400,
    );
    if (img == null) return;
    setState(() {
      _imgFile = File(img.path); // convert it to a Dart:io file
    });
  }
  _tambahHewan() async {
  final newHewan = await hewan.add({
    "user_uid": widget.user.uid,
    "nama": _namaController.text,
    "nama_lower": _namaController.text.toLowerCase(),
    "usia": _usia,
    "kategori": _kategori,
    "jenis_kelamin": _jenisKelamin,
    "jenis": _jenis,
    "kandang_id": _kandangId,
    "kandang": _kandang,
    "blok_id": _blokId,
    "blok": _blok,
    "bobot": _bobotController.text,
    "bobot_akhir": _bobotController.text,
    "tanggal_masuk": _tanggalController.text,
    "status_kesehatan": _statusKesehatan,
    "status": _status,
    "foto_url": "", // sementara kosong
  });

  if (_imgFile != null) {
    // Ambil ekstensi file
    String extension = path.extension(_imgFile!.path);
    // Buat nama file unik pakai id doc
    String fileName = '${newHewan.id}$extension';

    try {
      await Supabase.instance.client.storage
          .from('terdom') // ganti sesuai bucket kamu
          .upload('hewan/$fileName', _imgFile!);

      // Setelah upload berhasil, ambil public URL
      final String imageUrl = Supabase.instance.client.storage
          .from('terdom')
          .getPublicUrl('hewan/$fileName');

      // Update Firestore dengan foto_url
      await hewan.doc(newHewan.id).update({
        "foto_url": imageUrl,
      });
    } catch (e) {
      print('Upload error: $e');
    }
  }

  Navigator.pop(context, true);
}


  @override
  void initState() {
    super.initState();

    _tanggalController.text = DateFormat('yyyy-MM-dd').format(DateTime.now()); // ← Tambahkan ini
    Map<String, int> kandangTotal = {};

    FirebaseFirestore.instance
        .collection("hewan")
        .where("user_uid", isEqualTo: widget.user.uid)
        .get()
        .then((value) {
      for (var element in value.docs) {
        kandangTotal[element['kandang_id']] =
            (kandangTotal[element['kandang_id']] ?? 0) + 1;
      }
      FirebaseFirestore.instance// otmatis dibautin berdasarkan kodig=ngan dibawhah ini 
          .collection("kandang") 
          .where("user_uid", isEqualTo: widget.user.uid)
          .orderBy("kategori", descending: false)
          .get()
          .then((value) {
        setState(() {
          _listKategori = value.docs
              .where((element) {
                return (kandangTotal[element.id] ?? 0) <
                    int.parse(element['kapasitas'] ?? 0);
              })
              .map((e) => {"id": e.id, "nama": e['nama']})
              .toList();
        });
      });
    });
  }

  void _getListBlok(String kategoriId) {
    Map<String, int> blokTotal = {};
    FirebaseFirestore.instance
        .collection("hewan")
        .where("user_uid", isEqualTo: widget.user.uid)
        .get()
        .then((value) {
      for (var element in value.docs) {
        blokTotal[element['blok_id']] =
            (blokTotal[element['blok_id']] ?? 0) + 1;
      }
    });
    FirebaseFirestore.instance
        .collection("blok")
        .where("kandang_id", isEqualTo: kategoriId)
        .orderBy("nama", descending: false)
        .get()
        .then((value) {
      setState(() {
        _listBlok = value.docs
            .where((element) =>
                (blokTotal[element.id] ?? 0) <
                int.parse(element['kapasitas'] ?? 0))
            .map((e) => {"id": e.id, "nama": e['nama']})
            .toList();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D91AA),
        elevation: 0,
        title: const Text(
          "Tambah Hewan",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          // Header section
          // Container(
          //   color: const Color.fromRGBO(29, 145, 170, 0.5),
          //   width: double.infinity,
          //   padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          //   child: Column(
          //     crossAxisAlignment: CrossAxisAlignment.start,
          //     children: [
          //       Text(
          //         "Tanggal: ${DateFormat('dd MMMM yyyy').format(DateTime.now())}",
          //         style: TextStyle(
          //           color: Colors.white.withOpacity(0.9),
          //           fontSize: 14,
          //         ),
          //       ),
          //       const SizedBox(height: 4),
          //       const Text(
          //         "Tambah Data Hewan Baru",
          //         style: TextStyle(
          //           fontSize: 18,
          //           fontWeight: FontWeight.w700,
          //           color: Colors.white,
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
          
          // // Curved transition
          // Container(
          //   height: 20,
          //   decoration: const BoxDecoration(
          //     color: Color.fromRGBO(29, 145, 170, 0.5),
          //     borderRadius: BorderRadius.only(
          //       bottomLeft: Radius.circular(20),
          //       bottomRight: Radius.circular(20),
          //     ),
          //   ),
          // ),
          
          // Form section
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    // Image upload section
                    // _buildSectionTitle("Foto Hewan", Icons.photo_camera),
                    // const SizedBox(height: 12),
                    Container(
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
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Column(
                          children: [
                            (_imgFile == null)
                                ? Container(
                                    height: 180,
                                    width: double.infinity,
                                    color: Colors.grey[100],
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: const Color.fromRGBO(29, 145, 170, 0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.photo_camera,
                                            size: 40,
                                            color: Color.fromRGBO(29, 145, 170, 1),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        const Text(
                                          "Unggah Foto Hewan",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: Color.fromRGBO(29, 145, 170, 1),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          " ",
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Image.file(
                                    _imgFile!,
                                    height: 200,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color.fromRGBO(29, 145, 170, 0.8),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () => _ambilGambar(),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.camera_alt, size: 18),
                                    SizedBox(width: 8),
                                    Text(
                                      "Ambil Foto",
                                      style: TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (!_isImgValid)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 12),
                        child: Text(
                          "Harap unggah foto hewan terlebih dahulu.",
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 24),
                    
                    // Basic info section
                    _buildSectionTitle("Informasi Dasar", Icons.info_outline),
                    const SizedBox(height: 12),
                    Container(
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
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name field
                          TextFormField(
                            controller: _namaController,
                            maxLength: 20,
                            decoration: InputDecoration(
                              labelText: 'Nama Hewan',
                              // prefixIcon: const Icon(Icons.agriculture, size: 22),
                              // prefixIcon: const Icon(FontAwesomeIcons.paw, size: 22),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color.fromRGBO(29, 145, 170, 1)),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Masukan nama";
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Gender selection
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Jenis Kelamin",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildRadioOption(
                                      value: "Jantan",
                                      groupValue: _jenisKelamin,
                                      icon: Icons.male,
                                      iconColor: Colors.blue,
                                      onChanged: (value) {
                                        setState(() {
                                          if (value != null) {
                                            _jenisKelamin = value;
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildRadioOption(
                                      value: "Betina",
                                      groupValue: _jenisKelamin,
                                      icon: Icons.female,
                                      iconColor: Colors.pink,
                                      onChanged: (value) {
                                        setState(() {
                                          if (value != null) {
                                            _jenisKelamin = value;
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Characteristics section
                    _buildSectionTitle("Karakteristik", Icons.category),
                    const SizedBox(height: 12),
                    Container(
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
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Age dropdown
                          _buildDropdown(
                            labelText: 'Usia',
                            icon: Icons.calendar_today,
                            items: <String>[
                              '1< thn (Gigi Susu)',
                              '1-2 thn (Poel 1)',
                              '2-3 thn (Poel 2)',
                              '3-4 thn (Poel 3)',
                              '4-5 thn (Poel 4)',
                              '>5 thn (Poel 5)',
                            ].map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                if (value != null) {
                                  _usia = value;
                                }
                              });
                            },
                            validator: (value) => value == null ? 'Pilih Usia' : null,
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Category dropdown
                          _buildDropdown(
                            labelText: 'Kategori',
                            icon: Icons.category,
                            items: <String>['Pembiakan', 'Penggemukan']
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                if (value != null) {
                                  _kategori = value;
                                }
                              });
                            },
                            validator: (value) => value == null ? 'Pilih kategori' : null,
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Animal type dropdown
                          _buildDropdown(
                            labelText: 'Jenis',
                            icon: Icons.agriculture,
                            items: <String>[
                              'Domba Garut',
                              'Domba Lokal',
                              'Domba Dorper',
                              'Domba Ekor Tebal',
                              'Domba Texel',
                              'Domba Merino',
                              'Domba Suffolk',
                              'Domba Awassi',
                              'Domba Van Rooy'
                            ].map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                if (value != null) {
                                  _jenis = value;
                                }
                              });
                            },
                            validator: (value) => value == null ? 'Pilih jenis' : null,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Status section
                    _buildSectionTitle("Status dan Kondisi", Icons.health_and_safety),
                    const SizedBox(height: 12),
                    Container(
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
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Health condition dropdown
                          _buildDropdown(
                            labelText: 'Kondisi Kesehatan',
                            icon: Icons.favorite,
                            value: _statusKesehatan,
                            items: <String>['Sehat', 'Sakit']
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                if (value != null) {
                                  _statusKesehatan = value;
                                }
                              });
                            },
                            validator: (value) => value == null ? 'Pilih Kondisi' : null,
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Status dropdown
                          _buildDropdown(
                            labelText: 'Status',
                            icon: Icons.info_outline,
                            value: _status,
                            items: <String>['Hidup', 'Mati', 'Terjual']
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                if (value != null) {
                                  _status = value;
                                }
                              });
                            },
                            validator: (value) => value == null ? 'Pilih Status' : null,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Location section
                    _buildSectionTitle("Lokasi Kandang", Icons.home_work),
                    const SizedBox(height: 12),
                    Container(
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
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Cage dropdown
                          _buildDropdown(
                            labelText: 'Kandang',
                            icon: Icons.home,
                            items: _listKategori
                                .map<DropdownMenuItem<Map<String, dynamic>>>((value) {
                              return DropdownMenuItem<Map<String, dynamic>>(
                                value: value,
                                child: Text(value['nama']),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                if (value != null) {
                                  _kandang = value["nama"] ?? "";
                                  _kandangId = value["id"] ?? "";
                                  _getListBlok(value["id"] ?? "");
                                }
                              });
                            },
                            validator: (value) => value == null ? 'Pilih kandang' : null,
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Block dropdown
                          _buildDropdown(
                            labelText: 'Blok',
                            icon: Icons.grid_view,
                            items: _listBlok
                                .map<DropdownMenuItem<Map<String, dynamic>>>((value) {
                              return DropdownMenuItem<Map<String, dynamic>>(
                                value: value,
                                child: Text(value["nama"] ?? ""),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                if (value != null) {
                                  _blok = value["nama"];
                                  _blokId = value["id"];
                                }
                              });
                            },
                            validator: (value) => value == null ? 'Pilih blok' : null,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Weight and Date section
                    _buildSectionTitle("Berat dan Tanggal", Icons.date_range),
                    const SizedBox(height: 12),
                    Container(
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
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              // Weight field
                              Expanded(
                                child: TextFormField(
                                  controller: _bobotController,
                                  decoration: InputDecoration(
                                    labelText: 'Bobot Masuk',
                                    suffixText: "Kg",
                                    prefixIcon: const Icon(Icons.monitor_weight, size: 22),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: Colors.grey[300]!),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: Colors.grey[300]!),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: Color.fromRGBO(29, 145, 170, 1)),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Masukan bobot";
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              
                              const SizedBox(width: 16),
                              
                              // Date field (disabled)
                              Expanded(
                                child: TextFormField(
                                  controller: _tanggalController,
                                  decoration: InputDecoration(
                                    // labelText: 'Tanggal Masuk',
                                    prefixIcon: const Icon(Icons.date_range, size: 22),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: Colors.grey[300]!),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: Colors.grey[300]!),
                                    ),
                                    disabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(color: Colors.grey[300]!),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[200],
                                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                  ),
                                  readOnly: true,
                                  enabled: false,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Masukan tanggal";
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Submit button
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromRGBO(26, 107, 125, 1),
                          foregroundColor: Colors.white,
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          final isValid = _formKey.currentState?.validate() ?? false;

                          if (_imgFile == null) {
                            setState(() {
                              _isImgValid = false;
                            });
                          } else {
                            setState(() {
                              _isImgValid = true;
                            });
                          }

                          if (!isValid || !_isImgValid) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Harap lengkapi semua data yang diperlukan."),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          if (isValid && _isImgValid) {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text("Konfirmasi Tambah Hewan"),
                                  content: const Text("Apakah semua data sudah benar dan ingin disimpan?"),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop(); // Tutup dialog
                                      },
                                      child: const Text("Batal"),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color.fromRGBO(26, 107, 125, 1),
                                      ),
                                      onPressed: () {
                                        Navigator.of(context).pop(); // Tutup dialog
                                        _tambahHewan(); // Jalankan fungsi simpan data
                                      },
                                      child: const Text(
                                        "Ya",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Harap lengkapi semua data terlebih dahulu."),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Icon(Icons.add),
                            SizedBox(width: 8),
                            Text(
                              'Tambah Hewan',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color.fromRGBO(29, 145, 170, 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: const Color.fromRGBO(29, 145, 170, 1),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color.fromRGBO(29, 145, 170, 1),
          ),
        ),
      ],
    );
  }
  
  Widget _buildRadioOption({
    required String value,
    required String groupValue,
    required IconData icon,
    required Color iconColor,
    required void Function(String?)? onChanged,
  }) {
    final isSelected = value == groupValue;
    
    return InkWell(
      onTap: () => onChanged?.call(value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? iconColor.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? iconColor : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 8),
            Text(
              value,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? iconColor : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDropdown<T>({
    required String labelText,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?)? onChanged,
    required String? Function(T?)? validator,
    T? value,
  }) {
    return DropdownButtonFormField<T>(
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(icon, size: 22),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color.fromRGBO(29, 145, 170, 1)),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
      value: value,
      style: const TextStyle(fontSize: 15, color: Colors.black87),
      icon: const Icon(Icons.arrow_drop_down, color: Color.fromRGBO(29, 145, 170, 1)),
      isExpanded: true,
      validator: validator,
      items: items,
      onChanged: onChanged,
    );
  }
}
