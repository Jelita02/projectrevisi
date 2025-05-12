import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BlockDetail extends StatefulWidget {
  final String kandangId;
  final String totalBlok;
  final String total;
  const BlockDetail({
    super.key,
    required this.kandangId,
    required this.total,
    required this.totalBlok,
  });

  @override
  State<BlockDetail> createState() => _BlockDetailState();
}

class _BlockDetailState extends State<BlockDetail> {
  Future<QuerySnapshot<Map<String, dynamic>>> _getBlok() async {
    return FirebaseFirestore.instance
        .collection("blok")
        .where("kandang_id", isEqualTo: widget.kandangId)
        .get();
  }

  Future<int> _getJumlahHewanInBlok(String blokId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('hewan')
        .where('blok_id', isEqualTo: blokId)
        .get();
    return snapshot.size;
  }

  void _showEditBlok(
      context, QueryDocumentSnapshot<Map<String, dynamic>> blok) {
    final blokKey = GlobalKey<FormState>();
    final int kapasitasBlokLama = int.tryParse(blok.data()["kapasitas"]) ?? 0;
    final TextEditingController namaBlokController =
        TextEditingController(text: blok.data()["nama"] ?? "");
    final TextEditingController kapasitasBlokController =
        TextEditingController(text: blok.data()["kapasitas"] ?? "");
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(bc).viewInsets.bottom,
              top: 20,
              left: 20,
              right: 20,
            ),
            child: SingleChildScrollView(
              child: Form(
                key: blokKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                            FirebaseFirestore.instance
                                .collection("blok")
                                .doc(blok.id)
                                .update({
                              "nama": namaBlokController.text,
                              "kapasitas": kapasitasBlokController.text,
                            }).then((value) {
                              final kandang = FirebaseFirestore.instance
                                  .collection('kandang')
                                  .doc(widget.kandangId);

                              kandang.get().then((value) {
                                int kapasitasKandang =
                                    int.tryParse(value["kapasitas"] ?? 0) ?? 0;
                                kapasitasKandang -= kapasitasBlokLama;
                                kapasitasKandang += (int.tryParse(
                                        kapasitasBlokController.text) ??
                                    0);
                                kandang.update({
                                  "kapasitas": kapasitasKandang.toString()
                                }).then((value) {
                                  setState(() {
                                    Navigator.of(context).pop();
                                  });
                                });
                              });
                            });
                          }
                        },
                        child: const Text(
                          'Edit Blok',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
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
          "Detail Blok",
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back), // <- back icon
          onPressed: () {
            FirebaseFirestore.instance
                .collection('kandang')
                .doc(widget.kandangId)
                .get()
                .then((value) {
              Navigator.pop(context, value);
            });
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 200,
              width: double.infinity,
              color: const Color.fromRGBO(29, 145, 170, 0.75),
              child: Image.asset(
                "assets/images/icon-block.png",
                fit: BoxFit.fill,
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -70),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(20),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.grey,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Total Blok"),
                            Text("Total Terisi"),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "${widget.totalBlok} Blok",
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text("${widget.total} Ekor"),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Text("Detail Blok"),
                  SizedBox(
                    width: double.infinity,
                    // height: double.infinity,
                    child: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      future: _getBlok(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        return Column(
                          children: snapshot.data!.docs.map((e) {
                            return Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.grey,
                                ),
                              ),
                              child: Row(
                                //   children: [
                                //     Expanded(
                                //       flex: 4,
                                //       child: ListTile(
                                //         contentPadding: const EdgeInsets.all(0),
                                //         horizontalTitleGap: 1,
                                //         title: Text(
                                //           e.data()["nama"] ?? "",
                                //           style: const TextStyle(fontSize: 14),
                                //         ),
                                //         subtitle: Text(
                                //           // ignore: prefer_interpolation_to_compose_strings
                                //           "Kapasitas " +
                                //               e.data()["kapasitas"] +
                                //               " Ekor",
                                //           style: const TextStyle(
                                //               fontSize: 14,
                                //               fontWeight: FontWeight.w900),
                                //         ),
                                //         leading: Image.asset(
                                //           "assets/images/icon-block.png",
                                //           fit: BoxFit.fill,
                                //           height: 40,
                                //         ),
                                //       ),
                                //     ),
                                //     Expanded(
                                //       child: GestureDetector(
                                //         onTap: () {
                                //           _showEditBlok(context, e);
                                //         },
                                //         child: const Icon(Icons.edit),
                                //       ),
                                //     ),
                                //   ],
                                // ),
                                children: [
                                  Expanded(
                                    flex: 4,
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.all(0),
                                      horizontalTitleGap: 1,
                                      title: Text(
                                        e.data()["nama"] ?? "",
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      subtitle: FutureBuilder<int>(
                                        future: _getJumlahHewanInBlok(e.id),
                                        builder: (context, snapshotJumlah) {
                                          if (snapshotJumlah.connectionState ==
                                              ConnectionState.waiting) {
                                            return const Text("Menghitung...");
                                          }
                                          return Text(
                                            "Kapasitas ${e.data()["kapasitas"]} Ekor\nTerisi ${snapshotJumlah.data ?? 0} Ekor",
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          );
                                        },
                                      ),
                                      leading: Image.asset(
                                        "assets/images/icon-block.png",
                                        fit: BoxFit.fill,
                                        height: 40,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        _showEditBlok(context, e);
                                      },
                                      child: const Icon(Icons.edit),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
