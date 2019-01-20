# kitsune


### Notes to self:

String variables can be expanded on demand using `envsubst`
```shell
$ template='hello ${name}'
$ name=Betani envsubst <<< ${template}
hello Betani
```

Prompt variables can be expanded on demand using `${var@P}`
```shell
$ template='[\u@\h \w]> '
$ echo ${template@P}
[betafcc@bulbasaur ~/Desktop]>
```


### References:
- [Bash prompt cheat-sheet](https://ss64.com/bash/syntax-prompt.html)

- [Pure Bash Powerline implementation](https://github.com/chris-marsh/pureline)

- [Escaping invisible chars in prompt SE question (needed for colors)](https://unix.stackexchange.com/questions/105958)

- [Colors and formatting tips](https://misc.flogisoft.com/bash/tip_colors_and_formatting)

- [Small ANSI codes reference](https://bluesock.org/~willkg/dev/ansi.html)

- [Another small ANSI codes reference](http://ascii-table.com/ansi-escape-sequences.php)

- [TLDP Bash Prompt reference (from 2003)](http://www.tldp.org/HOWTO/Bash-Prompt-HOWTO/index.html)

- [Bash Templating SO question](https://stackoverflow.com/questions/2914220)
