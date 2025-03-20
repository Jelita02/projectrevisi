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

  Future<QuerySnapshot<Map<String, dynamic>>> _getListAnimal() {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection("hewan")
        .where("user_uid", isEqualTo: widget.user.uid);
    
    if (searchQuery.isNotEmpty) {
      query = query.where("nama", isGreaterThanOrEqualTo: searchQuery)
                   .where("nama", isLessThanOrEqualTo: searchQuery + '\uf8ff');
    }
    
    if (filterCategory.isNotEmpty) {
      query = query.where("kategori", isEqualTo: filterCategory);
    }
    
    return query.get();
  }

  @override
  void initState() {
    super.initState();
    refresh();
  }

  refresh() {
    FirebaseFirestore.instance
        .collection("hewan")
        .where("user_uid", isEqualTo: widget.user.uid)
        .get()
        .then((value) => setState(() => countList = value.size));
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
                builder: (context) => AnimalAdd(
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
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() => searchQuery = value);
                    },
                  ),
                ),
                SizedBox(width: 10),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    setState(() => filterCategory = value);
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(value: "", child: Text("Semua")),
                    PopupMenuItem(value: "Penggemukan", child: Text("Penggemukan")),
                    PopupMenuItem(value: "Pemeliharaan", child: Text("Pemeliharaan")),
                  ],
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.filter_list),
                    label: Text("Filter"),
                    onPressed: null,
                  ),
                ),
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
              child: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                future: _getListAnimal(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  } else {
                    List<Widget> listData = [];
                    if (snapshot.data != null) {
                      listData = snapshot.data!.docs
                          .map(
                            (e) => TileAnimal(
                              doc: e,
                              refresh: refresh,
                              isForHealthy: widget.isForHealthy,
                            ),
                          )
                          .toList();
                    }
                    return ListView(children: listData);
                  }
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
