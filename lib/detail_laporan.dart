import 'package:flutter/material.dart';
import 'package:ternak/components/colors.dart';

class DetailLaporanScreen extends StatefulWidget {
  const DetailLaporanScreen({super.key});

  @override
  State<DetailLaporanScreen> createState() => _DetailLaporanScreenState();
}

class _DetailLaporanScreenState extends State<DetailLaporanScreen> {
  int currentPage = 1;
  final int totalPages = 3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hidup"),
        backgroundColor: MyColors.primaryC,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text("No")),
                  DataColumn(label: Text("Nama")),
                  DataColumn(label: Text("Jenis Kelamin")),
                  DataColumn(label: Text("Jenis Hewan")),
                  DataColumn(label: Text("Kategori")),
                  DataColumn(label: Text("Kondisi")),
                ],
                rows: List.generate(
                  5,
                  (index) => DataRow(cells: [
                    DataCell(Text('${(currentPage - 1) * 5 + index + 1}')),
                    DataCell(Text("Nama ${index + 1}")),
                    DataCell(Text(index % 2 == 0 ? "Jantan" : "Betina")),
                    DataCell(Text("Domba")),
                    DataCell(Text("Pembiakan")),
                    DataCell(Text("Sehat")),
                  ]),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: currentPage > 1
                      ? () {
                          setState(() {
                            currentPage--;
                          });
                        }
                      : null,
                  child: const Text("Prev"),
                ),
                for (int i = 1; i <= totalPages; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          currentPage = i;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: currentPage == i ? Colors.blue : Colors.grey[300],
                      ),
                      child: Text("$i"),
                    ),
                  ),
                ElevatedButton(
                  onPressed: currentPage < totalPages
                      ? () {
                          setState(() {
                            currentPage++;
                          });
                        }
                      : null,
                  child: const Text("Next"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
