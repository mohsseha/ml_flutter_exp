import 'dart:developer';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui';
import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';

void main() {
  Directory("/tmp/input")
      .watch(events: FileSystemEvent.all, recursive: true)
      .forEach((element) {
    print("/TMP/INPUT CHANGED!! CHANGE TYPE: $element");
    takeScreenshot();
  });
  runApp(App());
}

final rnd = math.Random();
final pltData = {
  for (var i = 0; i < 10; i++)
    DateTime(2010).add(Duration(days: rnd.nextInt(3650))): rnd.nextInt(32).toDouble()
};

class Range {
  final num start, end;

  Range(this.start, this.end) {
    assert(start < end);
  }

  @override
  String toString() {
    return "Range($start,$end)";
  }
}

class FigConfig {
  var normAxOffX = .1,
      normAxOffY = 0.1,
      normAxMxX = 0.9,
      normAxMxY = .9,
      normAxTickLn = 0.05;
  var ticksX = [
    DateTime(2011, 1, 1),
    DateTime(2007, 1, 1),
    DateTime(2016),
    DateTime(2020)
  ];
  var ticksY = [0, 5, 30];
  var dataRangeX = Range(DateTime(2010).microsecondsSinceEpoch,
      DateTime(2021).microsecondsSinceEpoch);
  var dataRangeY = Range(0, 35);
}

final figConfig=FigConfig();
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
                color: Colors.blueGrey,
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
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.rotationX(math.pi),
      child: Stack(children: <Widget>[
        for (var p in [ BarPainter(), PointPainter(),AxisPainter()])
          CustomPaint(painter: p, size: size)
      ]),
    );
  }
}

void takeScreenshot() {
  screenshotController.capture().then((Uint8List? image) {
    final len = image!.lengthInBytes;
    print("wrote screenshot $len👍");
    new File("/tmp/plt.test.png").writeAsBytes(image);
  }).catchError((onError) {
    print(onError);
  });
}

class AxisPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cfg = FigConfig();
    final mind = math.min(size.width, size.height);
    final paintRed = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .03 * mind
      ..color = Colors.red;
    final paintGreen = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .03 * mind
      ..color = Colors.green;
    final paintBlack = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.black
      ..strokeWidth = .01 * mind;

    //Vars to simplify the lines;
    final blx = cfg.normAxOffX,
        bly = cfg.normAxOffY,
        mxx = cfg.normAxMxX,
        mxy = cfg.normAxMxY,
        tk = cfg.normAxTickLn;

    addPathToCanvas(
        canvas,
        scaleNormToSize([
          [blx - tk, bly],
          [mxx, bly]
        ], size),
        paintRed);
    addPathToCanvas(
        canvas,
        scaleNormToSize([
          [blx, bly - tk],
          [blx, mxy]
        ], size),
        paintGreen);

    addHorizontalTicks(canvas,size,paintBlack);
    addVerticalTicks(canvas,size,paintBlack);

  }

  @override
  bool shouldRepaint(AxisPainter oldDelegate) => false;

  void addHorizontalTicks(ui.Canvas canvas, ui.Size size, ui.Paint paintBlack) {
    final w=size.width,h=size.height;
    Map<DateTime,double>.fromIterables(figConfig.ticksX,
        figConfig.ticksX.map((e) => e.microsecondsSinceEpoch.toDouble()).map((e) => null)
    )
    figConfig.ticksX.forEach((e) {
      final xPos=
      canvas.save();
      TextSpan span = new TextSpan(style: new TextStyle(color: Colors.blue[800],fontSize: 12), text: "${e.year}/${e.month}");
      TextPainter tp = new TextPainter(text: span, textAlign: TextAlign.center, textDirection: TextDirection.ltr);
      tp.layout();
      canvas.translate(.5*size.width, h*(figConfig.normAxOffY-figConfig.normAxTickLn));
      canvas.transform(Matrix4.rotationX(math.pi).storage);
      tp.paint(canvas, Offset.zero);
      canvas.restore();


    })



  }
}

List<List<double>> scaleNormToSize(List<List<double>> list, ui.Size size) {
  return list
      .map((e) =>
          List<double>.from([size.width * e.first, size.height * e.last]))
      .toList();
}

void addPathToCanvas(Canvas c, List<List<double>> li, Paint paint) {
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

class PointPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cfg = FigConfig(),
        w = size.width,
        h = size.height,
        mind = math.min(w, h);
    final viewRect = Rect.fromLTRB(w * cfg.normAxOffX, h * cfg.normAxOffY,
        w * cfg.normAxMxX, h * cfg.normAxMxY);
    canvas.clipRect(viewRect);

    final paintPink = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = .03 * mind
      ..color = Colors.pink;

    scaledDataToPx({
      for (var k in pltData.keys)
        k.microsecondsSinceEpoch.toDouble(): pltData[k]!
    }, cfg, size)
        .forEach((x, y) {
      canvas.drawCircle(Offset(x, y), .02 * mind, paintPink);
    });
  }

  @override
  bool shouldRepaint(PointPainter oldDelegate) => false;
}

Map<double, double> scaledDataToPx(
    Map<double, double> data, FigConfig cfg, Size size) {
  final w = size.width,
      h = size.height,
      toRangeX = Range(w * cfg.normAxOffX, w * cfg.normAxMxX),
      toRangeY = Range(h * cfg.normAxOffY, h * cfg.normAxMxY);

  final frmRgX = cfg.dataRangeX, frmRgY = cfg.dataRangeY;
  return Map<double, double>.fromIterables(
      scaleData(frmRgX, data.keys, toRangeX),
      scaleData(frmRgY, data.values, toRangeY));
}

Iterable<double> scaleData(
    Range frmRange, Iterable<double> col, Range toRange) {
  return col.map((e) =>
      toRange.start +
      (e - frmRange.start) *
          (toRange.end - toRange.start) /
          (frmRange.end - frmRange.start));
}

Range rangeOf(Iterable<double> column) {
  var mn = column.first, mx = mn;
  column.forEach((element) {
    mn = math.min(mn, element);
    mx = math.max(mx, element);
  });
  if (mn == mx) {
    mx = 1.1 * mn;
    mn = 0.9 * mn;
  }
  return Range(mn, mx);
}

class BarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cfg = FigConfig(), w = size.width, h = size.height;
    final viewRect = Rect.fromLTRB(w * cfg.normAxOffX, h * cfg.normAxOffY,
        w * cfg.normAxMxX, h * cfg.normAxMxY);
    canvas.clipRect(viewRect);

    final greenPainter = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.brown;

    final dataInPx = scaledDataToPx({
      for (var k in pltData.keys)
        k.microsecondsSinceEpoch.toDouble(): pltData[k]!
    }, cfg, size);
    final sortedXs = dataInPx.keys.toList();
    sortedXs.sort();
    for (var i = 0; i < sortedXs.length - 1; i++) {
      final x = sortedXs[i], xn = sortedXs[i + 1], y = dataInPx[xn];
      var rect = Rect.fromLTRB(x, viewRect.top, xn, y!);
      log("rect= $rect");
      canvas.drawRect(rect, greenPainter);
    }
  }

  @override
  bool shouldRepaint(BarPainter oldDelegate) => false;
}
