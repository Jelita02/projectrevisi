import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:intl/intl.dart';
import 'package:ternak/components/colors.dart';
import 'package:excel/excel.dart' as xl;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

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
                .format(widget.selectedRange.start))
        .where('tanggal_masuk',
            isLessThanOrEqualTo: DateFormat('yyyy-MM-dd')
                .format(widget.selectedRange.end))
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          " ${widget.status}",
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: MyColors.primaryC,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  "${DateFormat('dd/MM/yyyy').format(widget.selectedRange.start)} - ${DateFormat('dd/MM/yyyy').format(widget.selectedRange.end)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded, color: Colors.white),
            tooltip: 'Download Excel',
            onPressed: () => _exportToExcel(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section
          Container(
            color: MyColors.primaryC,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.assignment_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Detail Laporan",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      "Daftar hewan dengan status ${widget.status}",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Curved transition
          Container(
            height: 20,
            decoration: BoxDecoration(
              color: MyColors.primaryC,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
          ),
          
          // Legend
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Colors.amber,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      "Geser ke kanan untuk melihat semua data",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Table
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 16, 20, 20),
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: SizedBox(
                    width: 1100,
                    child: Column(
                      children: [
                        // Header row
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: MyColors.primaryC.withOpacity(0.05),
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.withOpacity(0.2),
                                width: 1.0,
                              ),
                            ),
                          ),
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
                        
                        // Data rows
                        Expanded(
                          child: PagedListView<int, Map<String, dynamic>>(
                            pagingController: _pagingController,
                            builderDelegate: PagedChildBuilderDelegate<Map<String, dynamic>>(
                              itemBuilder: (context, item, index) {
                                return Container(
                                  decoration: BoxDecoration(
                                    color: index % 2 == 0 ? Colors.white : Colors.grey[50],
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.grey.withOpacity(0.2),
                                        width: 1.0,
                                      ),
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  child: Row(
                                    children: [
                                      _buildDataCell((index + 1).toString(), 50),
                                      _buildDataCell(item["nama"].toString(), 100),
                                      _buildDataCell(item["jenis_kelamin"].toString(), 130),
                                      _buildDataCell(item["usia"].toString(), 130),
                                      _buildDataCell(item["jenis"].toString(), 130),
                                      _buildDataCell(item["kategori"].toString(), 130),
                                      _buildStatusCell(item["status_kesehatan"].toString(), 100),
                                      _buildDataCell(item["kandang"].toString(), 100),
                                      _buildDataCell(item["blok"].toString(), 100),
                                    ],
                                  ),
                                );
                              },
                              firstPageErrorIndicatorBuilder: (_) => Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      size: 60,
                                      color: Colors.red[300],
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      "Terjadi kesalahan",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ElevatedButton(
                                      onPressed: () => _pagingController.refresh(),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: MyColors.primaryC,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text("Coba Lagi"),
                                    ),
                                  ],
                                ),
                              ),
                              noItemsFoundIndicatorBuilder: (_) => Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.search_off,
                                      size: 60,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      "Tidak ada data hewan",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Tidak ditemukan hewan dengan status ${widget.status}",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[500],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                              newPageProgressIndicatorBuilder: (_) => const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(
                                    color: MyColors.primaryC,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, double width) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      width: width,
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: MyColors.primaryC,
          fontSize: 15,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDataCell(String text, double width) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      width: width,
      child: Text(
        text,
        style: TextStyle(
          color: Colors.grey[800],
          fontSize: 14,
        ),
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
  
  Widget _buildStatusCell(String status, double width) {
    Color statusColor;
    
    if (status.toLowerCase().contains('sehat')) {
      statusColor = Colors.green;
    } else if (status.toLowerCase().contains('sakit')) {
      statusColor = Colors.red;
    } else {
      statusColor = Colors.orange;
    }
    
    return Container(
      margin: const EdgeInsets.only(right: 10),
      width: width,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: statusColor.withOpacity(0.3)),
        ),
        child: Text(
          status,
          style: TextStyle(
            color: statusColor,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Future<void> _exportToExcel() async {
    try {
      // Show loading dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Menyiapkan file Excel...'),
              ],
            ),
          ),
        );
      }

      // Create Excel object
      final excel = xl.Excel.createExcel();
      final sheet = excel['Laporan ${widget.status}'];

      // Add header row with styling
      final headerStyle = xl.CellStyle(
        backgroundColorHex: xl.ExcelColor.fromHexString('#4C72AF'),
        fontColorHex: xl.ExcelColor.fromHexString('#FFFFFF'),
        bold: true,
        horizontalAlign: xl.HorizontalAlign.Center,
      );

      final headers = [
        'No.',
        'Nama',
        'Jenis Kelamin',
        'Usia',
        'Jenis Hewan',
        'Kategori',
        'Kondisi',
        'Kandang',
        'Blok'
      ];

      // Add headers
      for (var i = 0; i < headers.length; i++) {
        final cell = sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = xl.TextCellValue(headers[i]);
        cell.cellStyle = headerStyle;
      }

      // Fetch all data from Firestore (not just the paginated data)
      var query = FirebaseFirestore.instance
          .collection("hewan")
          .where("user_uid", isEqualTo: widget.user.uid)
          .where('tanggal_masuk',
              isGreaterThanOrEqualTo: DateFormat('yyyy-MM-dd').format(widget.selectedRange.start))
          .where('tanggal_masuk',
              isLessThanOrEqualTo: DateFormat('yyyy-MM-dd').format(widget.selectedRange.end))
          .where("status", isEqualTo: widget.status)
          .orderBy("tanggal_masuk");

      final snapshot = await query.get();
      final data = snapshot.docs.map((e) => e.data()).toList();

      // Add data rows
      for (var i = 0; i < data.length; i++) {
        final item = data[i];
        final row = i + 1; // Excel rows are 0-indexed, but we start data at row 1

        sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = xl.TextCellValue((i + 1).toString());
        sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = xl.TextCellValue(item["nama"]?.toString() ?? '');
        sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value = xl.TextCellValue(item["jenis_kelamin"]?.toString() ?? '');
        sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).value = xl.TextCellValue(item["usia"]?.toString() ?? '');
        sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).value = xl.TextCellValue(item["jenis"]?.toString() ?? '');
        sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row)).value = xl.TextCellValue(item["kategori"]?.toString() ?? '');
        sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row)).value = xl.TextCellValue(item["status_kesehatan"]?.toString() ?? '');
        sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row)).value = xl.TextCellValue(item["kandang"]?.toString() ?? '');
        sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: row)).value = xl.TextCellValue(item["blok"]?.toString() ?? '');
      }

      // Auto fit columns
      for (var i = 0; i < headers.length; i++) {
        sheet.setColumnWidth(i, 15);
      }

      // Get directory for saving file and create filename
      final now = DateTime.now();
      final fileName = 'Laporan_${widget.status}_${DateFormat('yyyyMMdd_HHmmss').format(now)}.xlsx';
      String? filePath;
      
      if (!kIsWeb) {
        if (Platform.isAndroid) {
          // On Android, save to Downloads folder
          final status = await Permission.storage.request();
          if (status.isGranted) {
            // Use the Downloads directory
            final directory = Directory('/storage/emulated/0/Download');
            if (!await directory.exists()) {
              await directory.create(recursive: true);
            }
            filePath = '${directory.path}/$fileName';
          }
        } else if (Platform.isIOS) {
          // On iOS, use documents directory
          final directory = await getApplicationDocumentsDirectory();
          filePath = '${directory.path}/$fileName';
        } else {
          // Fallback for other platforms
          final directory = await getExternalStorageDirectory();
          filePath = '${directory?.path ?? (await getTemporaryDirectory()).path}/$fileName';
        }
      } else {
        // Web platform handling (not implementing here)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Download pada web tidak didukung'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      // Check if filePath was successfully determined
      if (filePath == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal mendapatkan lokasi penyimpanan'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      // Save the Excel file
      final fileBytes = excel.encode();
      if (fileBytes != null) {
        final file = File(filePath);
        await file.writeAsBytes(fileBytes);

        // Close loading dialog
        if (mounted) {
          Navigator.pop(context);
        }

        // Show success notification with more helpful message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('File Excel berhasil disimpan!', 
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  if (Platform.isAndroid)
                    const Text('Lokasi: folder Download di penyimpanan internal', 
                      style: TextStyle(fontSize: 13),
                    )
                  else
                    Text('Lokasi: $filePath', style: TextStyle(fontSize: 13)),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 6),
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog if open
      if (mounted) {
        Navigator.maybeOf(context)?.pop();
      }

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengunduh file: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('Error exporting to Excel: $e');
    }
  }
}
