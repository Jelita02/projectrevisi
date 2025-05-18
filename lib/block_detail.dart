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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1D91AA).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit, color: Color(0xFF1D91AA)),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "Edit Blok",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: namaBlokController,
                            maxLength: 20,
                            decoration: InputDecoration(
                              labelText: 'Nama Blok',
                              hintText: 'Masukkan nama blok',
                              isDense: true,
                              filled: true,
                              fillColor: Colors.grey[100],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF1D91AA), width: 1),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 16, horizontal: 16),
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
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: kapasitasBlokController,
                            decoration: InputDecoration(
                              labelText: 'Kapasitas',
                              hintText: 'Jumlah kapasitas',
                              isDense: true,
                              filled: true,
                              fillColor: Colors.grey[100],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF1D91AA), width: 1),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 16, horizontal: 16),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Masukan kapasitas";
                              }
                              int? nilai = int.tryParse(value);
                              if (nilai != null) {
                                if (nilai <= 0 || nilai >= 15) {
                                  return "Input dari 1-15";
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1D91AA),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: const Size(double.infinity, 48),
                        elevation: 0,
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
                        'Simpan Perubahan',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D91AA),
        elevation: 0,
        title: const Text(
          "Detail Blok",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
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
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header image section
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF1D91AA),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      "assets/images/icon-block.png",
                      fit: BoxFit.cover,
                      opacity: const AlwaysStoppedAnimation(0.2),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(30),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 50,
                    left: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Informasi Blok",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 1),
                                blurRadius: 3.0,
                                color: Color.fromARGB(150, 0, 0, 0),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "${widget.totalBlok} Blok  •  ${widget.total} Ekor",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Summary card
            Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D91AA).withOpacity(0.05),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1D91AA).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.dashboard_rounded,
                            color: Color(0xFF1D91AA),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Ringkasan",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1D91AA),
                              ),
                            ),
                            Text(
                              "Informasi kapasitas kandang",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSummaryItem(
                          icon: Icons.dashboard_outlined,
                          iconColor: const Color(0xFF1D91AA),
                          title: "Total Blok",
                          value: "${widget.totalBlok} Blok",
                        ),
                        Container(
                          height: 40,
                          width: 1,
                          color: Colors.grey.withOpacity(0.3),
                        ),
                        _buildSummaryItem(
                          icon: Icons.pets_rounded,
                          iconColor: Colors.orange,
                          title: "Total Terisi",
                          value: "${widget.total} Ekor",
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Block list header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Detail Blok",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1D91AA),
                        ),
                      ),
                      Text(
                        "Daftar blok dalam kandang",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D91AA).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF1D91AA).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      "${widget.totalBlok} Blok",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF1D91AA),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Block list
            FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
              future: _getBlok(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(
                        color: Color(0xFF1D91AA),
                      ),
                    ),
                  );
                }
                
                if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.dashboard_customize,
                            size: 60,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Tidak ada blok",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final e = snapshot.data!.docs[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            spreadRadius: 0,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: InkWell(
                        onTap: () {
                          _showEditBlok(context, e);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1D91AA).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Image.asset(
                                  "assets/images/icon-block.png",
                                  height: 32,
                                  width: 32,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) => const Icon(
                                    Icons.dashboard_outlined,
                                    color: Color(0xFF1D91AA),
                                    size: 24,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            e.data()["nama"] ?? "",
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        // Container(
                                        //   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        //   decoration: BoxDecoration(
                                        //     color: const Color(0xFF1D91AA).withOpacity(0.1),
                                        //     borderRadius: BorderRadius.circular(20),
                                        //   ),
                                        //   child: const Row(
                                        //     mainAxisSize: MainAxisSize.min,
                                        //     children: [
                                        //       Icon(
                                        //         Icons.edit,
                                        //         size: 12,
                                        //         color: Color(0xFF1D91AA),
                                        //       ),
                                        //       SizedBox(width: 4),
                                        //       Text(
                                        //         "Edit",
                                        //         style: TextStyle(
                                        //           fontSize: 12,
                                        //           fontWeight: FontWeight.w600,
                                        //           color: Color(0xFF1D91AA),
                                        //         ),
                                        //       ),
                                        //     ],
                                        //   ),
                                        // ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    FutureBuilder<int>(
                                      future: _getJumlahHewanInBlok(e.id),
                                      builder: (context, snapshotJumlah) {
                                        if (snapshotJumlah.connectionState == ConnectionState.waiting) {
                                          return const Text(
                                            "Menghitung...",
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey,
                                            ),
                                          );
                                        }
                                        
                                        final totalHewan = snapshotJumlah.data ?? 0;
                                        final kapasitas = int.tryParse(e.data()["kapasitas"] ?? "0") ?? 0;
                                        
                                        return Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.pets,
                                                  size: 14,
                                                  color: Colors.grey[600],
                                                ),
                                                const SizedBox(width: 4),
                                                Flexible(
                                                  child: Text(
                                                    "Terisi: $totalHewan Ekor",
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.grey[800],
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.dashboard,
                                                  size: 14,
                                                  color: Colors.grey[600],
                                                ),
                                                const SizedBox(width: 4),
                                                Flexible(
                                                  child: Text(
                                                    "Kapasitas: $kapasitas Ekor",
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.grey[800],
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(10),
                                              child: LinearProgressIndicator(
                                                value: kapasitas > 0 ? totalHewan / kapasitas : 0,
                                                backgroundColor: Colors.grey[200],
                                                color: _getProgressColor(totalHewan, kapasitas),
                                                minHeight: 6,
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSummaryItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon, 
              color: iconColor, 
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getProgressColor(int current, int max) {
    if (max == 0) return Colors.grey;
    
    final ratio = current / max;
    if (ratio >= 0.9) {
      return Colors.red;
    } else if (ratio >= 0.7) {
      return Colors.orange;
    } else {
      return const Color(0xFF1D91AA);
    }
  }
}
