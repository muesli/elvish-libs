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

# Return how many commits this repo is ahead of master
fn ahead_count {
	out = []
	err = ?(out = [(git rev-list --left-right '@{upstream}...HEAD' 2>/dev/null | grep '>')])
	count $out
}

# Return how many commits this repo is behind of master
fn behind_count {
	out = []
	err = ?(out = [(git rev-list --left-right '@{upstream}...HEAD' 2>/dev/null | grep '<')])
	count $out
}

# Return how many files in the current git repo are staged
fn staged_count {
	out = []
	err = ?(out = [(git diff --cached --numstat 2>/dev/null)])
	count $out
}

# Return how many files in the current git repo are "dirty" (modified in any way)
fn dirty_count {
	out = []
	err = ?(out = [(git status -s --ignore-submodules=dirty 2>/dev/null | grep "M ")])
	count $out
}

# Return how many files in the current git repo are untracked
fn untracked_count {
	out = []
	err = ?(out = [(git status -s --ignore-submodules=dirty 2>/dev/null | grep "?? ")])
	count $out
}
