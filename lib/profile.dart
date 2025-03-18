import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Profile extends StatefulWidget {
  final Map<String, dynamic> docUser;
  final User user;
  const Profile({super.key, required this.docUser, required this.user});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  var canUse = 0;
  var totalBlok = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.all(10),
            width: double.infinity,
            color: const Color.fromRGBO(26, 107, 125, 1),
            child: ListTile(
              leading: const Icon(
                Icons.person,
                size: 50,
                color: Colors.white,
              ),
              title: Text(
                widget.docUser["name"] ?? "",
                style: const TextStyle(
                  color: Colors.white,
                ),
              ),
              subtitle: Text(
                widget.user.email ?? "",
                style: const TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Transform.translate(
            offset: const Offset(0, -70),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(20),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.grey,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Nama Peternakan"),
                      Text(
                        widget.docUser["nama_peternakan"] ?? "",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
