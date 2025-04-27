import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ternak/cage_add.dart';
import 'package:ternak/components/tile_cage.dart';

class CageMenu extends StatefulWidget {
  final User user;
  const CageMenu({super.key, required this.user});

  @override
  State<CageMenu> createState() => _CageMenuState();
}

class _CageMenuState extends State<CageMenu> {
  // int countList = 0;
  String searchQuery = "";
  String filterCategory = "";

  //
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      _getListCage() async {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection("kandang")
        .where("user_uid", isEqualTo: widget.user.uid);

    if (searchQuery.isNotEmpty) {
      query = query
          .where("nama_lower",
              isGreaterThanOrEqualTo: searchQuery.toLowerCase())
          .where("nama_lower",
              isLessThan: '${searchQuery.toLowerCase()}\uf8ff');
    }

    if (filterCategory.isNotEmpty) {
      query = query.where("kategori", isEqualTo: filterCategory);
    }

    final snapshot = await query.get();
    return snapshot.docs;
  }

  @override
  void initState() {
    super.initState();
    // refresh();
  }

  // refresh() {
  //   // setState(() {});
  //   Query<Map<String, dynamic>> query = FirebaseFirestore.instance
  //       .collection("kandang")
  //       .where("user_uid", isEqualTo: widget.user.uid);

  //   if (searchQuery.isNotEmpty) {
  //     query = query
  //         .where("nama_lower",
  //             isGreaterThanOrEqualTo: searchQuery.toLowerCase())
  //         .where("nama_lower",
  //             isLessThan: '${searchQuery.toLowerCase()}\uf8ff');
  //   }

  //   if (filterCategory.isNotEmpty) {
  //     query = query.where("kategori", isEqualTo: filterCategory);
  //   }

  //   query.get().then((value) {
  //     setState(() {
  //       countList = value.size;
  //     });
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(29, 145, 170, 0.5),
        title: const Text(
          "Kandang",
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CageAdd(
                  //mengarah kehalaman
                  user: widget.user,
                ),
              )).then((value) => setState(() {}));
        },
        child: const Icon(Icons.add),
      ),
      body: Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Cari Kandang",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() => searchQuery = value);
                      // refresh();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    setState(() => filterCategory = value);
                    // refresh();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: "", child: Text("Semua")),
                    const PopupMenuItem(
                        value: "Penggemukan", child: Text("Penggemukan")),
                    const PopupMenuItem(
                        value: "Pembiakan", child: Text("Pembiakan")),
                  ],
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.filter_list),
                    label: const Text("Filter"),
                    onPressed: null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
                flex: 9,
                child: FutureBuilder<
                    List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
                  future: _getListCage(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return const Center(child: Text("Terjadi kesalahan"));
                    } else {
                      final docs = snapshot.data ?? [];

                      // Filter nama secara lokal (case-insensitive)
                      final filteredDocs = docs.where((doc) {
                        final data = doc.data();
                        final nama =
                            data["nama"]?.toString().toLowerCase() ?? "";
                        return nama.contains(searchQuery.toLowerCase());
                      }).toList();

                      final listData = filteredDocs.map((e) {
                        return FutureBuilder(
                          future: FirebaseFirestore.instance
                              .collection("hewan")
                              .where("kandang_id", isEqualTo: e.id)
                              .count()
                              .get(),
                          builder: (context, snap) {
                            if (snap.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }

                            final total = snap.data?.count ?? 0;
                            return TileCage(
                              user: widget.user,
                              refresh: () => setState(() {
                                print("SIP");
                              }),
                              doc: e,
                              total: total.toString(),
                            );
                          },
                        );
                      }).toList();

                      return ListView(children: listData);
                    }
                  },
                )

                // ).toList(),

                // return ListView(
                //   children: listData,
                // );
                //     }
                //   },
                // ),
                ),
          ],
        ),
      ),
    );
  }
}
