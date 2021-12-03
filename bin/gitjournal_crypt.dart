import 'dart:io';

import 'package:gitjournal_crypt/gitjournal_crypt.dart' as gitjournal_crypt;
import 'package:dart_git/dart_git.dart';

Future<void> main(List<String> arguments) async {
  print('Hello world: ${gitjournal_crypt.calculate()}!');

  if (arguments.isEmpty) {
    print("Arguments empty");
    exit(1);
  }

  var command = arguments.first;
  switch (command) {
    case "clean":
      print("Clean");
      break;

    case "smudge":
      print("smudge");
      break;

    case "init":
      await init();
      break;
  }
}

Future<void> init() async {
  var repoPath = GitRepository.findRootDir(Directory.current.path);
  if (repoPath == null) {
    print(
        'fatal: not a git repository (or any of the parent directories): .git');
    exit(1);
  }

  var repo = await GitRepository.load(repoPath).getOrThrow();
  var section =
      repo.config.section('filter').getOrCreateSection("gitjournal-crypt");

  // FIXME: How to check if a section exists?
  //        Can section names contain spaces?
  //        Add isEmpty for section

  if (section.options.isNotEmpty) {
    print(
        'Error: this repository has already been initialized with git-jcrypt.');
    exit(1);
  }

  section.options['smudge'] = '"git-jcrypt" smudge';
  section.options['clean'] = '"git-jcrypt" clean';

  await repo.saveConfig().throwOnError();

  print("installed");

  // FIXME: Add "gitjournal-crypt section"
  // - Add version and password
  //
}

// I would like tests for all of this
