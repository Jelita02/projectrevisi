import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fire;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';

class CageAdd extends StatefulWidget {
  final fire.User user;
  const CageAdd({super.key, required this.user});

  @override
  State<CageAdd> createState() => _CageAddState();
}

class _CageAddState extends State<CageAdd> {
  final _formKey = GlobalKey<FormState>();
  bool _imageError = false; // tambahkan di state
  File? _image;

  late String _kategori;
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _kapasitasController = TextEditingController();


  List<Map<String, dynamic>> blok = [];

  final picker = ImagePicker();

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

  void _addCage() {
    kandang.add({
      "user_uid": widget.user.uid,
      "nama": _namaController.text,
      "kapasitas": _kapasitasController.text,
      "kategori": _kategori,
    }).then((value) {
      if (_image != null) {
        // Ambil ekstensi file asli
        String extension = path.extension(_image!.path);

        // Buat nama file unik dengan UUID
        String fileName = '${value.id}$extension';
        Supabase.instance.client.storage
            .from('terdom') // Ganti dengan nama bucket
            .upload('kandang/$fileName', _image!)
            .then((data) {
          kandang.doc(value.id).update({
            "image": fileName,
          });
        }).catchError((error) => {print("ERRORRR: $error")});
      }

      int kapasitasKandang = 0;
      for (var v in blok) {
        kapasitasKandang += int.parse(v["kapasitas_blok"] ?? 0);
        blokStore.add({
          "user_uid": widget.user.uid,
          "kandang_id": value.id,
          "nama": v["nama_blok"] ?? "",
          "kapasitas": v["kapasitas_wblok"] ?? "",
          

        });
      }

      kandang.doc(value.id).update({
        "kapasitas": kapasitasKandang.toString()
      });

      Navigator.pop(context, true);
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
                onTap: () 
                async {
                await _getImage(ImageSource.gallery);
                setState(() {
                  _imageError = _image == null; // update error state
                });
                Navigator.of(context).pop();
              },
                // {
                //   _getImage(ImageSource.gallery);
                //   Navigator.of(context).pop();
                // },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () async {
                await _getImage(ImageSource.gallery);
                setState(() {
                  _imageError = _image == null; // update error state
                });
                Navigator.of(context).pop();
              },
                // {
                //   _getImage(ImageSource.camera);
                //   Navigator.of(context).pop();
                // },
              ),
            ],
          ),
        );
      },
    );
  }

  // void _showAddBlok(context) {
  //   final blokKey = GlobalKey<FormState>();
  //   final TextEditingController namaBlokController = TextEditingController();
  //   final TextEditingController kapasitasBlokController =
  //       TextEditingController();

  //   showModalBottomSheet(
  //      isScrollControlled: true, // penting untuk menghindari tertutup keyboad
  //     context: context,
  //     builder: (BuildContext bc) {
  //       return SafeArea(
  //         child: Container(
  //           padding: const EdgeInsets.all(20),
  //           child: Form(
  //             key: blokKey,
  //             child: Wrap(
  //               children: <Widget>[
  //                 Row(
  //                   children: [
  //                     Expanded(
  //                       child: Padding(
  //                         padding: const EdgeInsets.all(10),
  //                         child: TextFormField(
  //                           controller: namaBlokController,
  //                           maxLength: 20, //permintaan dari gumukmas
  //                           decoration: const InputDecoration(
  //                             labelText: 'Nama',
  //                           ),
  //                           keyboardType: TextInputType.name,
  //                           validator: (value) {
  //                             if (value == null || value.isEmpty) {
  //                               return "Masukan nama";
  //                             }

  //                             return null;
  //                           },
  //                         ),
  //                       ),
  //                     ),
  //                     Expanded(
  //                       child: Padding(
  //                         padding: const EdgeInsets.all(10),
  //                         child: TextFormField(
  //                           controller: kapasitasBlokController,
  //                           decoration: const InputDecoration(
  //                             labelText: 'Kapasitas',
  //                           ),
  //                           keyboardType: TextInputType.number,
  //                           validator: (value) {
  //                             if (value == null || value.isEmpty) {
  //                               return "Masukan kapasitas";
  //                             }

  //                             return null;
  //                           },
  //                         ),
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //                 Center(
  //                   child: SizedBox(
  //                     width: double.infinity,
  //                     child: ElevatedButton(
  //                       style: ElevatedButton.styleFrom(
  //                         backgroundColor:
  //                             const Color.fromRGBO(26, 107, 125, 1),
  //                       ),
  //                       onPressed: () {
  //                         if (blokKey.currentState?.validate() == true) {
  //                           setState(() {
  //                             blok.add({
  //                               "nama_blok": namaBlokController.text,
  //                               "kapasitas_blok": kapasitasBlokController.text,
  //                             });

  //                             Navigator.of(context).pop();
  //                           });
  //                         }
  //                       },
  //                       child: const Text(
  //                         'Tambah Blok',
  //                         style: TextStyle(
  //                           color: Colors.white,
  //                           fontSize: 20,
  //                         ),
  //                       ),
  //                     ),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }
  void _showAddBlok(context) {
  final blokKey = GlobalKey<FormState>();
  final TextEditingController namaBlokController = TextEditingController();
  final TextEditingController kapasitasBlokController = TextEditingController();

  showModalBottomSheet(
    isScrollControlled: true, // <- penting untuk menghindari tertutup keyboard
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
                    //   children: [
                    //     Expanded(
                    //       child: Padding(
                    //         padding: const EdgeInsets.all(10),
                    //         child: TextFormField(
                    //           controller: namaBlokController,
                    //           maxLength: 20,
                    //           decoration: const InputDecoration(
                    //             labelText: 'Nama',
                    //           ),
                    //           keyboardType: TextInputType.name,
                    //           validator: (value) {
                    //             if (value == null || value.isEmpty) {
                    //               return "Masukan nama";
                    //             }
                    //             return null;
                    //           },
                    //         ),
                    //       ),
                    //     ),
                    //     Expanded(
                    //       child: Padding(
                    //         padding: const EdgeInsets.all(10),
                    //         child: TextFormField(
                    //           controller: kapasitasBlokController,
                    //           decoration: const InputDecoration(
                    //             labelText: 'Kapasitas',
                    //           ),
                    //           keyboardType: TextInputType.number,
                    //           validator: (value) {
                    //             if (value == null || value.isEmpty) {
                    //               return "Masukan kapasitas";
                    //             }
                    //             return null;
                    //           },
                    //         ),
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    
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
            contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
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
            contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
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
                                "nama_blok": namaBlokController.text,
                                "kapasitas_blok": kapasitasBlokController.text,
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(29, 145, 170, 0.5),
        title: const Text(
          "Buat Kandang",
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
                items: <String>['Pembiakan', 'Penggemukan',]
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
                      child: (_image == null)
                          ? const Text(
                              "Foto Kandang",
                              style:
                                  TextStyle(fontSize: 18, color: Colors.grey),
                            )
                          : Image.file(
                              _image!,
                              height: 200,
                              width: 200,
                            ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromRGBO(48, 130, 148, 0.45),
                      ),
                      onPressed: () => _showPicker(context),
                      child: const Text(
                        "Pilih",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    )
                  ],
                ),
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
                                    // ignore: prefer_interpolation_to_compose_strings
                                    "Blok: " + (e["nama_blok"] ?? ""),
                                    style: const TextStyle(
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    // ignore: prefer_interpolation_to_compose_strings
                                    "Kapasitas: " + (e["kapasitas_blok"] ?? ""),
                                    style: const TextStyle(
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                ),
                              ],
                            ),
                            trailing: GestureDetector(
                              child: const Icon(Icons.delete),
                              onTap: () {
                                setState(() {
                                  blok.remove(e);
                                });
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
                      if (blok.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Minimal 1 blok harus ditambahkan')),
                          );
                          return;
                        }
                        _addCage();
                      }
                    },
                    child: const Text(
                      'Buat Kandang',
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
