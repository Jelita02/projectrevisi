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
  @override
  void initState() {
    super.initState();
    // refresh();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _getListCage() {
    return FirebaseFirestore.instance
        .collection("kandang")
        .where("user_uid", isEqualTo: widget.user.uid)
        .get();
  }

  // refresh() {
  //   FirebaseFirestore.instance
  //       .collection("kandang")
  //       .where("user_uid", isEqualTo: widget.user.uid)
  //       .get();
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
                  user: widget.user,
                ),
              )).then((value) => setState(() {}));
        },
        child: const Icon(Icons.add),
      ),
      body: Container(
        padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 1,
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
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              flex: 9,
              child: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                future: _getListCage(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  } else {
                    List<Widget> listData = List.empty();
                    if (snapshot.data != null) {
                      listData = snapshot.data!.docs.map(
                        (e) {
                          return FutureBuilder(
                              future: FirebaseFirestore.instance
                                  .collection("hewan")
                                  .where("kandang_id", isEqualTo: e.id)
                                  .count()
                                  .get(),
                              builder: (context, snap) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                  );
                                }

                                var stringTotal = "0";
                                var total = snap.data?.count;
                                if (total != null) {
                                  stringTotal = total.toString();
                                }

                                return TileCage(
                                  doc: e,
                                  total: stringTotal,
                                );
                              });
                        },
                      ).toList();
                    }

                    return ListView(
                      children: listData,
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
