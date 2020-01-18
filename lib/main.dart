import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]).then((_) {
    runApp(BitClock());
  });
}

class BitClock extends StatefulWidget {
  static const double NUM_STEP = 15.0;

  @override
  _BitClockState createState() => _BitClockState();
}

class _BitClockState extends State<BitClock> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Color.fromRGBO(20, 20, 20, 1.0),
        resizeToAvoidBottomPadding: false,
        body: SafeArea(
          child: Center(
            child: AspectRatio(
              aspectRatio: 5 / 3,
              child: BitClockWorld(),
            ),
          ),
        ),
      ),
    );
  }
}

class BitClockWorld extends StatefulWidget {
  @override
  _BitClockWorldState createState() => _BitClockWorldState();
}

class _BitClockWorldState extends State<BitClockWorld> {
  int tick = 0;
  int rowlen = 0;
  int columnlen = 0;

  double scrh = 0;
  double scrw = 0;

  Timer timer;
  List<BitPoint> world = [];

  bool splash = true;

  bool lock = true;
  bool dirty = false;

  @override
  void initState() {
    super.initState();

    scrh = WidgetsBinding.instance.window.physicalSize.height;
    scrw = WidgetsBinding.instance.window.physicalSize.width;
    if (scrh > scrw) {
      double h = scrw;
      double w = scrh;
      scrh = h;
      scrw = w;
    }

    rowlen = (scrh / 38).floor();
    columnlen = (scrw / 28).floor();

    void runworld() {
      int sec = 0;
      timer = Timer.periodic(Duration(milliseconds: 100), (Timer timer) {
        if (sec != DateTime.now().second) {
          sec = DateTime.now().second;
          dirty = true;
        }

        update();
        setState(() => tick = timer.tick);
      });

      // Future.delayed(Duration(seconds: 10), () => timer.cancel());
    }

    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        splash = false;
      });

      Future.delayed(Duration(seconds: 2), runworld);
    });
  }

  void update() {
    int randlen() => 7 + Random().nextInt(20 - 7);
    double yi() => Random().nextInt(10) * 1.0;

    if (world.isEmpty) {
      world..addAll(BitPointMatrix.buildFlow(0.0, yi() + 5, 8));
      world..addAll(BitPointRealTime.build(scrw, scrh));
    }

    if (dirty && !lock) {
      for (var i = 0; i < world.length; i++) {
        if (world[i].isTimeNum) world.removeAt(i);
      }
      world..addAll(BitPointRealTime.build(scrw, scrh).map((p) => p..isLight = true).toList());
      dirty = false;
    }

    if (world.length < 1200) {
      for (var i = 0; i < columnlen; i++) {
        int len = randlen();
        world..addAll(BitPointMatrix.buildFlow(5.0 + (i * 15), yi() + len * 2, len));
      }
    }

    for (var i = 0; i < world.length; i++) {
      if (world[i].isTimeNum) {
        if (world[7].y >= world[i].y) {
          world[i].isLight = true;
        }

        continue;
      }

      world[i].y += BitClock.NUM_STEP;
      if (world[i].y > scrh / 2) {
        world.removeAt(i);
        lock = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Center(
        child: AnimatedOpacity(
          duration: Duration(seconds: 2),
          opacity: splash ? 1.0 : 0.0,
          child: Image.asset('bitclock.png'),
        ),
      ),
      if (!splash)
        ...world.map((point) {
          int value = Random().nextInt(10);
          if (value == 1) value = 2;
          int opct = 3 + Random().nextInt(7 - 3);

          Color color = point.isLast ? Colors.white70 : Colors.green;
          color = color.withOpacity(point.isLast ? 0.7 : opct / 10);
          if (point.isTimeNum) {
            if (point.isLight) {
              color = Colors.white;
            } else {
              color = Colors.transparent;
            }
          }

          return Positioned(
            top: point.y,
            left: point.x,
            child: Container(
              child: Text(
                '$value',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                ),
              ),
            ),
          );
        }).toList(),
    ]);
  }
}

class BitPoint {
  double x;
  double y;
  int size;
  bool isLast;
  bool isTimeNum;
  bool isLight;

  BitPoint({
    this.x,
    this.y,
    this.size,
    this.isLast = false,
    this.isTimeNum = false,
    this.isLight = false,
  });
}

class BitPointMatrix {
  static List<BitPoint> buildFlow(double x, double yi, int len) {
    return List<BitPoint>.generate(len, (i) {
      BitPoint point = BitPoint();
      point.x = x * 1.25;
      point.y = (i - 0.5 - yi) * BitClock.NUM_STEP;
      point.isLast = i == len - 1;
      point.size = len;

      return point;
    });
  }
}

