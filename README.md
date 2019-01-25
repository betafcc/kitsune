# kitsune


### Notes to self:

String variables can be expanded on demand using `envsubst`
```shell
$ template='hello ${name}'
$ name=Betani envsubst <<< ${template}
hello Betani
```

Since Bash 4.4, prompt variables can be expanded on demand using `${var@P}`
```shell
$ template='[\u@\h \w]> '
$ echo ${template@P}
[betafcc@bulbasaur ~/Desktop]>
```

Actually also expand templates (more performant than `envsubst`):
```shell
$ template='hello ${name}'
$ name=Betani eval 'echo ${template@P}'
hello Betani

# Also work without eval, just need to expose the variable to the env
$ name=Betani  # exposed to shell
$ echo "${template@P}"  # then it works here
hello Betani
```

Possibles aproaches to parallelization:
- [use of `coproc`](https://stackoverflow.com/a/20018504)

- [more on coprocess](https://unix.stackexchange.com/questions/86270/how-do-you-use-the-command-coproc-in-various-shells)

- [Capturing output of find . -print0 into a bash array](https://stackoverflow.com/a/1120952)

- [bash background process modify global variable](https://stackoverflow.com/a/13209479)


### References:
- [Bash handbook](https://github.com/denysdovhan/bash-handbook)

- [Bash manual on prompt](https://www.gnu.org/software/bash/manual/bash.html#Controlling-the-Prompt)

- [Bash prompt cheat-sheet](https://ss64.com/bash/syntax-prompt.html)

- [Pure Bash Powerline implementation](https://github.com/chris-marsh/pureline)

- [Escaping invisible chars in prompt SE question (needed for colors)](https://unix.stackexchange.com/questions/105958)

- [Colors and formatting tips](https://misc.flogisoft.com/bash/tip_colors_and_formatting)

- [Small ANSI codes reference](https://bluesock.org/~willkg/dev/ansi.html)

- [Another small ANSI codes reference](http://ascii-table.com/ansi-escape-sequences.php)

- [TLDP Bash Prompt reference (from 2003)](http://www.tldp.org/HOWTO/Bash-Prompt-HOWTO/index.html)

- [Bash Templating SO question](https://stackoverflow.com/questions/2914220)
