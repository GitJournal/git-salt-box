import 'package:pinenacl/ed25519.dart';
import 'package:qr/qr.dart';

String printQr(Uint8List input) {
  final qrCode = QrCode.fromUint8List(
    data: input,
    errorCorrectLevel: QrErrorCorrectLevel.L,
  );

  var whiteB = '\x1b[107m';
  var blackB = '\x1b[40m';
  var whiteSquare = '⬜';
  var blackSquare = '⬛';

  var white = whiteB + whiteSquare;
  var black = blackB + blackSquare;

  var reset = "\x1b[m";

  var qrImage = QrImage(qrCode);
  var width = qrImage.moduleCount;
  int margin = 2;

  var output = '';

  output += _margin(margin, margin, width, white, reset);

  for (int y = 0; y < qrImage.moduleCount; y++) {
    var line = '';

    for (var x = 0; x < margin; x++) {
      line += white;
    }

    for (int x = 0; x < width; x++) {
      line += qrImage.isDark(y, x) ? black : white;
    }

    for (var x = 0; x < margin; x++) {
      line += white;
    }

    line += reset;
    output += line + '\n';
  }

  output += _margin(margin, margin, width, white, reset);

  return output;
}

String _margin(
  int horzMargin,
  int verticalMargin,
  int width,
  String char,
  String reset,
) {
  var output = '';
  for (int y = 0; y < verticalMargin; y++) {
    var line = '';
    for (var x = 0; x < width + horzMargin * 2; x++) {
      line += char;
    }
    line += reset;
    output += line;
    output += '\n';
  }
  return output;
}
