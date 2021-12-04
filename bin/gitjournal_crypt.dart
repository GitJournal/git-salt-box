import 'dart:io';
import 'dart:math';

// import 'package:gitjournal_crypt/gitjournal_crypt.dart' as gitjournal_crypt;
import 'package:dart_git/dart_git.dart';

Future<void> main(List<String> arguments) async {
  // print('Hello world: ${gitjournal_crypt.calculate()}!');

  if (arguments.isEmpty) {
    print("Arguments empty");
    exit(1);
  }

  var command = arguments.first;
  switch (command) {
    // Encrypt the file
    case "clean":
      print("Clean");
      break;

    // Decrypt the file
    case "smudge":
      print("smudge");
      break;

    case "init":
      await init();
      break;
  }
}

const _execName = "git-journal-crypt";
const _version = "0.0.1";

Future<void> init() async {
  var repoPath = GitRepository.findRootDir(Directory.current.path);
  if (repoPath == null) {
    print(
        'fatal: not a git repository (or any of the parent directories): .git');
    exit(1);
  }

  var repo = await GitRepository.load(repoPath).getOrThrow();
  var section = repo.config
      .getOrCreateSection('filter')
      .getOrCreateSection("git-journal-crypt");

  if (section.isNotEmpty) {
    print(
        'Error: this repository has already been initialized with git-journal-crypt.');
    exit(1);
  }

  section.options['smudge'] = '"$_execName" smudge';
  section.options['clean'] = '"$_execName" clean';

  var gjSection = repo.config.getOrCreateSection(_execName);
  gjSection.options["version"] = _version;
  gjSection.options["password"] = _generatePassword();

  var r = await repo.saveConfig();
  if (r.isFailure) {
    print(r.stackTrace);
    exit(1);
  }
}

// Wouldn't it be better to generate a more secure password and just base64 encode it?
String _generatePassword() {
  const _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';

  var _rnd = Random.secure();
  var length = 32;

  return String.fromCharCodes(Iterable.generate(
      length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));
}
