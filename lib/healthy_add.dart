import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:firebase_auth/firebase_auth.dart' as fire;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ternak/animal_menu.dart';
import 'package:ternak/components/colors.dart';
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

  final TextEditingController _tanggalController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
  final TextEditingController _textOtherController = TextEditingController();

  bool _vaksinCheck = false;
  bool _nafsuCheck = false;
  bool _pinkEyeCheck = false;
  bool _busukCheck = false;
  bool _otherCheck = false;

  File? _image;
  final picker = ImagePicker();
  bool _isAnyCheckboxChecked() {
    return _vaksinCheck ||
        _nafsuCheck ||
        _pinkEyeCheck ||
        _busukCheck ||
        _otherCheck;
  }

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
        _tanggalController.text =
            DateFormat('yyyy-MM-dd').format(DateTime.now());
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
        }).catchError((error) {
          debugPrint("ERROR: $error");
          return null;
        });
      }

      Navigator.pop(context);
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
          "Keterangan ",
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
          //   color: const Color(0xFF1D91AA),
          //   width: double.infinity,
          //   padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
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
          //     ],
          //   ),
          // ),
          
          // Curved transition
          // Container(
          //   height: 20,
          //   decoration: const BoxDecoration(
          //     color: Color(0xFF1D91AA),
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
                          ? Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 8,
                                    spreadRadius: 0,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: DottedBorder(
                                borderType: BorderType.RRect,
                                radius: const Radius.circular(12),
                                dashPattern: const [8, 8],
                                color: const Color(0xFF1D91AA),
                                padding: EdgeInsets.zero,
                                child: Container(
                                  height: 180,
                                  width: double.infinity,
                                  margin: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1D91AA).withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt,
                                          size: 40,
                                          color: Color(0xFF1D91AA),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        "Upload Foto",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF1D91AA),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Tap untuk memilih gambar",
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    spreadRadius: 0,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  _image!,
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "keterangan",
                      style: TextStyle(
                        color: Color.fromRGBO(0, 0, 0, 0.5),
                        fontSize: 16,
                      ),
                    ),
                Text(
                  "Tanggal: ${DateFormat('dd MMMM yyyy').format(DateTime.now())}",
                  style: TextStyle(
                    color: Color(0xFF1D91AA),
                    fontSize: 14,
                  ),
                ),
              
                    // const SizedBox(height: 20),
                    // Row(
                    //   children: [
                    //     Container(
                    //       padding: const EdgeInsets.all(8),
                    //       decoration: BoxDecoration(
                    //         color: const Color(0xFF1D91AA).withOpacity(0.1),
                    //         borderRadius: BorderRadius.circular(8),
                    //       ),
                    //       child: const Icon(
                    //         Icons.medical_services,
                    //         color: Color(0xFF1D91AA),
                    //         size: 18,
                    //       ),
                    //     ),
                    //     const SizedBox(width: 10),
                    //     const Text(
                    //       "Catatan",
                    //       style: TextStyle(
                    //         color: Color(0xFF1D91AA),
                    //         fontSize: 16,
                    //         fontWeight: FontWeight.w600,
                    //       ),
                    //     ),
                    //   ],
                    // ),
            
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            spreadRadius: 0,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildCheckboxTile("Vaksin", _vaksinCheck, (value) => setState(() {
                            _vaksinCheck = !_vaksinCheck;
                          }), Icons.local_hospital, Colors.blue),
                          const Divider(height: 1, indent: 16, endIndent: 16),
                          _buildCheckboxTile("Nafsu Makan Turun", _nafsuCheck, (value) => setState(() {
                            _nafsuCheck = !_nafsuCheck;
                          }), Icons.no_food, Colors.orange),
                          const Divider(height: 1, indent: 16, endIndent: 16),
                          _buildCheckboxTile("Penyakit mata (pink eye)", _pinkEyeCheck, (value) => setState(() {
                            _pinkEyeCheck = !_pinkEyeCheck;
                          }), Icons.visibility_off, Colors.red),
                          const Divider(height: 1, indent: 16, endIndent: 16),
                          _buildCheckboxTile("Busuk kuku", _busukCheck, (value) => setState(() {
                            _busukCheck = !_busukCheck;
                          }), Icons.healing, Colors.purple),
                          const Divider(height: 1, indent: 16, endIndent: 16),
                          _buildCheckboxTile("Lainnya", _otherCheck, (value) => setState(() {
                            _otherCheck = !_otherCheck;
                          }), Icons.add_circle_outline, Colors.teal),
                        ],
                      ),
                    ),
                    if (_otherCheck) // Tampilkan input hanya jika checkbox aktif
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                spreadRadius: 0,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextFormField(
                            validator: (value) {
                              if ((value == null || value.isEmpty) && _otherCheck) {
                                return "Masukan keterangan lainnya";
                              }

                              return null;
                            },
                            controller: _textOtherController,
                            decoration: InputDecoration(
                              labelText: "Masukkan keterangan lain",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                          ),
                        ),
                      ),
                    // Hidden date field
                    Opacity(
                      opacity: 0,
                      child: SizedBox(
                        height: 0,
                        child: TextFormField(
                          controller: _tanggalController,
                          enabled: false,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Masukan tanggal keterangan";
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        // Container(
                        //   padding: const EdgeInsets.all(8),
                        //   decoration: BoxDecoration(
                        //     color: const Color(0xFF1D91AA).withOpacity(0.1),
                        //     borderRadius: BorderRadius.circular(8),
                        //   ),
                        //   // child: const Icon(
                        //   //   Icons.pets,
                        //   //   color: Color(0xFF1D91AA),
                        //   //   size: 18,
                        //   // ),
                        // ),
                        const SizedBox(width: 10),
                        const Text(
                          "Pilih Hewan",
                          style: TextStyle(
                            color: Color(0xFF1D91AA),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            spreadRadius: 0,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                animal == null ? "Belum Ada Hewan Dipilih" : animal!.data()?["nama"] ?? "",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: animal == null ? Colors.grey[500] : Colors.black,
                                ),
                              ),
                              if (animal == null)
                                Text(
                                  "Klik tombol 'Pilih' untuk memilih hewan",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                            ],
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1D91AA),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              Navigator.push<DocumentSnapshot<Map<String, dynamic>>>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MenuAnimal(
                                    user: widget.user,
                                    isForHealthy: true,
                                  ),
                                ),
                              ).then((value) => setState(() {
                                animal = value;
                              }));
                            },
                            child: const Text(
                              "Pilih",
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1D91AA),
                          foregroundColor: Colors.white,
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          final isValid = _formKey.currentState?.validate() ?? false;

                          if (!isValid) return;

                          if (!_isAnyCheckboxChecked()) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text("Pilih minimal satu keterangan kesehatan."),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          if (_image == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Harap unggah foto hewan."),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          if (animal == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Harap pilih hewan terlebih dahulu."),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          _addHealthy();
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Icon(Icons.save),
                            SizedBox(width: 8),
                            Text(
                              'Simpan',
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

  Widget _buildCheckboxTile(String title, bool value, Function(bool?) onChanged, IconData icon, Color color) {
    return CheckboxListTile(
      value: value,
      onChanged: onChanged,
      title: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Text(title),
        ],
      ),
    );
  }
}
