import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_scanner_overlay/qr_scanner_overlay.dart';
import 'package:ternak/animal_detail.dart';

class QRScanner extends StatefulWidget {
  final User user;
  const QRScanner({super.key, required this.user});

  @override
  State<QRScanner> createState() => _QRScannerState();
}

class _QRScannerState extends State<QRScanner> {
  bool isScanCompleted = false;
  MobileScannerController controller = MobileScannerController();

  void closeScreen() {
    isScanCompleted = false;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _getHewan(BarcodeCapture barcodes) async {
    if (!isScanCompleted) {
      String code = '';
      for (var element in barcodes.barcodes) {
        code = element.rawValue ?? '-----';
      }
      isScanCompleted = true;

      controller.stop();
      try {
        var docSnapshot = await FirebaseFirestore.instance
            .collection("hewan")
            .doc(code)
            .get();

        if (!mounted) return;

        if (docSnapshot.exists) {
          // Kalau data ada, masuk ke detail
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                return AnimalDetail(
                  user: widget.user,
                  doc: docSnapshot,
                );
              },
            ),
          ).then((value) => setState(() {
                closeScreen();
                controller.start();
              }));
        } else {
          // Kalau data tidak ada, tampilkan snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data hewan tidak ditemukan.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
          // Reset scanner supaya bisa scan lagi
          setState(() {
            closeScreen();
            controller.start();
          });
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data tidak ditemukan'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        setState(() {
          closeScreen();
          controller.start();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF5F7FA), Color(0xFFE4EDF5)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              // Padding(
              //   padding: const EdgeInsets.all(16.0),
              //   // child: Row(
              //   //   children: [
              //   //     IconButton(
              //   //       icon: const Icon(Icons.arrow_back, color:  const Color(0xFF1D91AA)),
              //   //       onPressed: () => Navigator.of(context).pop(),
              //   //     ),
              //   //     const Expanded(
              //   //       child: Text(
              //   //         "QR Scanner",
              //   //         textAlign: TextAlign.center,
              //   //         style: TextStyle(
              //   //           color:  const Color(0xFF1D91AA),
              //   //           fontSize: 20,
              //   //           fontWeight: FontWeight.bold,
              //   //         ),
              //   //       ),
              //   //     ),
              //   //     const SizedBox(width: 40),
              //   //   ],
              //   // ),
              // ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Column(
                        children: [
                          // Icon(
                          //   Icons.qr_code_scanner,
                          //   size: 40,
                          //   color:  const Color(0xFF1D91AA),
                          // ),
                          SizedBox(height: 16),
                          Text(
                            "Arahkan QR Code ke area scan",
                            style: TextStyle(
                              color: Color(0xFF333333),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Pemindaian akan dimulai secara otomatis",
                            style: TextStyle(
                              color: Color(0xFF666666),
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 4,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: Stack(
                    children: <Widget>[
                      MobileScanner(
                        controller: controller,
                        onDetect: (barcodes) {
                          if (!isScanCompleted) {
                            _getHewan(barcodes);
                          }
                        },
                      ),
                      QRScannerOverlay(
                        overlayColor: Colors.black.withOpacity(0.5),
                        borderColor:  const Color(0xFF1D91AA),
                        borderRadius: 24,
                        scanAreaSize: const Size.square(280),
                      ),
                      Positioned(
                        bottom: 20,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(
                                    Icons.info_outline,
                                    size: 18,
                                    color: const Color(0xFF1D91AA),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "Scanning...",
                                    style: TextStyle(
                                      color: const Color(0xFF1D91AA),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      closeScreen();
                      controller.start();
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text("Reset Scanner"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D91AA),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
