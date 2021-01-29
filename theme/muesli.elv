# Muesli's prompt theme, based on the fish theme at https://github.com/oh-my-fish/theme-chain
# Ported to Elvish by Diego Zamboni <diego@zzamboni.org>
# Personal style changes by Christian Muehlhaeuser <muesli@gmail.com>
#
# To use, put this file in ~/.elvish/lib/theme and add the following to your ~/.elvish/rc.elv file:
#   use theme:muesli
#   theme:muesli:setup
#
# You can also assign the prompt functions manually instead of calling `theme:muesli:setup`:
#   edit:prompt = $theme:muesli:&prompt
#   edit:rprompt = $theme:muesli:&rprompt
#
# The chains on both sides can be configured by assigning to `theme:muesli:prompt_segments` and
# `theme:muesli:rprompt_segments`, respectively. These variables must be arrays, and the given
# segments will be automatically linked by `$theme:muesli:glyph[chain]`. Each element can be any
# of the following:
#
# - The name of one of the built-in segments. Available segments: `prefix` `userhost` `arrow` `timestamp` `su` `dir` `git_branch` `git_dirty`
# - A string or the output of `edit:styled`, which will be displayed as-is.
# - A lambda, which will be called and its output displayed
# - The output of a call to `theme:muesli:segment <style> <strings>`, which returns a "proper" segment, enclosed in
#   square brackets and styled as requested.
#

use git
use str

# Default values (all can be configured by assigning to the appropriate variable):

# Configurable prompt segments for each prompt
prompt_segments = [ prefix su dir git_branch git_dirty userhost arrow ]
rprompt_segments = [ timestamp ]

# Glyphs to be used in the prompt
glyph = [
	&prefix= "╭─"
	&prompt= "\n╰◉"
	&git_branch= "⎇"
	&git_dirty= "±"
	&su= "⚡"
  &cache= "∼"
	&chain= " "
]

# Styling for each built-in segment. The value must be a valid argument to `edit:styled`
segment_style = [
	&chain= default
	&su= red
	&cache= yellow
	&dir= lightyellow
	&git_branch= white
	&git_dirty= yellow
	&timestamp= gray
]

# To how many letters to abbreviate directories in the path - 0 to show in full
prompt_pwd_dir_length = 3

# Format to use for the 'timestamp' segment, in strftime(3) format
timestamp_format = "%H:%M:%S"

# User ID that will trigger the "su" segment. Defaults to root.
root_id = 0

# If $true, the chain is only generated after each command and not on every keystroke
# This improves typing speed sometimes (e.g. in large git repos when you have the
# git segments enabled) but may cause prompt refresh problems sometimes until
# you press Enter after a directory change or some other change.
cache_chain = $false

# Threshold in milliseconds for auto-enabling prompt caching
auto_cache_threshold_ms = 100

# Cached generated prompt - since arbitrary commands can be executed, we compute
# the prompt only before displaying it and not on every keystroke, and we cache
# the prompts here.
cached_prompt = [ ]
cached_rprompt = [ ]

######################################################################

# Convert output from -time function to a number in ms
fn -time-to-ms [n]{
  pat = (re:find '^([\d.]+)(.*)$' $n)
  num unit = $pat[groups][1 2][text]
  factor = [&s=1000 &ms=1 &µs=.001]
  * $num $factor[$unit]
}

fn -log [@msg]{
  echo (date) $@msg >> /tmp/chain-debug.log
}

# Internal function to return a styled string, or plain if color == "default"
fn -colored [what color]{
	if (!=s $color default) {
		edit:styled $what $color
	} else {
		put $what
	}
}

# Build a prompt segment in the given style, surrounded by square brackets
fn prompt_segment [style @texts]{
	text = "["(str:join ' ' $texts)"]"
	-colored $text $style
}

# Return the current directory, shortened according to `$prompt_pwd_dir_length`
fn -prompt_pwd {
	tmp = (tilde-abbr $pwd)
	if (== $prompt_pwd_dir_length 0) {
		put $tmp
	} else {
		re:replace '(\.?[^/]{'$prompt_pwd_dir_length'})[^/]*/' '$1/' $tmp
	}
}

######################################################################
# Built-in chain segments

fn segment_su {
	uid = (id -u)
	if (eq $uid $root_id) {
		prompt_segment $segment_style[su] $glyph[su]
	}
}

