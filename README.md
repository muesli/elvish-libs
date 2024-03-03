# elvish-libs
Libs & Themes for [elvish](https://github.com/elves/elvish)

## Install

Make sure you run elvish 0.20 or newer. Install this module by running the
following commands in your shell:

```
use epm
epm:install github.com/muesli/elvish-libs
```

## Themes

### powerline

![powerline](screenshots/powerline.png)

To use the `powerline` theme, put this line in your `rc.elv`:

```
use github.com/muesli/elvish-libs/theme/powerline
set edit:prompt-stale-transform = {|x| put $x }
set edit:rprompt-stale-transform = {|x| put $x }
```

## Modules

### git

The `git` module provides convenient elvish functions to extract stats from a
git repository. It lets you query the repo how many commits you are ahead or
behind of master and how many files have been changed or added to it.

Enjoy!
