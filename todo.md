* Implement each filter
* Implement all the boilerplate
* First use the git executable whereever needed
* After that you can slowly get rid of all of it
* Add tests to make sure it does the exact same thing as the git executable
  - this goes in dart-git
* Need the git attribute parser

---
* Fetch the password from the config
* Abstract out the FileSystem

* Use proper libsodium if present instead of this dart version


---

* Fetch the password from the config
* Ensure that git-salt-box has been installed
* Check if already encrypted
* Print the argument list when no arguments are provided
* Avoid reading the entire file into memory
  - Do this in chunks
  - But still sync
