import 'package:flutter/material.dart';
import 'package:ternak/components/login_form.dart';

class Login extends StatelessWidget {
  const Login({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        margin: const EdgeInsets.all(20),
        child: Center(
          child: ListView(
            // mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Column(
                children: <Widget>[
                  const Text(
                    "Domternak",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 30, // tulisan
                    ),
                  ),
                  Image.asset(
                    "assets/images/login-logo.jpg",
                    width: 250, // ukuran gambar
                  ),
                ],
              ),
              const LoginForm(),
            ],
          ),
        ),
      ),
    );
  }
}
