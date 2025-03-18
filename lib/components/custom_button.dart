import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({super.key, required this.icons, required this.to});

  final IconData icons;
  final Widget to;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.greenAccent,
        elevation: 10,
        minimumSize: const Size(100, 100),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => to,
          ),
        );
      },
      child: Icon(
        icons,
        size: 40,
      ),
    );
  }
}
