import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
// ignore: library_prefixes
import 'package:firebase_auth/firebase_auth.dart' as userFire;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as path;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AnimalEdit extends StatefulWidget {
  final userFire.User user;
  final DocumentSnapshot<Map<String, dynamic>> doc;
  const AnimalEdit({super.key, required this.user, required this.doc});

  @override
  State<AnimalEdit> createState() => _AnimalEditState();
}

class _AnimalEditState extends State<AnimalEdit> {
  final _formKey = GlobalKey<FormState>();

  File? _imgFile;

  List<Map<String, dynamic>> _listKategori = [];
  List<Map<String, dynamic>> _listBlok = [];

  late String _kategori;
  late String _jenis;
  late String _kandangId;
  late String _kandang;
  late String _blokId;
  late String _blok;
  late String _statusKesehatan;
  late String _status;
  late String _usia;
  String _jenisKelamin = "Jantan";
  String urlgambar = "";

  TextEditingController _namaController = TextEditingController();
  final TextEditingController _tanggalController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
  TextEditingController _bobotController = TextEditingController();

  void _showImage() async {
    final url = Supabase.instance.client.storage
        .from('terdom')
        .getPublicUrl("hewan/${widget.doc.id}.jpg");

    setState(() {
      urlgambar = url;
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

  var hewan = FirebaseFirestore.instance.collection('hewan');

  _editHewan() {
    hewan.doc(widget.doc.id).update({
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
       "sudah_diedit": true, 
    }).then((value) {
      if (_imgFile != null) {
        // Ambil ekstensi file asli
        String extension = path.extension(_imgFile!.path);

        // Buat nama file unik dengan UUID
        String fileName = '${widget.doc.id}$extension';

        Supabase.instance.client.storage
            .from('terdom') // Ganti dengan nama bucket
            .upload('hewan/$fileName', _imgFile!)
            .then((value) => print('File uploaded: $value'))
            .catchError((error) => {print("ERRORRR: $error")});
      }

      hewan.doc(widget.doc.id).get().then((value) => Navigator.pop(
            context,
            value,
          ));
    });
  }
 bool _isEditable = true;
  @override
  void initState() {
    super.initState();

     _isEditable = widget.doc.data()?["sudah_diedit"] != true;
    _showImage();
    _namaController = TextEditingController(text: widget.doc.data()?["nama"]);
    _bobotController =
        TextEditingController(text: widget.doc.data()?["bobot_akhir"]);

    Map<String, int> kandangTotal = {};

    FirebaseFirestore.instance
        .collection("hewan")
        .where("user_uid", isEqualTo: widget.user.uid)
        .where(FieldPath.documentId, isNotEqualTo: widget.doc.id)
        .get()
        .then((value) {
      for (var element in value.docs) {
        kandangTotal[element['kandang_id']] =
            (kandangTotal[element['kandang_id']] ?? 0) + 1;
      }
      FirebaseFirestore.instance
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

    _kategori = widget.doc.data()?["kategori"];
    _jenisKelamin = widget.doc.data()?["jenis_kelamin"];
    _statusKesehatan = widget.doc.data()?["status_kesehatan"];
    _status = widget.doc.data()?["status"] ?? "";
    _jenis = widget.doc.data()?["jenis"];
    _kandang = widget.doc.data()?["kandang"];
    _blok = widget.doc.data()?["blok"];
    _kandangId = widget.doc.data()?["kandang_id"];
    _blokId = widget.doc.data()?["blok_id"];
    _usia = widget.doc.data()?["usia"];

    _getListBlok(_kandangId);
  }

  void _getListBlok(String kategoriId) {
    Map<String, int> blokTotal = {};
    FirebaseFirestore.instance
        .collection("hewan")
        .where("user_uid", isEqualTo: widget.user.uid)
        .where(FieldPath.documentId, isNotEqualTo: widget.doc.id)
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

  Color _getStatusColor(String status) {
    switch (status) {
      case "Hidup":
        return Colors.green;
      case "Mati":
        return Colors.red;
      case "Terjual":
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
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

  @override
  Widget build(BuildContext context) {
    var dropdownKategori = <String>['Pembiakan', 'Penggemukan'];
    var dropdownStatusKesehatan = <String>['Sehat', 'Sakit'];
    var dropdownStatus = <String>['Hidup', 'Mati', 'Terjual'];
    var dropdownJenis = <String>[
      'Domba Garut',
      'Domba Lokal',
      'Domba Dorper',
      'Domba Ekor Tebal',
      'Domba Texel',
      'Domba Merino',
      'Domba Suffolk',
      'Domba Awassi',
      'Domba Van Rooy'
    ];
    var dropdownUsia = <String>[
      '1< thn (Gigi Susu)',
      '1-2 thn (Poel 1)',
      '2-3 thn (Poel 2)',
      '3-4 thn (Poel 3)',
      '4-5 thn (Poel 4)',
      '>5 thn (Poel 5)',
    ];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D91AA),
        elevation: 0,
        title: const Text(
          "Edit Hewan",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Header section with current image if available
          // Container(
          //   color: const Color(0xFF1D91AA),
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
          //       const SizedBox(height: 8),
          //       Row(
          //         children: [
          //           Expanded(
          //             child: Column(
          //               crossAxisAlignment: CrossAxisAlignment.start,
          //               children: [
          //                 const Text(
          //                   "Edit Data Hewan",
          //                   style: TextStyle(
          //                     fontSize: 18,
          //                     fontWeight: FontWeight.w700,
          //                     color: Colors.white,
          //                   ),
          //                 ),
          //                 const SizedBox(height: 4),
          //                 Text(
          //                   widget.doc.data()?["nama"] ?? "Hewan",
          //                   style: const TextStyle(
          //                     fontSize: 22,
          //                     fontWeight: FontWeight.w700,
          //                     color: Colors.white,
          //                   ),
          //                 ),
          //               ],
          //             ),
          //           ),
          //           if (!_isEditable)
          //             Container(
          //               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          //               decoration: BoxDecoration(
          //                 color: Colors.red.withOpacity(0.2),
          //                 borderRadius: BorderRadius.circular(30),
          //               ),
          //               child: const Row(
          //                 mainAxisSize: MainAxisSize.min,
          //                 children: [
          //                   Icon(
          //                     Icons.lock,
          //                     color: Colors.white,
          //                     size: 16,
          //                   ),
          //                   SizedBox(width: 4),
          //                   Text(
          //                     "Sudah Diedit",
          //                     style: TextStyle(
          //                       fontSize: 12,
          //                       fontWeight: FontWeight.w600,
          //                       color: Colors.white,
          //                     ),
          //                   ),
          //                 ],
          //               ),
          //             ),
          //         ],
          //       ),
          //     ],
          //   ),
          // ),
          
          // Curved transition
          Container(
            height: 20,
            decoration: const BoxDecoration(
              color: Color(0xFF1D91AA),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
          ),
          
          // Form section
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    // Basic information section
                    _buildSectionTitle("Informasi Dasar", Icons.info_outline),
                    const SizedBox(height: 16),
                    if (!_isEditable)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.lock,
                              color: Colors.white,
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Text(
                              "Sudah Diedit",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
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
                            enabled: _isEditable,
                            decoration: InputDecoration(
                              labelText: 'Nama Hewan',
                              prefixIcon: const Icon(FontAwesomeIcons.paw, size: 22),
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
                                borderSide: const BorderSide(color: Color(0xFF1D91AA)),
                              ),
                              filled: true,
                              fillColor: _isEditable ? Colors.white : Colors.grey[100],
                              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Masukan nama";
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 20),
                          
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
                    const SizedBox(height: 16),
                    
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
                            items: dropdownUsia.map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            value: dropdownUsia.contains(_usia) ? (_usia) : null,
                            onChanged: (value) {
                              setState(() {
                                if (value != null) {
                                  _usia = value;
                                }
                              });
                            },
                            validator: (value) => value == null ? 'Pilih usia' : null,
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Category dropdown
                          _buildDropdown(
                            labelText: 'Kategori',
                            icon: Icons.category,
                            items: dropdownKategori.map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            value: dropdownKategori.contains(_kategori) ? (_kategori) : null,
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
                            items: dropdownJenis.map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            value: dropdownJenis.contains(_jenis) ? (_jenis) : null,
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
                    
                    // // Status section
                    // _buildSectionTitle("Status dan Kondisi", Icons.health_and_safety),
                    // const SizedBox(height: 16),
                    
                    // Container(
                    //   decoration: BoxDecoration(
                    //     color: Colors.white,
                    //     borderRadius: BorderRadius.circular(12),
                    //     boxShadow: [
                    //       BoxShadow(
                    //         color: Colors.black.withOpacity(0.05),
                    //         blurRadius: 10,
                    //         spreadRadius: 0,
                    //         offset: const Offset(0, 2),
                    //       ),
                    //     ],
                    //   ),
                    //   padding: const EdgeInsets.all(16),
                    //   child: Column(
                    //     children: [
                    //       // Health condition dropdown
                    //       _buildDropdown(
                    //         labelText: 'Kondisi Kesehatan',
                    //         icon: Icons.favorite,
                    //         items: dropdownStatusKesehatan.map<DropdownMenuItem<String>>((String value) {
                    //           return DropdownMenuItem<String>(
                    //             value: value,
                    //             child: Row(
                    //               children: [
                    //                 Container(
                    //                   width: 12,
                    //                   height: 12,
                    //                   decoration: BoxDecoration(
                    //                     color: value == 'Sehat' ? Colors.green : Colors.red,
                    //                     borderRadius: BorderRadius.circular(6),
                    //                   ),
                    //                 ),
                    //                 const SizedBox(width: 8),
                    //                 Text(value),
                    //               ],
                    //             ),
                    //           );
                    //         }).toList(),
                    //         value: dropdownStatusKesehatan.contains(_statusKesehatan) ? (_statusKesehatan) : null,
                    //         onChanged: (value) {
                    //           setState(() {
                    //             if (value != null) {
                    //               _statusKesehatan = value;
                    //             }
                    //           });
                    //         },
                    //         validator: (value) => value == null ? 'Pilih Kondisi' : null,
                    //       ),
                          
                    //       const SizedBox(height: 16),
                          
                    //       // Status dropdown
                    //       _buildDropdown(
                    //         labelText: 'Status',
                    //         icon: Icons.info_outline,
                    //         items: dropdownStatus.map<DropdownMenuItem<String>>((String value) {
                    //           return DropdownMenuItem<String>(
                    //             value: value,
                    //             child: Row(
                    //               children: [
                    //                 Container(
                    //                   width: 12,
                    //                   height: 12,
                    //                   decoration: BoxDecoration(
                    //                     color: _getStatusColor(value),
                    //                     borderRadius: BorderRadius.circular(6),
                    //                   ),
                    //                 ),
                    //                 const SizedBox(width: 8),
                    //                 Text(value),
                    //               ],
                    //             ),
                    //           );
                    //         }).toList(),
                    //         value: dropdownStatus.contains(_status) ? (_status) : null,
                    //         onChanged: (value) {
                    //           setState(() {
                    //             if (value != null) {
                    //               _status = value;
                    //             }
                    //           });
                    //         },
                    //         validator: (value) => value == null ? 'Pilih Status' : null,
                    //       ),
                    //     ],
                    //   ),
                    // ),
                    
                    const SizedBox(height: 24),
                    
                    // Location section
                    _buildSectionTitle("Lokasi Kandang", Icons.home_work),
                    const SizedBox(height: 16),
                    
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
                            items: _listKategori.map<DropdownMenuItem<Map<String, dynamic>>>((value) {
                              return DropdownMenuItem<Map<String, dynamic>>(
                                value: value,
                                child: Text(value['nama']),
                              );
                            }).toList(),
                            value: _listKategori.firstWhere(
                                (e) => e["id"] == widget.doc.data()?["kandang_id"],
                                orElse: () => {}),
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
                            items: _listBlok.map<DropdownMenuItem<String>>((value) {
                              return DropdownMenuItem<String>(
                                value: value["id"],
                                child: Text(value["nama"] ?? ""),
                              );
                            }).toList(),
                            value: _listBlok
                                    .firstWhere(
                                        (e) => e["id"] == widget.doc.data()?["blok_id"],
                                        orElse: () => {})
                                    .isEmpty
                                ? null
                                : widget.doc.data()?["blok_id"],
                            onChanged: (value) {
                              setState(() {
                                if (value != null) {
                                  Map<String, dynamic> choiceBlok =
                                      _listBlok.firstWhere((item) => item['id'] == value);
                                  _blok = choiceBlok["nama"];
                                  _blokId = choiceBlok["id"];
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
                    const SizedBox(height: 16),
                    
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
                      child: Row(
                        children: [
                          // Weight field
                          Expanded(
                            child: TextFormField(
                              controller: _bobotController,
                              keyboardType: TextInputType.number,
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
                                  borderSide: const BorderSide(color: Color(0xFF1D91AA)),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                              ),
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
                              readOnly: true,
                              enabled: false,
                              decoration: InputDecoration(
                                labelText: 'Tanggal Update',
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
                                fillColor: Colors.grey[100],
                                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                              ),
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
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Submit button
                    if (_isEditable)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1D91AA),
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shadowColor: const Color(0xFF1D91AA).withOpacity(0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              if (_formKey.currentState?.validate() == true) {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      title: const Text(
                                        "Konfirmasi Perubahan",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1D91AA),
                                        ),
                                      ),
                                      content: const Text(
                                        "Apakah Anda yakin ingin menyimpan perubahan data hewan ini?",
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
                                            backgroundColor: const Color(0xFF1D91AA),
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                          ),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                            _editHewan();
                                          },
                                          child: const Text("Simpan"),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              }
                            },
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.save),
                                SizedBox(width: 8),
                                Text(
                                  'Simpan Perubahan',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                    const SizedBox(height: 20),
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
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1D91AA),
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
    required T? value,
    required void Function(T?)? onChanged,
    required String? Function(T?)? validator,
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
          borderSide: const BorderSide(color: Color(0xFF1D91AA)),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
      value: value,
      style: const TextStyle(fontSize: 15, color: Colors.black87),
      icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF1D91AA)),
      isExpanded: true,
      validator: validator,
      items: items,
      onChanged: onChanged,
    );
  }
}
