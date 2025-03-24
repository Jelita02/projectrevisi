import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
        title: const Text('Profil'),
        backgroundColor: Colors.blueGrey[300],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance.collection('users').doc(user?.uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Data tidak ditemukan'));
          }
          var userData = snapshot.data!.data() as Map<String, dynamic>;
          return ListView(
            children: [
              Container(
                color: Colors.teal[700],
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, size: 30, color: Colors.teal),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(userData['nama'],
                            style: const TextStyle(
                                color: Colors.white, fontSize: 18)),
                        Text(user?.email ?? '',
                            style: const TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ],
                ),
              ),
              Card(
                margin: const EdgeInsets.all(16),
                child: ListTile(
                  title: const Text('Nama Peternakan'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(userData['farmName'],
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(userData['location']),
                    ],
                  ),
                ),
              ),
              ListTile(
                title: const Text('Ubah Password'),
                subtitle: const Text('Perbarui password demi keamanan'),
                onTap: () => showUpdatePasswordDialog(context),
              ),
              ListTile(
                leading: const Icon(Icons.notifications, color: Colors.teal),
                title: const Text('Pengingat'),
                subtitle: const Text('Buat Jadwal untuk pengingat aktivitas'),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.black),
                title: const Text('Logout'),
                onTap: () {
                  FirebaseAuth.instance.signOut().then((value) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const Login()),
                      (Route<dynamic> route) =>
                          false, // Menghapus semua halaman sebelumnya
                    );
                  });
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void showUpdatePasswordDialog(BuildContext context) {
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();
    final FirebaseAuth auth = FirebaseAuth.instance;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Update Password"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Password Baru"),
              ),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration:
                    const InputDecoration(labelText: "Konfirmasi Password"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Tutup dialog
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () async {
                String newPassword = passwordController.text.trim();
                String confirmPassword = confirmPasswordController.text.trim();

                if (newPassword.isEmpty || confirmPassword.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Password tidak boleh kosong!")));
                  return;
                }

                if (newPassword != confirmPassword) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Password tidak cocok!")));
                  return;
                }

                try {
                  User? user = auth.currentUser;
                  if (user != null) {
                    await user.updatePassword(newPassword);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("Password berhasil diperbarui!")));
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("User tidak ditemukan!")));
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text("Error: $e")));
                }
              },
              child: const Text("Update"),
            ),
          ],
        );
      },
    );
  }
}
