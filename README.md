hyperclick-robot-framework
==========
Provides **go to definition** functionality for Robot Framework files

![Demo](https://raw.githubusercontent.com/gliviu/hyperclick-robot-framework/master/gotodef.gif)

```shell
apm install language-robot-framework
apm install autocomplete-robot-framework
apm install hyperclick
apm install hyperclick-robot-framework
```

Hold Ctrl while hovering the mouse or use 'ctrl-alt-enter' (windows & linux) to highlight keywords and open the definition.
Check out  [Hyperclick](https://atom.io/packages/hyperclick) for more information.

This package depends on [autocomplete-robot-framework](https://atom.io/packages/autocomplete-robot-framework) for keyword informatio. Various settings can be toggled in that package.

One important configuration that affects go to definition is 'exclude directories'. Sometimes one keyword may be found in more than one robot resource resulting in hyperclick showing multiple sources. Excluding directories can be controlled from [autocomplete-robot-framework](https://atom.io/packages/autocomplete-robot-framework) settings.

## Changelog
* v1.6.0 Added support for dot notation (ie. Library.keyword)
* v1.5.0 Hyperclick into imports
* v1.3.0 Auto download Atom dependencies using [package-deps](https://github.com/steelbrain/package-deps)
* v1.2.0 Hyperclick into python libraries
