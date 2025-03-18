import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ternak/animal_menu.dart';
import 'package:ternak/cage_menu.dart';
import 'package:ternak/healthy_add.dart';
import 'package:ternak/laporan.dart';

class Home extends StatefulWidget {
  final User user;
  final int countAnimal;
  final int countMale;
  final int countFemale;
  final int countHealthy;
  final int countSick;
  final Function getData;
  const Home(
      {super.key,
      required this.user,
      this.countAnimal = 0,
      this.countMale = 0,
      this.countFemale = 0,
      this.countHealthy = 0,
      this.countSick = 0,
      required this.getData});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: const Color.fromRGBO(29, 145, 170, 0.3),
              ),
              child: Container(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Image.asset("assets/images/icon-cage.png"),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Domba",
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 17,
                              ),
                            ),
                            Row(
                              children: [
                                const Text(
                                  "Total Populasi: ",
                                  style: TextStyle(
                                    color: Color.fromRGBO(0, 0, 0, 0.5),
                                  ),
                                ),
                                Text("${widget.countAnimal} Ekor"),
                              ],
                            )
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: 20),
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.male,
                                      color: Color.fromRGBO(29, 145, 170, 1),
                                      size: 28,
                                    ),
                                    Text("Jantan"),
                                  ],
                                ),
                                Text("${widget.countMale} Ekor"),
                              ],
                            ),
                            Column(
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.female,
                                      color: Color.fromRGBO(29, 145, 170, 1),
                                      size: 28,
                                    ),
                                    Text("Betina"),
                                  ],
                                ),
                                Text("${widget.countFemale} Ekor"),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                         Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.local_activity_outlined,
                                      color: Color.fromRGBO(29, 145, 170, 1),
                                      size: 28,
                                    ),
                                    Text("Sehat"),
                                  ],
                                ),
                                Text("${widget.countHealthy} Ekor"),
                              ],
                            ),
                            Column(
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.healing,
                                      color: Color.fromRGBO(29, 145, 170, 1),
                                      size: 28,
                                    ),
                                    Text("Sakit"),
                                  ],
                                ),
                                Text("${widget.countSick} Ekor"),
                              ],
                            ),
                          ],
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MenuAnimal(
                                  user: widget.user,
                                ),
                              )).then((value) => widget.getData());
                        },
                        child: Column(
                          children: [
                            Image.asset(
                              "assets/images/icon-goat.png",
                              width: 52,
                              height: 42,
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              "Hewan",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CageMenu(
                                  user: widget.user,
                                ),
                              )).then((value) => widget.getData());
                        },
                        child: Column(
                          children: [
                            Image.asset(
                              "assets/images/icon-cage.png",
                              width: 52,
                              height: 42,
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              "Kandang",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 50),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HealthyAdd(
                                  user: widget.user,
                                ),
                              ));
                        },
                        child: Column(
                          children: [
                            Image.asset(
                              "assets/images/icon-vektor.png",
                              width: 52,
                              height: 42,
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              "Kesehatan",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LaporanScreen(),
                              ));
                        },
                        child: Column(
                          children: [
                            Image.asset(
                              "assets/images/icon-report.png",
                              width: 52,
                              height: 42,
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              "Laporan",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
