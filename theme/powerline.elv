#
# Powerline prompt theme
#     Copyright (c) 2017-2018, Christian Muehlhaeuser <muesli@gmail.com>
#
# Based on chain.elv by Diego Zamboni <diego@zzamboni.org>
#
# To use this theme, first install it via epm:
#   use epm
#   epm:install github.com/muesli/elvish-libs
#
# Then add the following lines to your ~/.elvish/rc.elv file:
#   use github.com/muesli/elvish-libs/theme/powerline
#   powerline:setup
#
# You can also assign the prompt functions manually instead of calling `powerline:setup`:
#   edit:prompt = $powerline:&prompt
#   edit:rprompt = $powerline:&rprompt
#
# The chains on both sides can be configured by assigning to `powerline:prompt-segments` and
# `powerline:rprompt-segments`, respectively. These variables must be arrays, and the given
# segments will be automatically linked by `$powerline:glyph[chain]`. Each element can be any
# of the following:
#
# - The name of one of the built-in segments. Available segments:
#     `newline` `user` `host` `arrow` `timestamp` `dir`
#     `git-branch` `git-ahead` `git-behind` `git-staged` `git-dirty` `git-untracked`
# - A string or the output of `styled`, which will be displayed as-is.
# - A lambda, which will be called and its output displayed
# - The output of a call to `powerline:segment <style> <strings>`, which returns a "proper"
#   segment, enclosed in prefix and suffix and styled as requested.
#

use re
use str

use github.com/muesli/elvish-libs/git

# Default values (all can be configured by assigning to the appropriate variable):

# Configurable prompt segments for each prompt
prompt-segments = [
	host
	dir
	virtualenv
	git-branch
	git-ahead
	git-behind
	git-staged
	git-dirty
	git-untracked
	newline
	timestamp
	user
	arrow
]
rprompt-segments = [ ]

# Glyphs to be used in the prompt
glyph = [
	&prefix= " "
	&suffix= " "
	&arrow= ""
	&git-branch= "⎇"
	&git-ahead= "⬆"
	&git-behind= "⬇"
	&git-staged= "✔"
	&git-dirty= "✎"
	&git-untracked= "+"
	&su= "⚡"
	&chain= ""
	&dirchain= ""
	&virtualenv= "🐍"
]

# Styling for each built-in segment. The value must be a valid argument to `styled`
segment-style-fg = [
	&arrow= "0"
	&su= "15"
	&dir= "15"
	&user= "250"
	&host= "254"
	&host-short= "254"
	&git-branch= "0"
	&git-ahead= "15"
	&git-behind= "15"
	&git-staged= "15"
	&git-dirty= "15"
	&git-untracked= "15"
	&timestamp= "250"
	&virtualenv= "226"
]

segment-style-bg = [
	&default= "transparent"
	&arrow= (+ (% $pid 216) 16)
	&su= "161"
	&dir= "31"
	&user= "240"
	&host= "166"
	&host-short= "166"
	&git-branch= "148"
	&git-ahead= "52"
	&git-behind= "52"
	&git-staged= "22"
	&git-dirty= "161"
	&git-untracked= "52"
	&timestamp= "238"
	&virtualenv= "12"
]

# To how many letters to abbreviate directories in the path - 0 to show in full
prompt-pwd-dir-length = 3

# Format to use for the 'timestamp' segment, in strftime(3) format
timestamp-format = "%H:%M:%S"

# User ID that will trigger the "su" segment. Defaults to root.
root-id = 0

######################################################################
fn -log [@msg]{
	echo (date) $@msg >> /tmp/powerline-debug.log
}

# Return the current directory, shortened according to `$prompt-pwd-dir-length`
fn prompt-pwd {
	dir = (tilde-abbr $pwd)
	if (> $prompt-pwd-dir-length 0) {
		dir = (re:replace '(\.?[^/]{'$prompt-pwd-dir-length'})[^/]*/' '$1/' $dir)
	}
	str:split / $dir | str:join ' '$glyph[dirchain]' '
}

fn session-color-picker {
  if (>= (% (- $segment-style-bg[arrow] 16) 36) 18) {
    segment-style-fg[arrow] = 232
  } else {
    segment-style-fg[arrow] = 255
  }
}

