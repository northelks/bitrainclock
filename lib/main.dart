import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// size of number
double bitsize = 15.0;
// current time
DateTime now;

void main() {
  if (Platform.isIOS) {
    runApp(BitrainClock());
  } else {
    WidgetsFlutterBinding.ensureInitialized();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIOverlays([]).then((_) {
      runApp(BitrainClock());
    });
  }
}

class BitrainClock extends StatefulWidget {
  @override
  _BitrainClockState createState() => _BitrainClockState();
}

class _BitrainClockState extends State<BitrainClock> {
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
              child: BitrainClockWorld(),
            ),
          ),
        ),
      ),
    );
  }
}

class BitrainClockWorld extends StatefulWidget {
  @override
  _BitrainClockWorldState createState() => _BitrainClockWorldState();
}

class _BitrainClockWorldState extends State<BitrainClockWorld> {
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

    void runworld() {
      now = DateTime.now();

      int sec = 0;
      // run global tick
      timer = Timer.periodic(Duration(milliseconds: 100), (_) {
        if (sec != now.second) {
          sec = now.second;
          dirty = true;
        }

        update();
        setState(() => now = DateTime.now());
      });

      // for dev test
      // Future.delayed(Duration(seconds: 17), () => timer.cancel());
    }

    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        splash = false;
      });

      Future.delayed(Duration(seconds: 2), runworld);
    });
  }

  // update world
  void update() {
    double yi() => Random().nextInt(10) * 1.0;

    if (world.isEmpty) {
      // build left one column-flow to "show" time number
      world..addAll(BitPointMatrix.buildFlow(5.0, yi(), 8));
      // build time numbers
      world..addAll(BitPointRealTime.build(scrw, scrh));
    }

    if (dirty && !lock) {
      // time is running and we need to render new second and all time numbers
      for (var i = 0; i < world.length; i++) {
        if (world[i].isTimeNum) world.removeAt(i);
      }
      world..addAll(BitPointRealTime.build(scrw, scrh).map((p) => p..isLight = true).toList());
      dirty = false;
    }

    // keep world populated with required count of the numbers
    if (world.length < 1200) {
      for (var i = 0; i < (scrw / 10).floor(); i++) {
        int len = 7 + Random().nextInt(20 - 7);
        world..addAll(BitPointMatrix.buildFlow(5.0 + (i * 15), yi() + len * 2, len));
      }
    }

    for (var i = 0; i < world.length; i++) {
      if (world[i].isTimeNum) {
        if (world[7].y >= world[i].y) {
          // show time number by the left first column-flow
          world[i].isLight = true;
        }

        continue;
      }

      // move flow
      world[i].y += bitsize;

      // remove number which came out of the screen area
      if (world[i].y > scrh) {
        world.removeAt(i);
        lock = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    scrh = size.height;
    scrw = size.width;

    // yeah, the magic for iOS 8 and 11 o_O
    if (scrw != 667) bitsize = 15.0 * scrw / 667;
    if (scrw >= 896) bitsize = 13.5;

    return Stack(children: [
      Center(
        child: AnimatedOpacity(
          duration: Duration(seconds: 2),
          opacity: splash ? 1.0 : 0.0,
          child: Image.asset('bitrainclock-label.png'),
        ),
      ),
      if (!splash)
        ...world.map((point) {
          int value = Random().nextInt(10);
          // one number too thin
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
      point.y = (i - 0.5 - yi) * bitsize;
      point.isLast = i == len - 1;
      point.size = len;

      return point;
    });
  }
}

class BitPointRealTime {
  static List<BitPoint> build(double scrw, double scrh) {
    int timePointH1;
    int timePointH2;
    int timePointM1;
    int timePointM2;
    int timePointS1;
    int timePointS2;

    if (now.hour <= 9) {
      timePointH1 = 0;
      timePointH2 = now.hour;
    } else {
      timePointH1 = int.tryParse(now.hour.toString().substring(0, 1));
      timePointH2 = int.tryParse(now.hour.toString().substring(1, 2));
    }

    if (now.minute <= 9) {
      timePointM1 = 0;
      timePointM2 = now.minute;
    } else {
      timePointM1 = int.tryParse(now.minute.toString().substring(0, 1));
      timePointM2 = int.tryParse(now.minute.toString().substring(1, 2));
    }

    if (now.second <= 9) {
      timePointS1 = 0;
      timePointS2 = now.second;
    } else {
      timePointS1 = int.tryParse(now.second.toString().substring(0, 1));
      timePointS2 = int.tryParse(now.second.toString().substring(1, 2));
    }

    double cntrh = (scrh / 2) - bitsize * 4;

    // yeah, the magic for iOS 8 and 11 o_O
    if (scrw >= 896) scrw = scrw * 0.74;
    if (scrw >= 812) scrw = scrw * 0.95;
    if (scrw >= 667) scrw = scrw * 0.97;
    if (scrw >= 640) scrw = scrw * 1.03;

    return BitPointWorldTime.number(timePointH1, 20, cntrh) +
        BitPointWorldTime.number(timePointH2, 40 + bitsize * 4, cntrh) +
        // delimiter
        BitPointWorldTime.delimiter((scrw / 2) - bitsize * 9, cntrh) +
        //
        BitPointWorldTime.number(timePointM1, (scrw / 2) - bitsize * 7, cntrh) +
        BitPointWorldTime.number(timePointM2, (scrw / 2) - bitsize, cntrh) +
        // delimiter
        BitPointWorldTime.delimiter(scrw - (bitsize * 16.5), cntrh) +
        //
        BitPointWorldTime.number(timePointS1, scrw - ((bitsize * 8) + 100), cntrh) +
        BitPointWorldTime.number(timePointS2, scrw - ((bitsize * 4) + 80), cntrh);
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

  void left(int v) =>
      _buffer..addAll(List<BitPoint>.generate(v, (i) => BitPoint(x: _x -= bitsize, y: _y, isTimeNum: true)));
  void right(int v) =>
      _buffer..addAll(List<BitPoint>.generate(v, (i) => BitPoint(x: _x += bitsize, y: _y, isTimeNum: true)));
  void top(int v) =>
      _buffer..addAll(List<BitPoint>.generate(v, (i) => BitPoint(x: _x, y: _y -= bitsize, isTimeNum: true)));
  void bottom(int v) =>
      _buffer..addAll(List<BitPoint>.generate(v, (i) => BitPoint(x: _x, y: _y += bitsize, isTimeNum: true)));

  void jumpLeft(int v) => _x -= bitsize * v;
  void jumpRight(int v) => _x += bitsize * v;
  void jumpTop(int v) => _y -= bitsize * v;
  void jumpBottom(int v) => _y += bitsize * v;

  List<BitPoint> take() => _buffer;
}
