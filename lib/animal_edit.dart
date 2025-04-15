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

  TextEditingController _namaController = TextEditingController();
  TextEditingController _tanggalController = TextEditingController();
  TextEditingController _bobotController = TextEditingController();

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

  _editHewan() {
    hewan.doc(widget.doc.id).update({
      "user_uid": widget.user.uid,
      "nama": _namaController.text,
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

  @override
  void initState() {
    super.initState();

    _namaController = TextEditingController(text: widget.doc.data()?["nama"]);
    _tanggalController =
        TextEditingController(text: widget.doc.data()?["tanggal_masuk"]);
    _bobotController =
        TextEditingController(text: widget.doc.data()?["bobot_akhir"]);

    FirebaseFirestore.instance
        .collection("kandang")
        .where("user_uid", isEqualTo: widget.user.uid)
        .get()
        .then((value) {
      setState(() {
        _listKategori =
            value.docs.map((e) => {"id": e.id, "nama": e['nama']}).toList();
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
    FirebaseFirestore.instance
        .collection("blok")
        .where("kandang_id", isEqualTo: kategoriId)
        .get()
        .then((value) {
      setState(() {
        _listBlok =
            value.docs.map((e) => {"id": e.id, "nama": e['nama']}).toList();
      });
    });
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
      'Gigi Susu (1< thn)',
      'Poel 1 (1-2 thn)',
      'Poel 2 (2-3 thn)',
      'Poel 3 (3-4 thn)',
      'Poel 4 (4-5 thn)',
      'Poel 5 (>5 thn)',
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(29, 145, 170, 0.5),
        title: const Text(
          "Edit Hewan",
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                "Lengkapi data hewan",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Jenis Kelamin",
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text("Jantan"),
                          value: "Jantan",
                          groupValue: _jenisKelamin,
                          onChanged: (value) {
                            setState(() {
                              if (value != null) {
                                _jenisKelamin = value;
                              }
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text("Betina"),
                          value: "Betina",
                          groupValue: _jenisKelamin,
                          onChanged: (value) {
                            setState(() {
                              if (value != null) {
                                _jenisKelamin = value;
                              }
                            });
                          },
                        ),
                      )
                    ],
                  ),
                ],
              ),
              TextFormField(
                controller: _namaController,
                maxLength: 20,
                decoration: const InputDecoration(
                  labelText: 'Nama',
                  suffix: Icon(Icons.animation),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Masukan nama";
                  }

                  return null;
                },
              ),
              DropdownButtonFormField(
                decoration: const InputDecoration(
                  labelText: 'Usia',
                ),
                validator: (value) => value == null ? 'Pilih usia' : null,
                items:
                    dropdownUsia.map<DropdownMenuItem<String>>((String value) {
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
              ),
              DropdownButtonFormField(
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                ),
                validator: (value) => value == null ? 'Pilih kategori' : null,
                items: dropdownKategori
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                value:
                    dropdownKategori.contains(_kategori) ? (_kategori) : null,
                onChanged: (value) {
                  setState(() {
                    if (value != null) {
                      _kategori = value;
                    }
                  });
                },
              ),
              DropdownButtonFormField(
                decoration: const InputDecoration(
                  labelText: 'Kondisi',
                ),
                value: dropdownStatusKesehatan.contains(_statusKesehatan)
                    ? (_statusKesehatan)
                    : null,
                validator: (value) => value == null ? 'Pilih Kondisi' : null,
                items: dropdownStatusKesehatan
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
              ),
              DropdownButtonFormField(
                decoration: const InputDecoration(
                  labelText: 'Status',
                ),
                value: dropdownStatus.contains(_status) ? (_status) : null,
                validator: (value) => value == null ? 'Pilih Kondisi' : null,
                items: dropdownStatus
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
              ),
              DropdownButtonFormField(
                decoration: const InputDecoration(
                  labelText: 'Jenis',
                ),
                validator: (value) => value == null ? 'Pilih jenis' : null,
                items:
                    dropdownJenis.map<DropdownMenuItem<String>>((String value) {
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
              ),
              DropdownButtonFormField(
                decoration: const InputDecoration(
                  labelText: 'Kandang',
                ),
                validator: (value) => value == null ? 'Pilih kandang' : null,
                items: _listKategori
                    .map<DropdownMenuItem<Map<String, dynamic>>>((value) {
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
              ),
              DropdownButtonFormField(
                decoration: const InputDecoration(
                  labelText: 'Blok',
                ),
                validator: (value) => value == null ? 'Pilih blok' : null,
                items: _listBlok
                    .map<DropdownMenuItem<Map<String, dynamic>>>((value) {
                  return DropdownMenuItem<Map<String, dynamic>>(
                    value: value,
                    child: Text(value["nama"] ?? ""),
                  );
                }).toList(),
                value: _listBlok.firstWhere(
                    (e) => e["id"] == widget.doc.data()?["blok_id"],
                    orElse: () => {}),
                onChanged: (value) {
                  setState(() {
                    if (value != null) {
                      _blok = value["nama"];
                      _blokId = value["id"];
                    }
                  });
                },
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _bobotController,
                      decoration: const InputDecoration(
                        labelText: 'Bobot Masuk',
                        suffix: Text("Kg"),
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
                  const SizedBox(width: 20),
                  Expanded(
                    child: TextFormField(
                      controller: _tanggalController,
                      decoration: const InputDecoration(
                        labelText: 'Tanggal Masuk',
                        suffix: Icon(Icons.date_range_outlined),
                      ),
                      readOnly: true,
                      onTap: () => _selectDate(context),
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
              const SizedBox(height: 20),
              Container(
                // height: 80,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.black,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.grey,
                      blurRadius: 10.0,
                      offset: Offset(1, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20)),
                      child: (_imgFile == null)
                          ? const Text(
                              "Foto Hewan",
                              style:
                                  TextStyle(fontSize: 18, color: Colors.grey),
                            )
                          : Image.file(
                              _imgFile!,
                              height: 200,
                              width: 200,
                            ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromRGBO(48, 130, 148, 0.45),
                      ),
                      onPressed: () => _ambilGambar(),
                      child: const Text(
                        "Pilih",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      // padding: EdgeInsets.all(20),
                      backgroundColor: const Color.fromRGBO(26, 107, 125, 1),
                    ),
                    onPressed: () {
                      if (_formKey.currentState?.validate() == true) {
                        _editHewan();
                      }
                    },
                    child: const Text(
                      'Edit Hewan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