######################################################################
fn -prompt-builder {
	# last-bg is the background color of the last printed segment
	last-bg = $segment-style-bg[default]

	fn -colorprint [what fg bg]{
		fn st [seg]{
			if (eq $bg "transparent") {
				styled-segment $seg &fg-color="color"$fg
			} else {
				styled-segment $seg &fg-color="color"$fg &bg-color="color"$bg
			}
		}
		styled $what $st~
		last-bg = $bg
	}

	# Build a prompt segment in the given style, surrounded by square brackets
	fn prompt-segment [fg bg @texts]{
		text = $glyph[prefix](str:join ' ' $texts)$glyph[suffix]
		-colorprint $text $fg $bg
	}

	######################################################################
	# cached git status
	last-git-status = [&]

	fn -parse-git {
		last-git-status = (git:status &counts=$true)
	}

	######################################################################
	# Built-in chain segments

	fn segment-newline {
		put "\n"
	}

	fn segment-dir {
		prompt-segment $segment-style-fg[dir] $segment-style-bg[dir] (prompt-pwd)
	}

	fn segment-user {
		prompt-segment $segment-style-fg[user] $segment-style-bg[user] (whoami)
	}

	fn segment-host {
		prompt-segment $segment-style-fg[host] $segment-style-bg[host] (hostname)
	}

	fn segment-host-short {
		prompt-segment $segment-style-fg[host-short] $segment-style-bg[host-short] (hostname --short)
	}

	fn segment-git-branch {
		branch = $last-git-status[branch-name]
		if (not-eq $branch "") {
			if (eq $branch '(detached)') {
				branch = $last-git-status[branch-oid][0..7]
			}
			prompt-segment $segment-style-fg[git-branch] $segment-style-bg[git-branch] $glyph[git-branch] $branch$glyph[suffix]
		}
	}

	fn segment-git-ahead {
		if (> $last-git-status[rev-ahead] 0) {
			prompt-segment $segment-style-fg[git-ahead] $segment-style-bg[git-ahead] $last-git-status[rev-ahead]$glyph[git-ahead]
		}
	}

	fn segment-git-behind {
		if (> $last-git-status[rev-behind] 0) {
			prompt-segment $segment-style-fg[git-behind] $segment-style-bg[git-behind] $last-git-status[rev-behind]$glyph[git-behind]
		}
	}

	fn segment-git-staged {
		total-staged = (+ $last-git-status[staged-modified-count staged-deleted-count staged-added-count renamed-count copied-count])
		if (> $total-staged 0) {
			prompt-segment $segment-style-fg[git-staged] $segment-style-bg[git-staged] $total-staged$glyph[git-staged]
		}
	}

	fn segment-git-dirty {
		if (> $last-git-status[local-modified-count] 0) {
			prompt-segment $segment-style-fg[git-dirty] $segment-style-bg[git-dirty] $last-git-status[local-modified-count]$glyph[git-dirty]
		}
	}

	fn segment-git-untracked {
		if (> $last-git-status[untracked-count] 0) {
			prompt-segment $segment-style-fg[git-untracked] $segment-style-bg[git-untracked] $last-git-status[untracked-count]$glyph[git-untracked]
		}
	}

	fn segment-arrow {
		uid = (id -u)
		if (eq $uid $root-id) {
			prompt-segment $segment-style-fg[su] $segment-style-bg[su] $glyph[su]
		} else {
			prompt-segment $segment-style-fg[arrow] $segment-style-bg[arrow] $glyph[arrow]
		}
	}

	fn segment-timestamp {
		prompt-segment $segment-style-fg[timestamp] $segment-style-bg[timestamp] (date +$timestamp-format)
	}

	fn segment-virtualenv {
		if (not-eq $E:VIRTUAL_ENV "") {
			prompt-segment $segment-style-fg[user] $segment-style-bg[user] $glyph[virtualenv](re:replace '\/.*\/' ''  $E:VIRTUAL_ENV)
		}
	}

	# List of built-in segments
	segment = [
		&newline= $segment-newline~
		&dir= $segment-dir~
		&user= $segment-user~
		&host= $segment-host~
		&host-short= $segment-host-short~
		&git-branch= $segment-git-branch~
		&git-ahead= $segment-git-ahead~
		&git-behind= $segment-git-behind~
		&git-staged= $segment-git-staged~
		&git-dirty= $segment-git-dirty~
		&git-untracked= $segment-git-untracked~
		&arrow= $segment-arrow~
		&timestamp= $segment-timestamp~
		&virtualenv= $segment-virtualenv~
	]

	# Given a segment specification, return the appropriate value, depending
	# on whether it's the name of a built-in segment, a lambda, a string
	# or an styled
	fn -interpret-segment [seg]{
		k = (kind-of $seg)
		if (eq $k fn) {
			# If it's a lambda, run it
			$seg
		} elif (eq $k string) {
			if (has-key $segment $seg) {
				# If it's the name of a built-in segment, run its function
				$segment[$seg]
			} else {
				# If it's any other string, return it as-is
				put $seg
			}
		} elif (eq $k styled) {
			# If it's an styled, return it as-is
			put $seg
		}
	}

	# Return a string of values, including the appropriate chain connectors
	fn -build-chain [segments]{
		if (== (count $segments) 0) {
			return
		}

		first = $true
		output = ""
		-parse-git

		for seg $segments {
			lbg = $last-bg
			measured-time = (time { output = [(-interpret-segment $seg)] })
			# -log $pwd segment-$seg $measured-time
			if (> (count $output) 0) {
				if (not $first) {
					if (not (eq $seg "newline")) {
						-colorprint $glyph[chain] $lbg $last-bg
					} else {
						-colorprint $glyph[chain] $lbg $segment-style-bg[default]
					}
				}
				put $@output
				if (not (eq $seg "newline")) {
					first = $false
				} else {
					first = $true
				}
			}
		}
		-colorprint $glyph[chain]" " $last-bg $segment-style-bg[default]
	}

	put $-build-chain~
}

-build-prompt~ = (-prompt-builder)
-build-rprompt~ = (-prompt-builder)

# Prompt and rprompt functions (careful, they will be executed concurrently)
fn prompt {
	-build-prompt $prompt-segments
}

fn rprompt {
	-build-rprompt $rprompt-segments
}

# Default init, assigning our functions to `edit:prompt` and `edit:rprompt`
fn init {
	session-color-picker
	edit:prompt = $prompt~
	edit:rprompt = $rprompt~
}

init
