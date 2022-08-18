import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:ninja_fingers/const.dart';
import 'package:just_audio/just_audio.dart';
import 'package:ninja_fingers/extensions/random_num.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// Next updates : - anti-cheat (multiple tap before showing clown)
//                - Badges, storage

class _HomeScreenState extends State<HomeScreen> {
  late ConfettiController confettiController;

  int timeToWait = RandomInt.generateRandomNumber(min: 1, max: 10);
  Color bgColor = Colors.white;
  String clownImage = "assets/images/clown.gif";
  String giftImage = "assets/images/gift.gif";
  String ninjaImage = "assets/images/ninja.png";
  bool gameStarted = false;
  bool clownCatched = false;
  bool tooLate = false;
  bool gameFinished = false;
  bool clownShown = false;
  bool eliminated = false;
  int ninjaTime = 0;
  Timer? timer;
  late String imageToShow;
  String adviceText = "";
  Stopwatch? stopwatch;
  int level = 0;

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

  congratModal(int level) {
    var levelsNames = ["Genin", "Chunin", "Hokage", "Rogue Ninja"];
    showDialog(
      context: context,
      builder: ((context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Card(
            elevation: 0,
            child: Container(
              padding: EdgeInsets.all(kPadding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Bravo ! Vous êtes un ${levelsNames[level - 1]}, niveau $level !",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: kPadding),
                  Image.asset("assets/images/badge-$level.png"),
                  SizedBox(height: kPadding),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Fermer"),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
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

  playDisappointmentSound() async {
    final player = AudioPlayer();
    await player.setUrl('asset:assets/sounds/disappointment.mp3');
    player.play();
  }

  playApplauseSound() async {
    final player = AudioPlayer();
    await player.setUrl('asset:assets/sounds/applause.wav');
    player.play();
  }

  startTimer() {
    stopwatch = Stopwatch()..start();
    timer = Timer.periodic(
      const Duration(milliseconds: 1),
      (timer) {
        setState(() {
          ninjaTime = stopwatch!.elapsedMilliseconds;
          if (ninjaTime >= 1300 || eliminated) {
            if (eliminated) {
              timer.cancel();
              stopwatch!.stop();
              ninjaTime = 0;
              imageToShow = ninjaImage;
              eliminated = false;
            } else {
              timer.cancel();
              tooLate = true;
              clownCatched = false;
              gameFinished = true;
              adviceText =
                  getAdviceText(gameStarted, clownCatched, tooLate: true);
              playDisappointmentSound();
            }
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
      ninjaTime = stopwatch!.elapsedMilliseconds;

      if (ninjaTime <= 100) {
        level = 4;
      } else if (ninjaTime > 100 && ninjaTime <= 250) {
        level = 3;
      } else if (ninjaTime > 250 && ninjaTime <= 450) {
        level = 2;
      } else if (ninjaTime > 450) {
        level = 1;
      }

      congratModal(level);

      stopwatch!.stop();
      clownCatched = true;
      gameFinished = true;
      timer!.cancel();
      adviceText = getAdviceText(gameStarted, clownCatched, win: clownCatched);
      playApplauseSound();
    });
  }

  onIconClicked() {
    if (clownShown && !gameFinished) {
      catchClown();
    } else if (!clownShown && gameStarted && !gameFinished) {
      setState(() {
        tooLate = false;
        eliminated = true;
        imageToShow = ninjaImage;
        gameFinished = true;
        clownCatched = true;
        gameFinished = true;
        gameStarted = false;

        adviceText =
            "Éliminé.e ! Vous avez frappé avant que le clown n'apparaisse.";
      });
      playDisappointmentSound();
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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Stack(
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
                      style: const TextStyle(fontSize: 20),
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
      ),
    );
  }
}
