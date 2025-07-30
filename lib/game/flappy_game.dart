import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/collisions.dart';
import 'package:flame_audio/flame_audio.dart';

class Bird extends SpriteComponent with CollisionCallbacks, HasGameRef<FlappyGame> {
  double velocity = 0;

  Bird()
      : super(
    size: Vector2(50, 50),
    anchor: Anchor.center,
  );

  @override
  Future<void> onLoad() async {
    sprite = await gameRef.loadSprite('bird.png');

    add(RectangleHitbox.relative(
      Vector2(0.7, 0.7),
      parentSize: size,
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (gameRef.isGameOver) return;

    velocity += gameRef.gravity * dt;
    y += velocity * dt;

    // Cek nabrak lantai
    if (y + height / 2 >= gameRef.groundY) {
      y = gameRef.groundY - height / 2;
      velocity = 0;
      gameRef.gameOver();
    }

    // Cek nabrak plafon
    if (y - height / 2 <= gameRef.floorHeight) {
      y = gameRef.floorHeight + height / 2;
      velocity = 0;
    }
  }

  void jump() {
    velocity = gameRef.jumpForce;
    FlameAudio.play('jump.wav');
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Pipe) {
      gameRef.gameOver();
    }
    super.onCollision(intersectionPoints, other);
  }
}

class Pipe extends SpriteComponent with CollisionCallbacks {
  bool scored = false; // untuk mencegah skor ganda

  Pipe({
    required Vector2 position,
    required Vector2 size,
    required Sprite sprite,
    bool flipY = false,
  }) : super(position: position, size: size) {
    this.sprite = sprite;
    if (flipY) flipVertically();
  }

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox.relative(
      Vector2(0.9, 0.9),
      parentSize: size,
    ));
  }
}

class FlappyGame extends FlameGame with TapDetector, HasCollisionDetection {
  late Bird bird;
  late SpriteComponent background;
  late SpriteComponent floorBottom;
  late SpriteComponent floorTop;

  late Sprite pipeSprite;

  double gravity = 600;
  double jumpForce = -300;
  bool isGameOver = false;

  double groundY = 0;
  double floorHeight = 100;

  double spawnTimer = 0;
  final double spawnInterval = 2.0;
  final Random random = Random();

  final List<Pipe> pipes = [];

  int score = 0;
  int highScore = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 🔹 Preload audio biar tidak delay
    await FlameAudio.audioCache.loadAll([
      'jump.wav',
      'hit.wav',
      'point.wav',
      'bgm.mp3',
    ]);

    pipeSprite = await loadSprite('pipe.png');

    background = SpriteComponent()
      ..sprite = await loadSprite('background_color_sky.png')
      ..size = size
      ..position = Vector2.zero();
    add(background);

    floorBottom = SpriteComponent()
      ..sprite = await loadSprite('floor.png')
      ..size = Vector2(size.x, floorHeight)
      ..position = Vector2(0, size.y - floorHeight);
    add(floorBottom);

    floorTop = SpriteComponent()
      ..sprite = await loadSprite('floor.png')
      ..size = Vector2(size.x, floorHeight)
      ..position = Vector2(0, 0);
    add(floorTop);

    groundY = size.y - floorHeight;

    bird = Bird()..position = Vector2(100, size.y / 2);
    add(bird);

    // 🔹 Opsional: mainkan BGM loop
    // FlameAudio.bgm.play('bgm.mp3', volume: 0.5);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isGameOver) return;

    spawnTimer += dt;
    if (spawnTimer >= spawnInterval) {
      spawnTimer = 0;
      spawnPipe();
    }

    for (var pipe in pipes) {
      pipe.x -= 150 * dt;

      // Tambah skor saat burung melewati pipa bawah
      if (!pipe.scored &&
          pipe.x + pipe.width < bird.x &&
          pipe.y > size.y / 2) {
        pipe.scored = true;
        score++;
        if (score > highScore) highScore = score;
        FlameAudio.play('point.wav'); // ✅ sekarang pasti bunyi
      }
    }

    // Bersihkan pipa yang keluar layar
    pipes.removeWhere((pipe) {
      if (pipe.x + pipe.width < 0) {
        pipe.removeFromParent();
        return true;
      }
      return false;
    });
  }

  void spawnPipe() {
    const double gapHeight = 300;
    const double topOffset = 100;

    final double minPipeHeight = 50;
    final double maxPipeHeight = groundY - gapHeight - minPipeHeight;
    if (maxPipeHeight <= minPipeHeight) return;

    final double bottomPipeHeight =
        minPipeHeight + random.nextDouble() * (maxPipeHeight - minPipeHeight);

    final double bottomPipeY = groundY - bottomPipeHeight;
    final double topPipeHeight =
        size.y - topOffset - gapHeight - bottomPipeHeight;

    final double pipeX = size.x;

    final bottomPipe = Pipe(
      position: Vector2(pipeX, bottomPipeY),
      size: Vector2(60, bottomPipeHeight),
      sprite: pipeSprite,
    );

    final topPipe = Pipe(
      position: Vector2(pipeX, topOffset),
      size: Vector2(60, topPipeHeight),
      sprite: pipeSprite,
      flipY: true,
    )..anchor = Anchor.bottomLeft;

    add(bottomPipe);
    add(topPipe);
    pipes.add(bottomPipe);
    pipes.add(topPipe);
  }

  @override
  void onTap() {
    if (isGameOver) {
      restartGame();
    } else {
      bird.jump();
    }
  }

  void gameOver() {
    if (isGameOver) return;
    isGameOver = true;
    FlameAudio.play('hit.wav');
    overlays.add('GameOver');
  }

  void restartGame() {
    isGameOver = false;
    score = 0;
    bird.velocity = 0;
    bird.position = Vector2(100, size.y / 2);

    for (var pipe in pipes) {
      pipe.removeFromParent();
    }
    pipes.clear();

    overlays.remove('GameOver');
  }
}
