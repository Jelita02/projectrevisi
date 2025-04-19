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
            .where((element) => element.data()["jenis_kelamin"] == "Jantan")
            .length;
        totalFemale = list
            .where((element) => element.data()["jenis_kelamin"] == "Betina")
            .length;
        totalSick = list
            .where((element) => element.data()["status_kesehatan"] == "Sakit")
            .length;
        totalPembiakan = list
            .where((element) => element.data()["kategori"] == "Pembiakan")
            .length;
        totalPenggemukan = list
            .where((element) => element.data()["kategori"] == "Penggemukan")
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
      appBar: AppBar(
        title: const Text("Laporan"),
        backgroundColor: MyColors.primaryC,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            InkResponse(
              onTap: () {
                setState(() {
                  _isProcessing = true;
                });
                pickDateRange();
              },
              child: buildCard(Icons.calendar_today, "Tanggal",
                  "${DateFormat('dd MMMM yyyy', 'id_ID').format(selectedRange.start)} - ${DateFormat('dd MMMM yyyy', 'id_ID').format(selectedRange.end)}",
                  trailing: _isProcessing
                      ? const CircularProgressIndicator(
                          color: MyColors.primaryC)
                      : null),
            ),
            buildCard(Icons.pie_chart, "Domba", "Populasi: $totalDomba Ekor"),
            buildGenderSection(),
            buildCard(Icons.favorite, "Jumlah Kasus Sakit", "$totalSick Kasus"),
            // buildCard(Icons.cake, "Usia", ""),
            buildCategorySection(),
            buildStatusSection(),
          ],
        ),
      ),
    );
  }

  Widget buildCard(IconData icon, String title, String subtitle,
      {Widget? trailing}) {
    return Card(
      child: ListTile(
        trailing: trailing,
        leading: Icon(icon, color: const Color.fromRGBO(26, 107, 125, 1)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
      ),
    );
  }

  Widget buildGenderSection() {
    return Card(
      child: Column(
        children: [
          const ListTile(
            title: Text("Jenis Kelamin",
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading:
                const Icon(Icons.male, color: Color.fromRGBO(26, 107, 125, 1)),
            title: const Text("Jantan"),
            trailing: Text("$totalMale Ekor",
                style: const TextStyle(color: Color.fromRGBO(26, 107, 125, 1))),
          ),
          ListTile(
            leading: const Icon(Icons.female, color: Colors.pink),
            title: const Text("Betina"),
            trailing: Text("$totalFemale Ekor",
                style: const TextStyle(color: Color.fromRGBO(26, 107, 125, 1))),
          ),
        ],
      ),
    );
  }

  Widget buildCategorySection() {
    return Card(
      child: Column(
        children: [
          const ListTile(
            title:
                Text("Kategori", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ListTile(
            title: const Text("Pembiakan"),
            trailing: Text("$totalPembiakan Ekor",
                style: const TextStyle(color: Color.fromRGBO(26, 107, 125, 1))),
          ),
          ListTile(
            title: const Text("Penggemukan"),
            trailing: Text("$totalPenggemukan Ekor",
                style: const TextStyle(color: Color.fromRGBO(26, 107, 125, 1))),
          ),
        ],
      ),
    );
  }

  Widget buildStatusSection() {
    return Card(
      child: Column(
        children: [
          const ListTile(
            title:
                Text("Status", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailLaporanScreen(
                              user: widget.user,
                              selectedRange: selectedRange,
                              status: "Hidup",
                            ),
                          ));
                    },
                    child: const Text("Hidup")),
                ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailLaporanScreen(
                              user: widget.user,
                              selectedRange: selectedRange,
                              status: "Mati",
                            ),
                          ));
                    },
                    child: const Text("Mati")),
                ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailLaporanScreen(
                              user: widget.user,
                              selectedRange: selectedRange,
                              status: "Terjual",
                            ),
                          ));
                    },
                    child: const Text("Terjual")),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
