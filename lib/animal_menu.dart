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

@override
List<Widget> buildActions(BuildContext context) {
  return [
    IconButton(
      icon: const Icon(Icons.clear),
      onPressed: () {
        // query = '';
      },
    ),
  ];
}

// @override
// List<Widget> buildSuggestions (BuildContext context) {
//   List<string> matchQuery = [];
// for (var animal in searchTerms) {
//   if(animal.toLowerCase().contains(query.toLowerCase())){
//     matchQuery.add(animal);
//   }
// }
// return ListView.builder(
//   itemCount: matchQuery.length,
//   itemBuilder: (context, index) {
//     var result = matchQuery [index];
//     return ListTile(
//     title : Text(result),
//     );
//   },
// );
// }
// }

class _MenuAnimalState extends State<MenuAnimal> {
  int countList = 0;
  bool isSearching = false;
  TextEditingController searchController = TextEditingController();

  Future<QuerySnapshot<Map<String, dynamic>>> _getListAnimal() {
    return FirebaseFirestore.instance
        .collection("hewan")
        .where("user_uid", isEqualTo: widget.user.uid)
        .get();
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
        actions: [
          // IconButton(
          // onPressed: () {
          // showSearch(
          //   context: context,
          //   // delegate: CustomSearchDelegate(),);

          //   },
          // icon: const Icon(
          //   Icons.search, // Ganti ikon jadi Search
          //     size: 34, // Ukuran bisa disesuaikan
          //     color: Color.fromRGBO(26, 107, 125, 1), // Warna tetap sama
          //   ),
          // ),
        ],
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
        padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(7),
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.filter_list_alt),
                    label: const Text("Filter"),
                    onPressed: () {
                      print("filter");
                    },
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.sort),
                    label: const Text("Urutkan"),
                    onPressed: () {
                      print("filter");
                    },
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.keyboard_arrow_down),
                    label: const Text("Kondisi Hewan"),
                    onPressed: () {
                      print("filter");
                    },
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.keyboard_arrow_down),
                    label: const Text("Kandang"),
                    onPressed: () {
                      print("filter");
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              flex: 9,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$countList Hewan",
                      style: const TextStyle(
                        color: Color.fromRGBO(0, 0, 0, 0.5),
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                        child:
                            FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      future: _getListAnimal(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        } else {
                          List<Widget> listData = List.empty();
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

                          return ListView(
                            children: listData,
                          );
                        }
                      },
                    ))
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
