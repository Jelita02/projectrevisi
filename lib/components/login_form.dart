import 'package:flutter/material.dart';
import 'package:ternak/main_menu.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  LoginFormState createState() => LoginFormState();
}

class LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;

  bool _isLoading = false;

  void showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Login Gagal'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _attemptLogin() {
    setState(() {
      _isLoading = true;
    });

    FirebaseAuth.instance
        .signInWithEmailAndPassword(
      email: _emailController.text,
      password: _passwordController.text,
    )
        .then((value) {
      User? user = value.user;
      if (user != null) {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MainMenu(user: user),
            ));
      } else {
        setState(() {
          //untuk merubah nilai secara realtime
          _isLoading = false;
        });
        throw Exception("Error System");
      }
    }).catchError((e) {
      setState(() {
        _isLoading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        showErrorDialog(
          context,
          e.toString(),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // jarak
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Center(
              child: Text(
                "Login",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
            ),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  //jika nilai input sama dengan kosong atau nilainya kosong maka mengirim pesan masukan email
                  return 'Masukkan email';
                }
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                  return 'Masukkan email yang valid';
                }
                return null;
              },
            ),
            const SizedBox(height: 16.0),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscureText,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Masukkan kata sandi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () {
                    // Aksi ketika teks ditekan
                    print('Teks ditekan');
                  },
                  child: const Text(
                    'Lupa Password?',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blue, // Warna teks yang dapat ditekan
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20.0),
            Center(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    // padding: EdgeInsets.all(20),
                    backgroundColor: const Color.fromRGBO(26, 107, 125, 1),
                  ),
                  onPressed: () {
                    if (_formKey.currentState?.validate() == true) {
                      _attemptLogin();
                    }
                  },
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Masuk',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
