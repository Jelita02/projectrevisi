import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:intl/intl.dart';
import 'package:ternak/components/colors.dart';

class DetailLaporanScreen extends StatefulWidget {
  final String status;
  final User user;
  final DateTimeRange selectedRange;
  const DetailLaporanScreen(
      {super.key,
      required this.user,
      required this.selectedRange,
      required this.status});

  @override
  State<DetailLaporanScreen> createState() => _DetailLaporanScreenState();
}

class _DetailLaporanScreenState extends State<DetailLaporanScreen> {
  final PagingController<int, Map<String, dynamic>> _pagingController =
      PagingController(firstPageKey: 0);
  static const _pageSize = 5;

  DocumentSnapshot<Map<String, dynamic>>? lastDoc;

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener((pageKey) {
    _fetchPage(pageKey);
    });
  }

  Future<void> _fetchPage(int pageKey) async {
    var query = FirebaseFirestore.instance
        .collection("hewan")
        .where("user_uid", isEqualTo: widget.user.uid)
        .where('tanggal_masuk',
            isGreaterThanOrEqualTo: DateFormat('yyyy-MM-dd')
                .format(widget.selectedRange.start)) // >= 1 Mei 2024
        .where('tanggal_masuk',
            isLessThanOrEqualTo: DateFormat('yyyy-MM-dd')
                .format(widget.selectedRange.end)) // <= 10 Mei 2024
        .where("status", isEqualTo: widget.status)
        .orderBy("nama");

    if (lastDoc != null) {
      query = query.startAfter([lastDoc!.data()?["nama"]]);
    }

    var newItems = await query.limit(_pageSize).get();

    lastDoc = newItems.docs.last;

    var list = newItems.docs.map((e) => e.data()).toList();

    final isLastPage = list.length < _pageSize;
    if (isLastPage) {
      _pagingController.appendLastPage(list);
    } else {
      final nextPageKey = pageKey + list.length;
      _pagingController.appendPage(list, nextPageKey);
    }
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.status),
        backgroundColor: MyColors.primaryC,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: SingleChildScrollView(//
          scrollDirection: Axis.horizontal,//biar geser kesamping 
          child: SizedBox(
            width: 1100,
            child: Column  (
              children: [
                Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.black, // Warna border
                        width: 2.0, // Ketebalan border
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      _buildHeaderCell("No.", 50),
                      _buildHeaderCell("Nama", 100),
                      _buildHeaderCell("Jenis Kelamin", 130),
                      _buildHeaderCell("Usia", 130),
                      _buildHeaderCell("Jenis Hewan", 130),
                      _buildHeaderCell("Kategori", 130),
                      _buildHeaderCell("Kondisi", 100),
                      _buildHeaderCell("Kandang", 100),
                      _buildHeaderCell("Blok", 100),
                      
                    ],
                  ),
                ),
                Expanded(
                  child: PagedListView<int, Map<String, dynamic>>(
                    pagingController: _pagingController,
                    builderDelegate:
                        PagedChildBuilderDelegate<Map<String, dynamic>>(
                      itemBuilder: (context, item, index) {
                        return Container(
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.black, // Warna border
                                width: 2.0, // Ketebalan border
                              ),
                            ),
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              _buildDataCell((index + 1).toString(), 50),
                              _buildDataCell(item["nama"].toString(), 100),
                              _buildDataCell(
                                  item["jenis_kelamin"].toString(), 130),
                              _buildDataCell(item["usia"].toString(), 130),
                              _buildDataCell(item["jenis"].toString(), 130),
                              _buildDataCell(item["kategori"].toString(), 130),
                               _buildDataCell(item["status_kesehatan"].toString(), 100),
                              _buildDataCell(item["kandang"].toString(), 100),
                              _buildDataCell(item["blok"].toString(), 100),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String text, double width) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      width: width,
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildDataCell(String text, double width) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      width: width,
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}
