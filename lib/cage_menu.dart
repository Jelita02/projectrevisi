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
  int countList = 0;
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
    query = query.orderBy("nama_lower");

    final snapshot = await query.get();
    return snapshot.docs;
  }

  @override
  void initState() {
    super.initState();
    refresh();
  }

  refresh() {
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

    query.get().then((value) {
      setState(() {
        countList = value.size;
      });
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
          "Daftar Kandang",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  "$countList Kandang",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold, 
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1D91AA),
        elevation: 4,
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
              )).then((value) => refresh());
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Cari kandang...",
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF1D91AA)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onChanged: (value) {
                        setState(() => searchQuery = value);
                        refresh();
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                PopupMenuButton<String>(
                  offset: const Offset(0, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (value) {
                    setState(() => filterCategory = value);
                    refresh();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: "", 
                      child: Text("Semua Kategori", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const PopupMenuItem(
                      value: "Penggemukan", 
                      child: Row(
                        children: [
                          // Icon(Icons.trending_up, color: Colors.orange, size: 18),
                          SizedBox(width: 8),
                          Text("Penggemukan"),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: "Pembiakan", 
                      child: Row(
                        children: [
                          // Icon(Icons.pets, color: Color(0xFF1D91AA), size: 18),
                          SizedBox(width: 8),
                          Text("Pembiakan"),
                        ],
                      ),
                    ),
                  ],
                  child: Container(
                    height: 46,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D91AA),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.filter_list, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          filterCategory.isEmpty 
                              ? "Filter" 
                              : filterCategory,
                          style: const TextStyle(
                            color: Colors.white,
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
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: FutureBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
                future: _getListCage(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF1D91AA),
                      )
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                          const SizedBox(height: 16),
                          const Text(
                            "Terjadi kesalahan",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Tidak dapat memuat data kandang",
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    );
                  } else {
                    final docs = snapshot.data ?? [];

                    // Filter nama secara lokal (case-insensitive)
                    final filteredDocs = docs.where((doc) {
                      final data = doc.data();
                      final nama = data["nama"]?.toString().toLowerCase() ?? "";
                      return nama.contains(searchQuery.toLowerCase());
                    }).toList();

                    if (filteredDocs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              "assets/images/empty.png",
                              width: 120,
                              height: 120,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => Icon(
                                Icons.home_outlined,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              "Belum ada data kandang",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              searchQuery.isNotEmpty || filterCategory.isNotEmpty
                                  ? "Coba ubah kata kunci atau filter"
                                  : "Tambahkan data kandang dengan tombol + di bawah",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final listData = filteredDocs.map((e) {
                      return FutureBuilder(
                        future: FirebaseFirestore.instance
                            .collection("hewan")
                            .where("kandang_id", isEqualTo: e.id)
                            .count()
                            .get(),
                        builder: (context, snap) {
                          if (snap.connectionState == ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Center(
                                child: SizedBox(
                                  height: 120,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF1D91AA),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }

                          final total = snap.data?.count ?? 0;
                          return TileCage(
                            user: widget.user,
                            refresh: () => refresh(),
                            doc: e,
                            total: total.toString(),
                          );
                        },
                      );
                    }).toList();

                    return ListView(
                      padding: const EdgeInsets.only(top: 16, bottom: 80),
                      children: listData,
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
