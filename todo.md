* Need the git attribute parser

---
* Abstract out the FileSystem
  - The library doesn't need to ever use the File System

* Use proper libsodium if present instead of this dart version

---

* Print the argument list when no arguments are provided
* Avoid reading the entire file into memory
  - Do this in chunks
  - But still sync

* Implement the merge filter using git's merge-file
* Implement long lived process for smudge/clean

* list (for listing encrypted files)
* add
* rm
* lock / unlock
* unlock can take an optional password
