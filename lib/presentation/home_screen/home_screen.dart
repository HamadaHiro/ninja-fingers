import 'dart:math';
import 'dart:async';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:ninja_fingers/const.dart';
import 'package:ninja_fingers/extensions/random_num.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late ConfettiController confettiController;

  int timeToWait = RandomInt.generateRandomNumber(min: 1, max: 10);
  Color bgColor = Colors.white;
  String clownImage = "assets/images/clown.gif";
  String giftImage = "assets/images/gift.gif";
  bool gameStarted = false;
  bool clownCatched = false;
  bool tooLate = false;
  bool gameFinished = false;
  bool clownShown = false;
  int ninjaTime = 0;
  Timer? timer;
  late String imageToShow;
  String adviceText = "";

  @override
  initState() {
    confettiController =
        ConfettiController(duration: const Duration(seconds: 5));
    adviceText = getAdviceText(gameStarted, clownCatched);
    imageToShow = giftImage;
    super.initState();
  }

  @override
  dispose() {
    confettiController.dispose();
    super.dispose();
  }

  startGame() {
    setState(() {
      gameStarted = true;
    });

    Future.delayed(
      Duration(seconds: timeToWait),
      () {
        setState(() {
          clownShown = true;
          imageToShow = clownImage;
          startTimer();
        });
      },
    );
  }

  initGame() {
    setState(() {
      clownCatched = false;
      adviceText = getAdviceText(true, false);
      bgColor = Colors.grey;
    });
    startGame();
  }

  startTimer() {
    timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        setState(() {
          ninjaTime = timer.tick;
          if (ninjaTime >= 5) {
            timer.cancel();
            tooLate = true;
            clownCatched = false;
            gameFinished = true;
            adviceText =
                getAdviceText(gameStarted, clownCatched, tooLate: true);
          }
        });
      },
    );
  }

  getAdviceText(
    bool gameStarted,
    bool clownCatched, {
    bool tooLate = false,
    bool win = false,
  }) {
    if (tooLate && gameFinished) {
      adviceText = "Trop lent, escargot !";
    } else if (win && clownCatched) {
      adviceText = "Bravo ! Clown attrapé en $ninjaTime millisecondes";
    } else if (!gameStarted) {
      adviceText = "Tapez pour Jouer";
    } else if (gameStarted) {
      adviceText =
          "Le clown apparaîtra dans quelques secondes. Attrapez-le le plus rapidement possible, ninja !";
    }
    return adviceText;
  }

  catchClown() {
    confettiController.play();
    setState(() {
      clownCatched = true;
      gameFinished = true;
      timer!.cancel();
      adviceText = getAdviceText(gameStarted, clownCatched, win: clownCatched);
    });
  }

  onIconClicked() {
    if (clownShown && !gameFinished) {
      catchClown();
    } else if (gameFinished) {
      return;
    } else {
      initGame();
    }
  }

  /// A custom Path to paint stars.
  Path drawStar(Size size) {
    // Method to convert degree to radians
    double degToRad(double deg) => deg * (pi / 180.0);

    const numberOfPoints = 5;
    final halfWidth = size.width / 2;
    final externalRadius = halfWidth;
    final internalRadius = halfWidth / 2.5;
    final degreesPerStep = degToRad(360 / numberOfPoints);
    final halfDegreesPerStep = degreesPerStep / 2;
    final path = Path();
    final fullAngle = degToRad(360);
    path.moveTo(size.width, halfWidth);

    for (double step = 0; step < fullAngle; step += degreesPerStep) {
      path.lineTo(halfWidth + externalRadius * cos(step),
          halfWidth + externalRadius * sin(step));
      path.lineTo(halfWidth + internalRadius * cos(step + halfDegreesPerStep),
          halfWidth + internalRadius * sin(step + halfDegreesPerStep));
    }
    path.close();
    return path;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          appName,
          style: const TextStyle(
            // fontSize: 45,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: MediaQuery.of(context).size.height / 8),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.18,
                  child: Text(
                    adviceText,
                    style: const TextStyle(fontSize: 25),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: kPadding),
                GestureDetector(
                  onTap: () {
                    onIconClicked();
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: Image.asset(imageToShow),
                  ),
                ),
                SizedBox(height: kPadding),
                gameFinished
                    ? ElevatedButton(
                        onPressed: () {
                          setState(() {
                            tooLate = false;
                            bgColor = Colors.white;
                            clownCatched = false;
                            gameStarted = false;
                            clownShown = false;
                            gameFinished = false;
                            imageToShow = giftImage;
                            adviceText =
                                getAdviceText(gameStarted, clownCatched);
                          });
                        },
                        child: const Text("Recommencer"),
                      )
                    : Container(),
                const Spacer(),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: ConfettiWidget(
              confettiController: confettiController,
              blastDirection: -pi / 2,
              emissionFrequency: 0.01,
              numberOfParticles: 20,
              maxBlastForce: 100,
              minBlastForce: 80,
              gravity: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
