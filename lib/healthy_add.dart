import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:firebase_auth/firebase_auth.dart' as fire;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ternak/animal_menu.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as path;

class HealthyAdd extends StatefulWidget {
  final fire.User user;
  const HealthyAdd({super.key, required this.user});

  @override
  State<HealthyAdd> createState() => HealthyAddState();
}

class HealthyAddState extends State<HealthyAdd> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _tanggalController = TextEditingController();
  final TextEditingController _textOtherController = TextEditingController();

  bool _vaksinCheck = false;
  bool _nafsuCheck = false;
  bool _pinkEyeCheck = false;
  bool _busukCheck = false;
  bool _otherCheck = false;

  File? _image;
  final picker = ImagePicker();

  DocumentSnapshot<Map<String, dynamic>>? animal;

  Future _getImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      }
    });
  }

  void _showPicker(context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () {
                  _getImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () {
                  _getImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
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
        _tanggalController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _addHealthy() {
    var kesehatan = FirebaseFirestore.instance.collection('kesehatan');

    List<String> keterangan = [];
    _vaksinCheck ? keterangan.add("Vaksin") : null;
    _nafsuCheck ? keterangan.add("Nafsu Makan Turun") : null;
    _pinkEyeCheck ? keterangan.add("Penyakit Mata (pink eye)") : null;
    _busukCheck ? keterangan.add("Busuk Kuku") : null;
    _otherCheck ? keterangan.add(_textOtherController.text) : null;

    kesehatan.add({
      "user_uid": widget.user.uid,
      "hewan_nama": animal?.data()?["nama"],
      "hewan_id": animal?.id,
      "tanggal": _tanggalController.text,
      "keterangan": keterangan,
    }).then((value) {
      if (_image != null) {
        // Ambil ekstensi file asli
        String extension = path.extension(_image!.path);

        // Buat nama file unik dengan UUID
        String fileName = '${value.id}$extension';
        Supabase.instance.client.storage
            .from('terdom') // Ganti dengan nama bucket
            .upload('kesehatan/$fileName', _image!)
            .then((data) {
          kesehatan.doc(value.id).update({
            "image": fileName,
          });
        }).catchError((error) => {print("ERRORRR: $error")});
      }

      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(29, 145, 170, 0.5),
        title: const Text(
          "Kesehatan",
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
                "Foto Hewan",
                style: TextStyle(
                  color: Color.fromRGBO(0, 0, 0, 0.5),
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => _showPicker(context),
                child: _image == null
                    ? DottedBorder(
                        borderType: BorderType.RRect,
                        radius: const Radius.circular(5),
                        dashPattern: const [10, 10],
                        color: const Color.fromRGBO(26, 107, 125, 1),
                        child: Container(
                          margin: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.camera_alt,
                                  size: 40,
                                  color: Color.fromRGBO(26, 107, 125, 1),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  "Upload",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color.fromRGBO(26, 107, 125, 1),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      )
                    : Image.file(_image!),
              ),
              const SizedBox(height: 20),
              const Text(
                "keterangan",
                style: TextStyle(
                  color: Color.fromRGBO(0, 0, 0, 0.5),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 20),
              CheckboxListTile(
                value: _vaksinCheck,
                onChanged: (value) => setState(() {
                  _vaksinCheck = !_vaksinCheck;
                }),
                title: const Text("Vaksin"),
              ),
              CheckboxListTile(
                value: _nafsuCheck,
                onChanged: (value) => setState(() {
                  _nafsuCheck = !_nafsuCheck;
                }),
                title: const Text("Nafsu Makan Turun"),
              ),
              CheckboxListTile(
                value: _pinkEyeCheck,
                onChanged: (value) => setState(() {
                  _pinkEyeCheck = !_pinkEyeCheck;
                }),
                title: const Text("Penyakit mata (pink eye)"),
              ),
              
              CheckboxListTile(
                value: _busukCheck,
                onChanged: (value) => setState(() {
                  _busukCheck = !_busukCheck;
                }),
                title: const Text("Busuk kuku"),
              ),
              CheckboxListTile(
                value: _otherCheck,
                onChanged: (value) => setState(() {
                  _otherCheck = !_otherCheck;
                }),
                title: const Text("Lainnya"),
              ),
              if (_otherCheck) // Tampilkan input hanya jika checkbox aktif
                TextFormField(
                  validator: (value) {
                    if ((value == null || value.isEmpty) && _otherCheck) {
                      return "Masukan keterangan lainya";
                    }

                    return null;
                  },
                  controller: _textOtherController,
                  decoration: const InputDecoration(
                    labelText: "Masukkan keterangan lain",
                    border: OutlineInputBorder(),
                  ),
                ),
              TextFormField(
                controller: _tanggalController,
                decoration: const InputDecoration(
                  labelText: 'Tanggal kesehatan',
                  suffix: Icon(Icons.date_range_outlined),
                ),
                readOnly: true,
                onTap: () => _selectDate(context),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Masukan tanggal kesehatan";
                  }

                  return null;
                },
              ),
              const SizedBox(height: 20),
              const Text(
                "Hewan ",
                style: TextStyle(
                  color: Color.fromRGBO(0, 0, 0, 0.5),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
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
                      child: Text(
                        (animal == null)
                            ? "Pilih Hewan yang Sakit"
                            : (animal!.data()?["nama"] ?? ""),
                        style: TextStyle(
                            fontSize: 18,
                            color:
                                (animal == null) ? Colors.grey : Colors.black),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromRGBO(48, 130, 148, 0.45),
                      ),
                      onPressed: () {
                        Navigator.push<DocumentSnapshot<Map<String, dynamic>>>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MenuAnimal(
                                user: widget.user,
                                isForHealthy: true,
                              ),
                            )).then((value) => setState(() {
                              animal = value;
                            }));
                      },
                      child: const Text(
                        "Pilih",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  // padding: EdgeInsets.all(20),
                  backgroundColor: const Color.fromRGBO(26, 107, 125, 1),
                ),
                onPressed: () {
                  if (_formKey.currentState?.validate() == true) {
                    _addHealthy();
                  }
                },
                child: const Text(
                  'Simpan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
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
