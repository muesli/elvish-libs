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
# The chains on both sides can be configured by assigning to `powerline:prompt_segments` and
# `powerline:rprompt_segments`, respectively. These variables must be arrays, and the given
# segments will be automatically linked by `$powerline:glyph[chain]`. Each element can be any
# of the following:
#
# - The name of one of the built-in segments. Available segments:
#     `newline` `user` `host` `arrow` `timestamp` `dir`
#     `git_branch` `git_ahead` `git_behind` `git_staged` `git_dirty` `git_untracked`
# - A string or the output of `edit:styled`, which will be displayed as-is.
# - A lambda, which will be called and its output displayed
# - The output of a call to `powerline:segment <style> <strings>`, which returns a "proper"
#   segment, enclosed in prefix and suffix and styled as requested.
#

use re

use github.com/muesli/elvish-libs/git

# Default values (all can be configured by assigning to the appropriate variable):

# Configurable prompt segments for each prompt
prompt_segments = [
	host
	dir
	virtualenv
	git_branch
	git_ahead
	git_behind
	git_staged
	git_dirty
	git_untracked
	newline
	timestamp
	user
	arrow
]
rprompt_segments = [ ]

# Glyphs to be used in the prompt
glyph = [
	&prefix= " "
	&suffix= " "
	&arrow= "$"
	&git_branch= "⎇"
	&git_ahead= "⬆"
	&git_behind= "⬇"
	&git_staged= "✔"
	&git_dirty= "✎"
	&git_untracked= "+"
	&su= "⚡"
	&chain= ""
	&dirchain= ""
	&virtualenv= "🐍"
]

# Styling for each built-in segment. The value must be a valid argument to `edit:styled`
segment_style_fg = [
	&arrow= "15"
	&su= "15"
	&dir= "15"
	&user= "250"
	&host= "254"
	&git_branch= "0"
	&git_ahead= "15"
	&git_behind= "15"
	&git_staged= "15"
	&git_dirty= "15"
	&git_untracked= "15"
	&timestamp= "250"
	&virtualenv= "226"
]

segment_style_bg = [
	&arrow= "22"
	&su= "161"
	&dir= "31"
	&user= "240"
	&host= "166"
	&git_branch= "148"
	&git_ahead= "52"
	&git_behind= "52"
	&git_staged= "22"
	&git_dirty= "161"
	&git_untracked= "52"
	&timestamp= "238"
	&virtualenv= "12"
]

# To how many letters to abbreviate directories in the path - 0 to show in full
prompt_pwd_dir_length = 3

# Format to use for the 'timestamp' segment, in strftime(3) format
timestamp_format = "%H:%M:%S"

# User ID that will trigger the "su" segment. Defaults to root.
root_id = 0

######################################################################

# last_bg is the background color of the last printed segment
last_bg = ""

# git stats
last_git_ahead = 0
last_git_behind = 0
last_git_dirty = 0
last_git_untracked = 0
last_git_deleted = 0

fn -parse_git {
	last_git_ahead last_git_behind = (git:rev_count)
	last_git_dirty last_git_untracked last_git_deleted = (git:change_count)
}

fn -log [@msg]{
	# echo (date) $@msg >> /tmp/chain-debug.log
}

fn -colorprint [what fg bg]{
	edit:styled $what "38;5;"$fg";48;5;"$bg
	last_bg = $bg
}

# Build a prompt segment in the given style, surrounded by square brackets
fn prompt_segment [fg bg @texts]{
	text = $glyph[prefix](joins ' ' $texts)$glyph[suffix]
	-colorprint $text $fg $bg
}

# Return the current directory, shortened according to `$prompt_pwd_dir_length`
fn prompt_pwd {
	tmp = (tilde-abbr $pwd)
	if (> $prompt_pwd_dir_length 0) {
		tmp = (re:replace '(\.?[^/]{'$prompt_pwd_dir_length'})[^/]*/' '$1/' $tmp)
	}

	first = $true
	tmps = [(splits / $tmp)]
	for t $tmps {
		if (not $first) {
			put $glyph[dirchain]
		}
		put $t
		first = $false
	}
}

######################################################################
# Built-in chain segments

fn segment_newline {
	put "\n"
}

