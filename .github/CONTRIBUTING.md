# Contributing Guidelines

All code in this repository should be neat and tidy.

- Shell scripts should use [https://github.com/mvdan/sh](https://github.com/mvdan/sh)
- YAML should use [https://prettier.io/](https://prettier.io/)

More important than being beautiful is being functional. This repository is primarily shell scripts and YAML files. The shell scripts should all have the Unofficial Bash Strict Mode as outlined here: [https://dev.to/thiht/shell-scripts-matter](https://dev.to/thiht/shell-scripts-matter)

Shell scripts should also be readable and structured as described here: [http://www.kfirlavi.com/blog/2012/11/14/defensive-bash-programming/](http://www.kfirlavi.com/blog/2012/11/14/defensive-bash-programming/)

Google also has a wonderful reference about best practices with shell scripts: [https://google.github.io/styleguide/shell.xml](https://google.github.io/styleguide/shell.xml)

We use Travis CI to run tests on the code in the repo. Code must pass tests run by Travis CI in order to merge to the `master` branch of the repo. Travis CI has a limit on requests to GitHub which can cause certain tests to fail. If this happens we can easily restart the build and try again until we get a true pass or fail.

Try not to do this: [https://en.wikipedia.org/wiki/Cowboy_coding](https://en.wikipedia.org/wiki/Cowboy_coding)
