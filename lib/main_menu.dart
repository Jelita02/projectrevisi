import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ternak/components/home.dart';
import 'package:ternak/profile.dart';
import 'package:ternak/qr_scanner.dart';

class MainMenu extends StatefulWidget {
  final User user;
  const MainMenu({super.key, required this.user});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  Map<String, dynamic> _docUser = {};
  int _countAnimal = 0;
  int _countMale = 0;
  int _countFemale = 0;
  int _countHealthy = 0;
  int _countSick = 0;

  @override
  void initState() {
    super.initState();

    getData();
  }

  getData() {
    FirebaseFirestore.instance
        .collection("users")
        .doc(widget.user.uid)
        .snapshots()
        .first
        .then((value) {
      setState(() {
        Map<String, dynamic>? dataUser = value.data();
        if (dataUser != null) {
          setState(() {
            _docUser = dataUser;
          });
        }

        FirebaseFirestore.instance
            .collection("hewan")
            .where("user_uid", isEqualTo: widget.user.uid)
            .get()
            .then((value) {
          var list = value.docs.toList();
          setState(() {
            _countAnimal = list
                .where((element) => element.data()["status"] == "Hidup")
                .length;
            _countMale = list
                .where((element) =>
                    element.data()["jenis_kelamin"] == "Jantan" &&
                    element.data()["status"] == "Hidup")
                .length;
            //perhitungannya length
            _countFemale = list
                .where((element) =>
                    element.data()["jenis_kelamin"] == "Betina" &&
                    element.data()["status"] == "Hidup")
                .length;
            _countHealthy = list
                .where((element) =>
                    element.data()["status_kesehatan"] == "Sehat" &&
                    element.data()["status"] == "Hidup")
                .length;
            _countSick = list
                .where((element) =>
                    element.data()["status_kesehatan"] == "Sakit" &&
                    element.data()["status"] == "Hidup")
                .length;
          });
        });
      });
    });
  }

  int _currentIndex = 0;

  void _onTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      Home(
        user: widget.user,
        countAnimal: _countAnimal,
        countMale: _countMale,
        countFemale: _countFemale,
        countHealthy: _countHealthy,
        countSick: _countSick,
        getData: getData,
      ),
      QRScanner(user: widget.user),
      Profile(
        docUser: _docUser,
      ),
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1D91AA).withOpacity(0.9),
        centerTitle: true,
        title: const Text(
          "QR-Sheep",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        margin: const EdgeInsets.only(top: 10),
        height: 65,
        width: 65,
        child: FloatingActionButton(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(35),
          ),
          elevation: 4,
          backgroundColor: const Color(0xFF1D91AA),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(35),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.qr_code_scanner,
              color: Colors.white,
              size: 30,
            ),
          ),
          onPressed: () {
            setState(() {
              _currentIndex = 1; // Pindah ke qr
            });
          },
        ),
      ),
      bottomNavigationBar: Container(
        height: 83,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
          child: BottomAppBar(
            color: Colors.white,
            height: 65,
            shape: const CircularNotchedRectangle(),
            notchMargin: 8,
            elevation: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, 'Beranda'),
                const SizedBox(width: 40), // Space for FAB
                _buildNavItem(2, Icons.person_rounded, 'Profil'),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1D91AA).withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: pages[_currentIndex],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final bool isSelected = _currentIndex == index;

    return InkWell(
      onTap: () => _onTapped(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF1D91AA) : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? const Color(0xFF1D91AA) : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
