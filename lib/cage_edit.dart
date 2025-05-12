import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fire;
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
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

  var kandang = FirebaseFirestore.instance.collection('kandang');
  var blokStore = FirebaseFirestore.instance.collection('blok');

  void _editCage(context) {
    kandang.doc(widget.doc.id).update({
      "nama": _namaController.text,
      "nama_lower": _namaController.text.toLowerCase(),
      "kapasitas": _kapasitasController.text,
      "kategori": _kategori,
    }).then((value) async {
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
        var doc = await blokStore.add({
          "user_uid": widget.user.uid,
          "kandang_id": widget.doc.id,
          "nama": v["nama"] ?? "",
          "kapasitas": v["kapasitas"] ?? "",
        });

        listId[doc.id] = doc.id;
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

  void _showAddBlok(context) {
    final blokKey = GlobalKey<FormState>();
    final TextEditingController namaBlokController = TextEditingController();
    final TextEditingController kapasitasBlokController =
        TextEditingController();

    // showModalBottomSheet(
    //   context: context,
    //   builder: (BuildContext bc) {
    //     return SafeArea(
    //       child: Container(
    //         padding: const EdgeInsets.all(20),
    //         child: Form(
    //           key: blokKey,
    //           child: Wrap(
    //             children: <Widget>[
    //               Row(
    //                 children: [
    //                   Expanded(
    //                     child: Padding(
    //                       padding: const EdgeInsets.all(10),
    //                       child: TextFormField(
    //                         controller: namaBlokController,
    //                         maxLength: 20,
    //                         decoration: const InputDecoration(
    //                           labelText: 'Nama',
    //                         ),
    //                         keyboardType: TextInputType.name,
    //                         validator: (value) {
    //                           if (value == null || value.isEmpty) {
    //                             return "Masukan nama";
    //                           }

    //                           return null;
    //                         },
    //                       ),
    //                     ),
    //                   ),
    //                   Expanded(
    //                     child: Padding(
    //                       padding: const EdgeInsets.all(10),
    //                       child: TextFormField(
    //                         controller: kapasitasBlokController,
    //                         decoration: const InputDecoration(
    //                           labelText: 'Kapasitas',
    //                         ),
    //                         keyboardType: TextInputType.number,
    //                         validator: (value) {
    //                           if (value == null || value.isEmpty) {
    //                             return "Masukan kapasitas";
    //                           }

    //                           return null;
    //                         },
    //                       ),
    //                     ),
    //                   ),
    //                 ],
    //               ),
    //               Center(
    //                 child: SizedBox(
    //                   width: double.infinity,
    //                   child: ElevatedButton(
    //                     style: ElevatedButton.styleFrom(
    //                       backgroundColor:
    //                           const Color.fromRGBO(26, 107, 125, 1),
    //                     ),
    //                     onPressed: () {
    //                       if (blokKey.currentState?.validate() == true) {
    //                         setState(() {
    //                           blok.add({
    //                             "nama": namaBlokController.text,
    //                             "kapasitas": kapasitasBlokController.text,
    //                           });

    //                           Navigator.of(context).pop();
    //                         });
    //                       }
    //                     },
    //                     child: const Text(
    //                       'Tambah Blok',
    //                       style: TextStyle(
    //                         color: Colors.white,
    //                         fontSize: 20,
    //                       ),
    //                     ),
    //                   ),
    //                 ),
    //               ),
    //             ],
    //           ),
    //         ),
    //       ),
    //     );
    //   },
    // );
    showModalBottomSheet(
      isScrollControlled:
          true, // <- penting untuk menghindari tertutup keyboard
      context: context,
      builder: (BuildContext bc) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: blokKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: TextFormField(
                                controller: namaBlokController,
                                maxLength: 20,
                                decoration: const InputDecoration(
                                  labelText: 'Nama',
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 10),
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
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: TextFormField(
                                controller: kapasitasBlokController,
                                decoration: const InputDecoration(
                                  labelText: 'Kapasitas',
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 10),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "Masukan kapasitas";
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromRGBO(26, 107, 125, 1),
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
                              color: Colors.white,
                              fontSize: 20,
                            ),
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
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(29, 145, 170, 0.5),
        title: const Text(
          "Edit Kandang",
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
                "Lengkapi data kandang",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _namaController,
                maxLength: 20,
                decoration: const InputDecoration(
                  labelText: 'Nama',
                ),
                keyboardType: TextInputType.name,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Masukan nama";
                  }

                  return null;
                },
              ),
              // TextFormField(
              //   controller: _kapasitasController,
              //   decoration: const InputDecoration(
              //     labelText: 'Kapasitas',
              //   ),
              //   keyboardType: TextInputType.number,
              //   validator: (value) {
              //     if (value == null || value.isEmpty) {
              //       return "Masukan kapasitas";
              //     }

              //     return null;
              //   },
              // ),
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
              // const SizedBox(height: 20),
              // Container(
              //   // height: 80,
              //   padding: const EdgeInsets.all(10),
              //   decoration: BoxDecoration(
              //     color: Colors.white,
              //     borderRadius: BorderRadius.circular(20),
              //     border: Border.all(
              //       color: Colors.black,
              //     ),
              //     boxShadow: const [
              //       BoxShadow(
              //         color: Colors.grey,
              //         blurRadius: 10.0,
              //         offset: Offset(1, 3),
              //       ),
              //     ],
              //   ),
              //   child: Row(
              //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //     children: [
              //       Container(
              //         decoration: BoxDecoration(
              //             borderRadius: BorderRadius.circular(20)),
              //         child: (urlgambar != null && _image == null)
              //             ? Image.network(
              //                 urlgambar,
              //                 height: 200,
              //                 width: 200,
              //                 errorBuilder: (context, error, stackTrace) {
              //                   return const Icon(Icons.broken_image,
              //                       size: 50, color: Colors.grey);
              //                 },
              //                 loadingBuilder:
              //                     (context, child, loadingProgress) {
              //                   if (loadingProgress == null) return child;
              //                   return const CircularProgressIndicator();
              //                 },
              //               )
              //             : (_image != null)
              //                 ? Image.file(
              //                     _image!,
              //                     height: 200,
              //                     width: 200,
              //                   )
              //                 : const Text(
              //                     "Foto Kandang",
              //                     style: TextStyle(
              //                         fontSize: 18, color: Colors.grey),
              //                   ),
              //       ),
              //       ElevatedButton(
              //         style: ElevatedButton.styleFrom(
              //           backgroundColor:
              //               const Color.fromRGBO(48, 130, 148, 0.45),
              //         ),
              //         onPressed: () => _showPicker(context),
              //         child: const Text(
              //           "upload",
              //           style: TextStyle(fontWeight: FontWeight.bold),
              //         ),
              //       )
              //     ],
              //   ),
              // ),
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
                      child: const Text(
                        "Blok Kandang",
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromRGBO(48, 130, 148, 0.45),
                      ),
                      onPressed: () => _showAddBlok(context),
                      child: const Text(
                        "Buat",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Column(
                children: blok
                    .map((e) => Card(
                          child: ListTile(
                            title: Row(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    "Blok: ${e["nama"] ?? ""}",
                                    style: const TextStyle(
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    "Kapasitas: ${e["kapasitas"] ?? ""}",
                                    style: const TextStyle(
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                ),
                              ],
                            ),
                            trailing: GestureDetector(
                              child: const Icon(Icons.delete),
                              onTap: () {
                                showDialog(
                                  context:
                                      context, // <- pastikan context ini adalah context milik Scaffold
                                  builder: (BuildContext dialogContext) {
                                    return AlertDialog(
                                      title: const Text("Konfirmasi"),
                                      content: const Text(
                                          "Apakah kamu yakin ingin menghapus blok ini?"),
                                      actions: [
                                        TextButton(
                                          child: const Text("Batal"),
                                          onPressed: () {
                                            Navigator.of(dialogContext).pop();
                                          },
                                        ),
                                        TextButton(
                                          child: const Text("Hapus",
                                              style:
                                                  TextStyle(color: Colors.red)),
                                          onPressed: () {
                                            setState(() {
                                              blok.remove(e);
                                            });
                                            Navigator.of(dialogContext).pop();
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ))
                    .toList(),
              ),

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
                        _editCage(context);
                      }
                    },
                    child: const Text(
                      'Edit Kandang',
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
