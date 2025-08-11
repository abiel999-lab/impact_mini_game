import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'game/flappy_game.dart';

void main() {
  runApp(const FlappyApp());
}

class FlappyApp extends StatelessWidget {
  const FlappyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final game = FlappyGame();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: GameWidget(
          game: game,
          overlayBuilderMap: {
            'GameOver': (context, gameWidget) => gameOverOverlay(context, game),
          },
        ),
      ),
    );
  }
}

/// Overlay Game Over
/// Overlay Game Over
Widget gameOverOverlay(BuildContext context, FlappyGame game) {
  return Container(
    // ignore: deprecated_member_use
    color: Colors.white.withOpacity(0.9), // 🔹 background putih semi transparan
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Game Over!',
            style: TextStyle(fontSize: 40, color: Colors.red),
          ),
          const SizedBox(height: 10),
          Text(
            'Score: ${game.score}\nHigh Score: ${game.highScore}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, color: Colors.black),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: game.restartGame,
            child: const Text('Restart'),
          ),
        ],
      ),
    ),
  );
}

