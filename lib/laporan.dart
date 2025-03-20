import 'package:flutter/material.dart';
import 'package:ternak/components/colors.dart';

class LaporanScreen extends StatefulWidget {
  const LaporanScreen({super.key});

  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen> {
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
            buildCard(
                Icons.calendar_today, "Tanggal", "29 Mei 2024 - 29 Mei 2024"),
            buildCard(Icons.pie_chart, "Domba", "Populasi: 1 Ekor"),
            buildGenderSection(),
            buildCard(Icons.favorite, "Jumlah Kasus Sakit", "0 Kasus"),
            buildCard(Icons.cake, "Usia", "2 bln"),
            buildCategorySection(),
            buildStatusSection(),
          ],
        ),
      ),
    );
  }

  Widget buildCard(IconData icon, String title, String subtitle) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: MyColors.primaryC),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
      ),
    );
  }

  Widget buildGenderSection() {
    return const Card(
      child: Column(
        children: [
          ListTile(
            title: Text("Jenis Kelamin",
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: Icon(Icons.male, color: MyColors.primaryC),
            title: Text("Jantan"),
            trailing:
                Text("1 Ekor", style: TextStyle(color: MyColors.primaryC)),
          ),
          ListTile(
            leading: Icon(Icons.female, color: Colors.pink),
            title: Text("Betina"),
            trailing:
                Text("0 Ekor", style: TextStyle(color: MyColors.primaryC)),
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                    onPressed: () {}, child: const Text("Pembiakan")),
                ElevatedButton(
                    onPressed: () {}, child: const Text("Penggemukan")),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildStatusSection() {
    return const Card(
      child: Column(
        children: [
          ListTile(
            title:
                Text("Status", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ListTile(
            title: Text("Hidup"),
          ),
          ListTile(
            title: Text("Mati"),
          ),
          ListTile(
            title: Text("Terjual"),
          ),
        ],
      ),
    );
  }
}
