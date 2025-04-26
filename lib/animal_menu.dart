import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ternak/animal_add.dart';
import 'package:ternak/components/tile_animal.dart';

class MenuAnimal extends StatefulWidget {
  final User user;
  final bool isForHealthy;
  const MenuAnimal({super.key, required this.user, this.isForHealthy = false});

  @override
  State<MenuAnimal> createState() => _MenuAnimalState();
}

class _MenuAnimalState extends State<MenuAnimal> {
  int countList = 0;
  String searchQuery = "";
  String filterCategory = "";
  // String filterkondisi = "";

  // Future<QuerySnapshot<Map<String, dynamic>>> _getListAnimal() {
  //   Query<Map<String, dynamic>> query = FirebaseFirestore.instance
  //       .collection("hewan")
  //       .where("user_uid", isEqualTo: widget.user.uid)
  //       .orderBy("nama");
  //   if (searchQuery.isNotEmpty) {
  //     query = query
  //         .where("nama_lower", isGreaterThanOrEqualTo: searchQuery)
  //         .where("nama_lower", isLessThan: '$searchQuery\uf8ff');
  //   }

  //   if (filterCategory.isNotEmpty) {
  //     query = query.where("kategori", isEqualTo: filterCategory);
  //   }
    // if (filterkondisi.isNotEmpty) {
    //   query = query.where("status_kesehatan", isEqualTo: filterkondisi);
    // }

  //   return query.get();
  // }
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _getListAnimal() async {
  Query<Map<String, dynamic>> query = FirebaseFirestore.instance
      .collection("hewan")
      .where("user_uid", isEqualTo: widget.user.uid);

  if (filterCategory.isNotEmpty) {
    query = query.where("kategori", isEqualTo: filterCategory);
  }

  final snapshot = await query.get();
  return snapshot.docs;
}


  @override
  void initState() {
    super.initState();
    refresh();
  }

  refresh() {
    // FirebaseFirestore.instance
    //     .collection("hewan")
    //     .where("user_uid", isEqualTo: widget.user.uid)
    //     .get()
    //     .then((value) => setState(() => countList = value.size));

  Query<Map<String, dynamic>> query = FirebaseFirestore.instance
      .collection("hewan")
      .where("user_uid", isEqualTo: widget.user.uid);

  if (searchQuery.isNotEmpty) {
    query = query
        .where("nama_lower", isGreaterThanOrEqualTo: searchQuery)
        .where("nama_lower", isLessThan: '$searchQuery\uf8ff');
  }

  if (filterCategory.isNotEmpty) {
    query = query.where("kategori", isEqualTo: filterCategory);
  }

  // if (filterkondisi.isNotEmpty) {
  //   query = query.where("status_kesehatan", isEqualTo: filterkondisi);
  // }

  query.get().then((value) {
    setState(() {
      countList = value.size;
    });
  });
}

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(29, 145, 170, 0.5),
        title: const Text(
          "Daftar Semua Hewan",
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
                builder: (context) => AnimalAdd(//mengarah kehalaman animal add
                  user: widget.user,
                ),
              )).then((value) => refresh());
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
                      hintText: "Cari hewan",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() => searchQuery = value);
                      
                    },
                  ),
                ),
                const SizedBox(width: 10),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    setState(() => filterCategory = value);
                     refresh(); 
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
                    label: const Text("Kategori"),
                    onPressed:
                        null, // tambahkan fungsi kosong agar tombol aktif
                  ),
                ),
                // const SizedBox(width: 10),
                // PopupMenuButton<String>(
                //   onSelected: (value) {
                //     setState(() => filterkondisi = value);
                //     refresh(); 
                //   },
                //   itemBuilder: (context) => [
                //     const PopupMenuItem(value: "", child: Text("Semua")),
                //     const PopupMenuItem(value: "Sehat", child: Text("Sehat")),
                //     const PopupMenuItem(value: "Sakit", child: Text("Sakit")),
                //   ],
                //   child: ElevatedButton.icon(
                //     icon: const Icon(Icons.filter_list),
                //     label: const Text("Kondisi"),
                //     onPressed:
                //         null, // tambahkan fungsi kosong agar tombol aktif
                //   ),
                // ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              "$countList Hewan",
              style: const TextStyle(
                color: Color.fromRGBO(0, 0, 0, 0.5),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 10),
                      Expanded(
            child: FutureBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
              future: _getListAnimal(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text("Terjadi kesalahan"));
                } else {
                  List<QueryDocumentSnapshot<Map<String, dynamic>>> docs = snapshot.data ?? [];

                  // 🔍 Filter lokal dengan toLowerCase()
                  final filteredDocs = docs.where((doc) {
                    final data = doc.data();
                    final nama = data["nama"]?.toString().toLowerCase() ?? "";
                    return nama.contains(searchQuery.toLowerCase());
                  }).toList();

                  countList = filteredDocs.length; // update jumlah hasil

                  return ListView(
                    children: filteredDocs.map((e) => TileAnimal(
                      user: widget.user,
                      doc: e,
                      refresh: refresh,
                      isForHealthy: widget.isForHealthy,
                    )).toList(),
                  );
                }
              },
            ),
          ),
            
          ],
        ),
      ),
    );
  }
}
