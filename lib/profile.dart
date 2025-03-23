import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:ternak/login.dart';

class Profile extends StatefulWidget {
  final Map<String, dynamic> docUser;
  const Profile({super.key, required this.docUser});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  var canUse = 0;
  var totalBlok = 0;

  User? user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profil'),
        backgroundColor: Colors.blueGrey[300],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance.collection('users').doc(user?.uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('Data tidak ditemukan'));
          }
          var userData = snapshot.data!.data() as Map<String, dynamic>;
          return Column(
            children: [
              Container(
                color: Colors.teal[700],
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, size: 30, color: Colors.teal),
                    ),
                    SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(userData['nama'],
                            style:
                                TextStyle(color: Colors.white, fontSize: 18)),
                        Text(user?.email ?? '',
                            style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ],
                ),
              ),
              Card(
                margin: EdgeInsets.all(16),
                child: ListTile(
                  title: Text('Nama Peternakan'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(userData['farmName'],
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(userData['location']),
                    ],
                  ),
                ),
              ),
              ListTile(
                title: Text('Ubah Password'),
                subtitle: Text('Perbarui password demi keamanan'),
                onTap: () {},
              ),
              ListTile(
                leading: Icon(Icons.notifications, color: Colors.teal),
                title: Text('Pengingat'),
                subtitle: Text('Buat Jadwal untuk pengingat aktivitas'),
                onTap: () {},
              ),
              Spacer(),
              ListTile(
                leading: Icon(Icons.logout, color: Colors.black),
                title: Text('Logout'),
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => Login()),
                    (Route<dynamic> route) =>
                        false, // Menghapus semua halaman sebelumnya
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
