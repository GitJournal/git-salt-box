import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'package:git_salt_box/git_salt_box.dart';

void main() {
  test('calculate', () {
    var content = "Random\nFile\n";
    var filePath = p.join(Directory.systemTemp.path, 'list-objects');
    File(filePath).writeAsStringSync(content);

    var box = GitSaltBox(
      password: base64.decode('d68FT2ZcozhNIogMp8aXeQumeW3j+WJgzdipB/Bs5Dw='),
    );
    var encMsg = box.encrypt(filePath, utf8.encode(content));
    var origContent = box.decrypt(encMsg);

    expect(utf8.decode(origContent), content);
  });
}