fn segment_cache {
  if $cache_chain {
    prompt_segment $segment_style[cache] $glyph[cache]
  }
}

fn segment_dir {
	prompt_segment $segment_style[dir] (-prompt_pwd)
}

fn segment_userhost {
  edit:styled (put "(") gray;
  edit:styled (put (whoami)) "lightgreen";
  edit:styled (put "@") gray;
  edit:styled (put (hostname)) "lightblue";
  edit:styled (put ")") gray;
}

fn segment_git_branch {
  branch = (git:branch_name)
  if (not-eq $branch "") {
	  prompt_segment $segment_style[git_branch] $glyph[git_branch] $branch
  }
}

fn segment_git_dirty {
	if (git:is_dirty) {
	  prompt_segment $segment_style[git_dirty] $glyph[git_dirty]
	}
}

fn segment_prefix {
	edit:styled $glyph[prefix] white
}

fn segment_arrow {
	edit:styled $glyph[prompt]" " white
}

fn segment_timestamp {
	prompt_segment $segment_style[timestamp] (date +$timestamp_format)
}

# List of built-in segments
segment = [
	&su= $&segment_su
	&cache= $&segment_cache
	&dir= $&segment_dir
	&userhost= $&segment_userhost
	&git_branch= $&segment_git_branch
	&git_dirty= $&segment_git_dirty
	&prefix= $&segment_prefix
	&arrow= $&segment_arrow
	&timestamp= $&segment_timestamp
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
	for seg $segments {
		time = (-time { output = [(-interpret-segment $seg)] })
    #    -log $pwd segment-$seg $time
	  if (> (count $output) 0) {
		  if (not $first) {
			  -colored $glyph[chain] $segment_style[chain]
		  }
		  put $@output
		  first = $false
	  }
	}
}

# Check if the time exceeds the threshold for enabling/disabling
# caching We have separate functions for enabling/disabling because
# they are called from different points - the "enabling" functions are
# called after each chain generation (so that either prompt or rprompt
# taking too long can trigger the caching), while the "disabling"
# functions are called only from the "cache_prompts" function, so that
# caching is disabled only when both prompts are fast.
fn -check_time_for_enabling_caching [t]{
  ms = (-time-to-ms $t)
  if (>= $ms $auto_cache_threshold_ms) {
    if (not $cache_chain) {
      -log Chain build took $ms - enabling prompt caching
      theme:chain:cache $true
      edit:redraw
    }
  }
}

fn -check_time_for_disabling_caching [t]{
  ms = (-time-to-ms $t)
  if (< $ms $auto_cache_threshold_ms) {
    if $cache_chain {
      -log Chain build took $ms - disabling prompt caching
      theme:chain:cache $false
      edit:redraw
    }
  }
}

# Prompt and rprompt functions

fn prompt [@skipcheck]{
  out = []
  time = (-time { out = [(-build-chain $prompt_segments)] })
  if (== (count $skipcheck) 0) {
    -check_time_for_enabling_caching $time
  }
  put $@out
}

fn rprompt [@skipcheck]{
  out = []
  time = (-time { out = [(-build-chain $rprompt_segments)] } )
  if (== (count $skipcheck) 0) {
    -check_time_for_enabling_caching $time
  }
  put $@out
}

fn cache_prompts [@skipcheck]{
  time = (-time {
      cached_prompt = [(prompt $@skipcheck)]
      cached_rprompt = [(rprompt $@skipcheck)]
  })
  if (== (count $skipcheck) 0) {
    -check_time_for_disabling_caching $time
  }
  #  -log $pwd cache_prompts $time
}

# Default setup, assigning our functions to `edit:prompt` and `edit:rprompt`
fn setup {
  if $cache_chain {
    edit:before-readline=[ $@edit:before-readline $&cache_prompts ]
    edit:prompt = { put $@cached_prompt }
    edit:rprompt = { put $@cached_rprompt }
    cache_prompts skip_timecheck
  } else {
    edit:prompt = $&prompt
    edit:rprompt = $&rprompt
  }
}

# Toggle (or set, according to parameter) prompt caching
fn cache [@val]{
  value = (not $cache_chain)
  if (> (count $val) 0) {
    value = $val[0]
  }
  cache_chain = $value
  setup
}