class BitPointRealTime {
  static List<BitPoint> build(double scrw, double scrh) {
    int timePoint1Num;
    int timePoint2Num;
    int timePoint3Num;
    int timePoint4Num;
    int timePoint5Num;
    int timePoint6Num;

    String timePoint12 = DateTime.now().hour.toString();
    if (timePoint12.length == 2) {
      timePoint1Num = int.tryParse(timePoint12.substring(0, 1));
      timePoint2Num = int.tryParse(timePoint12.substring(1, 2));
    } else {
      timePoint1Num = 0;
      timePoint2Num = int.tryParse(timePoint12);
    }

    String timePoint34 = DateTime.now().minute.toString();
    if (timePoint34.length == 2) {
      timePoint3Num = int.tryParse(timePoint34.substring(0, 1));
      timePoint4Num = int.tryParse(timePoint34.substring(1, 2));
    } else {
      timePoint3Num = 0;
      timePoint4Num = int.tryParse(timePoint34);
    }

    String timePoint56 = DateTime.now().second.toString();
    if (timePoint56.length == 2) {
      timePoint5Num = int.tryParse(timePoint56.substring(0, 1));
      timePoint6Num = int.tryParse(timePoint56.substring(1, 2));
    } else {
      timePoint5Num = 0;
      timePoint6Num = int.tryParse(timePoint56);
    }

    double cntrw = scrw / 4.1;
    double cntrh = scrh / 6.5;

    final timePoint1 = BitPointWorldTime.number(timePoint1Num, cntrw - BitClock.NUM_STEP * 21, cntrh);
    final timePoint2 = BitPointWorldTime.number(timePoint2Num, cntrw - BitClock.NUM_STEP * 15, cntrh);

    final delimiter1 = BitPointWorldTime.delimiter(cntrw - BitClock.NUM_STEP * 8, cntrh);

    final timePoint3 = BitPointWorldTime.number(timePoint3Num, cntrw - BitClock.NUM_STEP * 6, cntrh);
    final timePoint4 = BitPointWorldTime.number(timePoint4Num, cntrw - BitClock.NUM_STEP * 0.5, cntrh);

    final delimiter2 = BitPointWorldTime.delimiter(cntrw + BitClock.NUM_STEP * 6.5, cntrh);

    final timePoint5 = BitPointWorldTime.number(timePoint5Num, cntrw + BitClock.NUM_STEP * 9, cntrh);
    final timePoint6 = BitPointWorldTime.number(timePoint6Num, cntrw + BitClock.NUM_STEP * 14, cntrh);

    return timePoint1 +
        timePoint2 +
        delimiter1 +
        timePoint3 +
        timePoint4 +
        delimiter2 +
        timePoint5 +
        timePoint6;
  }
}

class BitPointWorldTime {
  static List<BitPoint> number(int value, double x, double y) {
    switch (value) {
      case 0:
        return (BitPointBrush(x, y)
              ..right(4)
              ..bottom(7)
              ..left(3)
              ..top(6))
            .take();
      case 1:
        return (BitPointBrush(x, y)
              ..jumpRight(3)
              ..right(1)
              ..bottom(7))
            .take();
      case 2:
        return (BitPointBrush(x, y)
              ..right(4)
              ..bottom(3)
              ..left(3)
              ..bottom(4)
              ..right(3))
            .take();
      case 3:
        return (BitPointBrush(x, y)
              ..right(4)
              ..bottom(3)
              ..left(3)
              ..jumpRight(3)
              ..bottom(4)
              ..left(3))
            .take();
      case 4:
        return (BitPointBrush(x, y)
              ..jumpRight(1)
              ..jumpTop(1)
              ..bottom(4)
              ..right(3)
              ..top(3)
              ..jumpBottom(3)
              ..bottom(4))
            .take();
      case 5:
        return (BitPointBrush(x, y)
              ..jumpRight(5)
              ..left(4)
              ..bottom(3)
              ..right(3)
              ..bottom(4)
              ..left(3))
            .take();
      case 6:
        return (BitPointBrush(x, y)
              ..jumpRight(5)
              ..left(4)
              ..bottom(7)
              ..right(3)
              ..top(4)
              ..left(2))
            .take();
      case 7:
        return (BitPointBrush(x, y)
              ..right(4)
              ..bottom(7))
            .take();
      case 8:
        return (BitPointBrush(x, y)
              ..right(4)
              ..bottom(7)
              ..left(3)
              ..top(6)
              ..jumpBottom(2)
              ..right(2))
            .take();
      case 9:
        return (BitPointBrush(x, y)
              ..right(4)
              ..bottom(7)
              ..left(3)
              ..jumpTop(4)
              ..jumpLeft(1)
              ..right(3)
              ..jumpLeft(2)
              ..top(2))
            .take();
      default:
        return [];
    }
  }

  static List<BitPoint> delimiter(double x, double y) => (BitPointBrush(x, y)
        ..bottom(2)
        ..jumpBottom(2)
        ..bottom(2))
      .take();
}

class BitPointBrush {
  final List<BitPoint> _buffer = [];

  double _x = 0;
  double _y = 0;

  BitPointBrush(double x, double y)
      : _x = x,
        _y = y;

  void left(int v) => _buffer
    ..addAll(List<BitPoint>.generate(v, (i) => BitPoint(x: _x -= BitClock.NUM_STEP, y: _y, isTimeNum: true)));
  void right(int v) => _buffer
    ..addAll(List<BitPoint>.generate(v, (i) => BitPoint(x: _x += BitClock.NUM_STEP, y: _y, isTimeNum: true)));
  void top(int v) => _buffer
    ..addAll(List<BitPoint>.generate(v, (i) => BitPoint(x: _x, y: _y -= BitClock.NUM_STEP, isTimeNum: true)));
  void bottom(int v) => _buffer
    ..addAll(List<BitPoint>.generate(v, (i) => BitPoint(x: _x, y: _y += BitClock.NUM_STEP, isTimeNum: true)));

  void jumpLeft(int v) => _x -= BitClock.NUM_STEP * v;
  void jumpRight(int v) => _x += BitClock.NUM_STEP * v;
  void jumpTop(int v) => _y -= BitClock.NUM_STEP * v;
  void jumpBottom(int v) => _y += BitClock.NUM_STEP * v;

  List<BitPoint> take() => _buffer;
}