fn segment_dir {
	prompt_segment $segment_style_fg[dir] $segment_style_bg[dir] (prompt_pwd)
}

fn segment_user {
	prompt_segment $segment_style_fg[user] $segment_style_bg[user] (whoami)
}

fn segment_host {
	prompt_segment $segment_style_fg[host] $segment_style_bg[host] (hostname)
}

fn segment_git_branch {
	branch = (git:branch_name)
	if (not-eq $branch "") {
		prompt_segment $segment_style_fg[git_branch] $segment_style_bg[git_branch] $glyph[git_branch] $branch$glyph[suffix]
	}
}

fn segment_git_ahead {
	if (> $last_git_ahead 0) {
		prompt_segment $segment_style_fg[git_ahead] $segment_style_bg[git_ahead] $last_git_ahead$glyph[git_ahead]
	}
}

fn segment_git_behind {
	if (> $last_git_behind 0) {
		prompt_segment $segment_style_fg[git_behind] $segment_style_bg[git_behind] $last_git_behind$glyph[git_behind]
	}
}

fn segment_git_staged {
	changecount = (git:staged_count)
	if (> $changecount 0) {
		prompt_segment $segment_style_fg[git_staged] $segment_style_bg[git_staged] $changecount$glyph[git_staged]
	}
}

fn segment_git_dirty {
	if (> $last_git_dirty 0) {
		prompt_segment $segment_style_fg[git_dirty] $segment_style_bg[git_dirty] $last_git_dirty$glyph[git_dirty]
	}
}

fn segment_git_untracked {
	if (> $last_git_untracked 0) {
		prompt_segment $segment_style_fg[git_untracked] $segment_style_bg[git_untracked] $last_git_untracked$glyph[git_untracked]
	}
}

fn segment_arrow {
	uid = (id -u)
	if (eq $uid $root_id) {
		prompt_segment $segment_style_fg[su] $segment_style_bg[su] $glyph[su]
	} else {
		prompt_segment $segment_style_fg[arrow] $segment_style_bg[arrow] $glyph[arrow]
	}
}

fn segment_timestamp {
	prompt_segment $segment_style_fg[timestamp] $segment_style_bg[timestamp] (date +$timestamp_format)
}

fn segment_virtualenv {
	if (not-eq $E:VIRTUAL_ENV "") {
		prompt_segment $segment_style_fg[user] $segment_style_bg[user] $glyph[virtualenv](re:replace '\/.*\/' ''  $E:VIRTUAL_ENV)
	}
}

# List of built-in segments
segment = [
	&newline= $segment_newline~
	&dir= $segment_dir~
	&user= $segment_user~
	&host= $segment_host~
	&git_branch= $segment_git_branch~
	&git_ahead= $segment_git_ahead~
	&git_behind= $segment_git_behind~
	&git_staged= $segment_git_staged~
	&git_dirty= $segment_git_dirty~
	&git_untracked= $segment_git_untracked~
	&arrow= $segment_arrow~
	&timestamp= $segment_timestamp~
	&virtualenv= $segment_virtualenv~
]

# Given a segment specification, return the appropriate value, depending
# on whether it's the name of a built-in segment, a lambda, a string
# or an edit:styled
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
		# If it's an edit:styled, return it as-is
		put $seg
	}
}

# Return a string of values, including the appropriate chain connectors
fn -build-chain [segments]{
	first = $true
	output = ""
	-parse_git

	for seg $segments {
		lbg = $last_bg
		time = (-time { output = [(-interpret-segment $seg)] })
		# -log $pwd segment-$seg $time
		if (> (count $output) 0) {
			if (not $first) {
				if (not (eq $seg "newline")) {
					-colorprint $glyph[chain] $lbg $last_bg
				} else {
					-colorprint $glyph[chain] $lbg "0"
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
	-colorprint $glyph[chain]" " $last_bg "0"
}

# Prompt and rprompt functions

fn prompt {
  put (-build-chain $prompt_segments)
}

fn rprompt {
  put (-build-chain $rprompt_segments)
}

# Default setup, assigning our functions to `edit:prompt` and `edit:rprompt`
fn setup {
	edit:prompt = $prompt~
	edit:rprompt = $rprompt~
}
