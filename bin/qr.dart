import 'package:qr/qr.dart';

String printQr(String input) {
  final qrCode = QrCode.fromData(
    data: input,
    errorCorrectLevel: QrErrorCorrectLevel.L,
  );

  var whiteB = '\x1b[30;107m';
  // var blackB = '\x1b[40;100m';

  var lowerB = '\u{2584}';
  var upperB = '\u{2580}';
  var fullB = '\u{2588}';
  var empty = ' ';

  var reset = "\x1b[m";

  var qrImage = QrImage(qrCode);
  var width = qrImage.moduleCount;
  int margin = 2;

  var output = '';

  output += _margin(margin * 2, margin, width, whiteB + empty, reset);

  for (int y = 0; y < width; y += 2) {
    var line = '';

    for (var x = 0; x < margin * 2; x++) {
      line += whiteB + empty;
    }

    for (int x = 0; x < width; x++) {
      var isDark = qrImage.isDark(y, x);
      var darkBelow = y + 1 == width ? false : qrImage.isDark(y + 1, x);
      if (isDark) {
        if (darkBelow) {
          line += whiteB + fullB;
        } else {
          line += whiteB + upperB;
        }
      } else {
        if (darkBelow) {
          line += whiteB + lowerB;
        } else {
          line += whiteB + empty;
        }
      }
    }

    for (var x = 0; x < margin * 2; x++) {
      line += whiteB + empty;
    }

    line += reset;
    output += line + '\n';
  }

  output += _margin(margin * 2, margin, width, whiteB + empty, reset);

  return output.trimRight();
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
