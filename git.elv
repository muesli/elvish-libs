#
# Git methods for elvish
#     Copyright (c) 2017-2018, Christian Muehlhaeuser <muesli@gmail.com>
#                              Diego Zamboni <diego@zzamboni.org>
#
#   For license see LICENSE
#
# To use this module, first install it via epm:
#   use epm
#   epm:install github.com/muesli/elvish-libs
#
# Then add the following line to import it somewhere:
#   use github.com/muesli/elvish-libs/git
#

use re

# Return the git branch name of the current directory
fn branch_name {
	out = ""
	err = ?(out = (git branch 2>/dev/null | eawk [line @f]{
				if (eq $f[0] "*") {
					if (and (> (count $f) 2) (eq $f[2] "detached")) {
						replaces ')' '' $f[4]
					} else {
						echo $f[1]
					}
				}
	}))
	put $out
}

# Return how many commits this repo is ahead & behind of master
fn rev_count {
	out = []
	ahead = 0
	behind = 0

	err = ?(out = [(git rev-list --left-right '@{upstream}...HEAD' 2>/dev/null)])
	each [line]{
		if (has-prefix $line ">") {
			ahead = (+ $ahead 1)
		}
		if (has-prefix $line "<") {
			behind = (+ $behind 1)
		}
	} $out

	put $ahead
	put $behind
}

# Return how many files in the current git repo are "dirty" (modified in any way) or untracked
fn change_count {
	out = []
	dirty = 0
	untracked = 0

	err = ?(out = [(git status -s --ignore-submodules=dirty 2>/dev/null)])
	each [line]{
		if (has-prefix $line " M ") {
			dirty = (+ $dirty 1)
		}
		if (has-prefix $line "?? ") {
			untracked = (+ $untracked 1)
		}
	} $out

	put $dirty
	put $untracked
}

# Return how many files in the current git repo are staged
fn staged_count {
	out = []
	err = ?(out = [(git diff --cached --numstat 2>/dev/null)])
	count $out
}

# Automatically "git rm" files which have been deleted from the file
# system. Can be used to clean up when you remove files by hand before
# telling git about it. Use with care.
fn auto-rm {
  git status | each [l]{
    f = [(re:split &max=3 '\s+' $l)]
    if (re:match '^\s*deleted:' $l) {
      echo (edit:styled "Removing "$f[2] red)
      git rm $f[2]
    }
  }
}
