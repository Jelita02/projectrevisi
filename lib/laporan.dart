import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ternak/components/colors.dart';
import 'package:ternak/detail_laporan.dart';

class LaporanScreen extends StatefulWidget {
  final User user;
  const LaporanScreen({super.key, required this.user});

  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen> {
  late DateTimeRange selectedRange;
  bool _isProcessing = false;

  int totalDomba = 0;
  int totalMale = 0;
  int totalFemale = 0;
  int totalSick = 0;
  int totalPembiakan = 0;
  int totalPenggemukan = 0;
  int totalSakit = 0;
  int totalHidup = 0;
  int totalMati = 0;
  int totalTerjual = 0;

  Future<void> pickDateRange() async {
    DateTimeRange? picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
        initialDateRange: selectedRange,
        locale: const Locale("id", "ID"));
    _isProcessing = false;

    if (picked != null) {
      setState(() {
        selectedRange = picked;
      });
      getDate();
    }
  }

  Future<void> getDate() async {
    FirebaseFirestore.instance
        .collection("hewan")
        .where("user_uid", isEqualTo: widget.user.uid)
        .where('tanggal_masuk',
            isGreaterThanOrEqualTo: DateFormat('yyyy-MM-dd')
                .format(selectedRange.start)) // >= 1 Mei 2024
        .where('tanggal_masuk',
            isLessThanOrEqualTo: DateFormat('yyyy-MM-dd')
                .format(selectedRange.end)) // <= 10 Mei 2024
        .get()
        .then((value) {
      var list = value.docs.toList();
      setState(() {
        totalDomba = value.size;
        totalMale = list
            .where((element) =>
                element.data()["jenis_kelamin"] == "Jantan" &&
                element.data()["status"] == "Hidup")
            .length;
        totalFemale = list
            .where((element) =>
                element.data()["jenis_kelamin"] == "Betina" &&
                element.data()["status"] == "Hidup")
            .length;
        totalSick = list
            .where((element) =>
                element.data()["status_kesehatan"] == "Sakit" &&
                element.data()["status"] == "Hidup")
            .length;
        totalPembiakan = list
            .where((element) =>
                element.data()["kategori"] == "Pembiakan" &&
                element.data()["status"] == "Hidup")
            .length;
        totalPenggemukan = list
            .where((element) =>
                element.data()["kategori"] == "Penggemukan" &&
                element.data()["status"] == "Hidup")
            .length;
        totalHidup =
            list.where((element) => element.data()["status"] == "Hidup").length;
        totalMati =
            list.where((element) => element.data()["status"] == "Mati").length;
        totalTerjual = list
            .where((element) => element.data()["status"] == "Terjual")
            .length;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    // Set default range: hari ini sebagai start dan end
    DateTime today = DateTime.now();
    selectedRange = DateTimeRange(start: today, end: today);
    getDate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Laporan",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: MyColors.primaryC,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header with date selector
          Container(
            color: MyColors.primaryC,
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(15, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Ringkasan Data Peternakan",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () {
                    setState(() {
                      _isProcessing = true;
                    });
                    pickDateRange();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            "${DateFormat('dd MMMM yyyy', 'id_ID').format(selectedRange.start)} - ${DateFormat('dd MMMM yyyy', 'id_ID').format(selectedRange.end)}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_isProcessing) ...[
                          const SizedBox(width: 8),
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Curved transition
          Container(
            height: 20,
            decoration: const BoxDecoration(
              color: MyColors.primaryC,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
          ),

          // Statistics
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Total sheep card
                _buildStatCard(
                  icon: Icons.pets,
                  title: "Total Domba",
                  value: "$totalDomba",
                  subtitle: "Ekor",
                  color: Colors.blue,
                ),

                const SizedBox(height: 16),

                // Gender section
                _buildGenderSection(),

                const SizedBox(height: 16),

                // Health section
                _buildStatCard(
                  icon: Icons.health_and_safety,
                  title: "Kasus Sakit",
                  value: "$totalSick",
                  subtitle: "Kasus",
                  color: Colors.orange,
                ),

                const SizedBox(height: 16),

                // Category section
                _buildCategorySection(),

                const SizedBox(height: 16),

                // Status section
                _buildStatusSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // Container(
                //   padding: const EdgeInsets.all(10),
                //   decoration: BoxDecoration(
                //     color: Colors.purple.withOpacity(0.1),
                //     borderRadius: BorderRadius.circular(10),
                //   ),
                //   child: const Icon(
                //     Icons.wc,
                //     color: Colors.purple,
                //     size: 24,
                //   ),
                // ),
                SizedBox(width: 12),
                Text(
                  "Jenis Kelamin",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Male
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.male,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Jantan",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: totalMale /
                            (totalMale + totalFemale > 0
                                ? totalMale + totalFemale
                                : 1),
                        backgroundColor: Colors.grey[200],
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.blue),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  "$totalMale",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  "Ekor",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Female
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.pink.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.female,
                    color: Colors.pink,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Betina",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: totalFemale /
                            (totalMale + totalFemale > 0
                                ? totalMale + totalFemale
                                : 1),
                        backgroundColor: Colors.grey[200],
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.pink),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  "$totalFemale",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.pink,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  "Ekor",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // Container(
                //   padding: const EdgeInsets.all(10),
                //   decoration: BoxDecoration(
                //     color: Colors.green.withOpacity(0.1),
                //     borderRadius: BorderRadius.circular(10),
                //   ),
                //   // child: const Icon(
                //   //   Icons.category,
                //   //   color: Colors.green,
                //   //   size: 24,
                //   // ),
                // ),
                SizedBox(width: 12),
                Text(
                  "Kategori",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Breeding
          _buildCategoryRow(
              title: "Pembiakan",
              value: totalPembiakan,
              total: totalPembiakan + totalPenggemukan > 0
                  ? totalPembiakan + totalPenggemukan
                  : 1,
              color: Colors.teal),

          // Fattening
          _buildCategoryRow(
              title: "Penggemukan",
              value: totalPenggemukan,
              total: totalPembiakan + totalPenggemukan > 0
                  ? totalPembiakan + totalPenggemukan
                  : 1,
              color: Colors.amber,
              isLast: true),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(
      {required String title,
      required int value,
      required int total,
      required Color color,
      bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, isLast ? 16 : 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                "$value",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                "Ekor",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              Container(
                height: 8,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              FractionallySizedBox(
                widthFactor: value / total,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // Container(
                //   padding: const EdgeInsets.all(10),
                //   decoration: BoxDecoration(
                //     color: MyColors.primaryC.withOpacity(0.1),
                //     borderRadius: BorderRadius.circular(10),
                //   ),
                //   // child: const Icon(
                //   //   Icons.info,
                //   //   color: MyColors.primaryC,
                //   //   size: 24,
                //   // ),
                // ),
                SizedBox(width: 12),
                Text(
                  "Status",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatusButton(
                    status: "Hidup",
                    count: totalHidup,
                    color: Colors.green,
                    icon: Icons.favorite,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatusButton(
                    status: "Mati",
                    count: totalMati,
                    color: Colors.red,
                    icon: Icons.dangerous,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatusButton(
                    status: "Terjual",
                    count: totalTerjual,
                    color: Colors.blue,
                    icon: Icons.attach_money,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusButton({
    required String status,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailLaporanScreen(
                user: widget.user,
                selectedRange: selectedRange,
                status: status,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.3),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                status,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "$count Ekor",
                style: const TextStyle(
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
