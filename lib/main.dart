import 'dart:ffi';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui';
import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';

void main() {
  print("welcome to space, ace ! ");
  Directory("/tmp/input")
      .watch(events: FileSystemEvent.all, recursive: true)
      .forEach((element) {
    print("/TMP/INPUT CHANGED!! CHANGE TYPE: $element");
    takeScreenshot();
  });
  runApp(App());
}

final pltData = {
  DateTime(2010, 1, 1): 3,
  DateTime(2011, 1, 1): 1,
  DateTime(2012, 1, 1): 23,
  DateTime(2015, 1, 1): 3,
  DateTime(2020, 1, 1): 32
};

ScreenshotController screenshotController = ScreenshotController();

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final res = MaterialApp(
        debugShowCheckedModeBanner: false,
        theme:
            ThemeData.dark().copyWith(scaffoldBackgroundColor: Colors.blueGrey),
        home: Scaffold(
          // Outer white container with padding
          body: Screenshot(
              controller: screenshotController,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.pink,
                child: Figure(),
              )),
        ));

    takeScreenshot();
    return res;
  }
}

class Figure extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Stack(
      children: <Widget>[
        CustomPaint(
          painter: AxisPainter(),
          size: size,
        ),
        CustomPaint(
          painter: AxisPainter(),
          size: Size(size.width*.5,size.height*.87),
        )
      ],
    );
  }
}

void takeScreenshot() {
  screenshotController.capture().then((Uint8List? image) {
    final len = image!.lengthInBytes;
    print("DEBUG ABOUT TO write a screenshot $len");
    new File("/tmp/plt.test.png").writeAsBytes(image);
  }).catchError((onError) {
    print(onError);
  });
}

class AxisPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final mind = min(size.width, size.height);
    final paintRed = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .03 * mind
      ..color = Colors.red;
    final paintGreen = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .03 * mind
      ..color = Colors.green;
    final thinLine = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.black
      ..strokeWidth = .01 * mind;

    addNormedPathToCanvas(
        canvas,
        scale([
          [.1, .9],
          [.9, .9]
        ], size),
        paintRed);
    addNormedPathToCanvas(
        canvas,
        scale([
          [.1, .9],
          [.1, .1]
        ], size),
        paintGreen);
    final detailedTicksPath = scale([
      [.1, .5],
      [.1, .1],
      [.1, .5],
      [.15, .5],
      [.1, .5],
      [.1, .95],
      [.1, .9],
      [.05, .9],
      [.5, .9],
      [.5, .85],
      [.5, .9],
      [.9, .9]
    ], size);
    addNormedPathToCanvas(canvas, detailedTicksPath, thinLine);
  }

  @override
  bool shouldRepaint(AxisPainter oldDelegate) => false;
}

List<List<double>> scale(List<List<double>> list, ui.Size size) {
  return list
      .map((e) =>
          List<double>.from([size.width * e.first, size.height * e.last]))
      .toList();
}

void addNormedPathToCanvas(Canvas c, List<List<double>> li, Paint paint) {
  final p = Path();
  p.moveTo(li.first.first, li.first.last);
  for (final t in li.sublist(1)) {
    p.lineTo(t.first, t.last);
  }
  c.drawPath(p, paint);
}

Future<void> writeToFile(ByteData data, String path) {
  final buffer = data.buffer;
  return new File(path)
      .writeAsBytes(buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
}
