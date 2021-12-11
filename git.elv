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

# You can configure the commands to use here - only change if you know
# what you are doing.

# The status command must produce output in Porcelain v2 format. See
# https://git-scm.com/docs/git-status for details
var git-status-cmd = { git --no-optional-locks status --porcelain=v2 --branch --ignore-submodules=all 2>&- }

# Get remotes
var git-remote-cmd = { git remote 2>&- }

# Switch statement to make the code in `status` simpler
fn -switch {|a b|
  if (has-key $b $a) {
    $b[$a]
  }
}

# Runs $git-status-cmd, parses it and returns a data structure with
# information. If &counts=$true, it precomputes the element count for
# all key elements, and adds them in the result with the same names
# but with "-count" at the end.
fn status {|&counts=$false|
  var staged-modified = []
  var staged-deleted  = []
  var staged-added    = []
  var local-modified  = []
  var local-deleted   = []
  var untracked       = []
  var unmerged        = []
  var ignored         = []
  var renamed         = []
  var copied          = []
  var branch-name     = ""
  var branch-oid      = ""
  var rev-ahead       = 0
  var rev-behind      = 0
  var is-git-repo     = $false

  var is-ok = ?($git-status-cmd | eawk {|line @f|
      # pprint "@f=" $f
      -switch $f[0] [
        &"#"= {
          -switch $f[1] [
            &"branch.head"= { set branch-name = $f[2] }
            &"branch.oid"= { set branch-oid = $f[2] }
            &"branch.ab"= {
              set rev-ahead = (re:find '\+(\d+)' $f[2])[groups][1][text]
              set rev-behind = (re:find '-(\d+)' $f[3])[groups][1][text]
            }
          ]
        }
        &"1"= {
          -switch $f[1] [
            &"M."= { set staged-modified = [ $@staged-modified $f[8] ] }
            &".M"= { set local-modified =  [ $@local-modified  $f[8] ] }
            &"MM"= { set staged-modified = [ $@staged-modified $f[8] ]; set local-modified = [ $@local-modified $f[8] ] }
            &"D."= { set staged-deleted =  [ $@staged-deleted  $f[8] ] }
            &".D"= { set local-deleted =   [ $@local-deleted   $f[8] ] }
            &"DD"= { set staged-deleted =  [ $@staged-deleted  $f[8] ]; set local-deleted = [ $@local-deleted $f[8] ] }
            &"A."= { set staged-added =    [ $@staged-added    $f[8] ] }
          ]
        }
        &"2"= {
          if (re:match '(\.C|C\.)' $f[1]) {
            set copied = [ $@copied $f[9] ]
          } elif (re:match '(\.R|R\.)' $f[1]) {
            set renamed = [ $@renamed $f[9] ]
          }
        }
        &"?"= { set untracked = [ $@untracked $f[1] ] }
        &"!"= { set ignored = [ $@ignored $f[1] ] }
        &"u"= { set unmerged = [ $@unmerged $f[10] ] }
      ]
    }
  )

  var result = [
    &staged-modified= $staged-modified
    &staged-deleted=  $staged-deleted
    &staged-added=    $staged-added
    &local-modified=  $local-modified
    &local-deleted=   $local-deleted
    &untracked=       $untracked
    &unmerged=        $unmerged
    &ignored=         $ignored
    &renamed=         $renamed
    &copied=          $copied
    &branch-name=     $branch-name
    &branch-oid=      $branch-oid
    &rev-ahead=       $rev-ahead
    &rev-behind=      $rev-behind
    &is-git-repo=     (bool $is-ok)
  ]
  if $counts {
    keys $result | each {|k|
      if (eq (kind-of $result[$k]) list) {
        set result[$k'-count'] = (count $result[$k])
      }
    }
  }
  put $result
}

# Return the git branch name of the current directory
fn branch_name {
  put (status)[branch-name]
}

# Return how many commits this repo is ahead & behind of master
fn rev_count {
  var data = (status)
  put $data[rev-ahead] $data[rev-behind]
}

# Return how many files in the current git repo are "dirty" (modified in any way) or untracked
fn change_count {
  var data = (status)
  put (count $data[local-modified]) (count $data[untracked]) (count $data[local-deleted])
}

# Return how many files in the current git repo are staged
fn staged_count {
  var data = (status)
  + (count $data[staged-modified]) (count $data[staged-deleted]) (count $data[staged-added]) (count $data[renamed]) (count $data[copied])
}

# Automatically "git rm" files which have been deleted from the file
# system. Can be used to clean up when you remove files by hand before
# telling git about it. Use with care.
fn auto-rm {
  all (status)[local-deleted] | each {|f|
    echo (edit:styled "Removing "$f red)
    git rm $f
  }
}

fn remotes {
  set _ = ?($git-remote-cmd)
}

fn remotes-transform {|transform-fn @remotes|
  if (eq $remotes []) {
    set remotes = [(remotes)]
  }
  each {|r|
    var url = (git remote get-url $r)
    var new-url = ($transform-fn $url)
    if (not-eq $url $new-url) {
      git remote set-url $r $new-url
      echo (edit:styled "Moved remote "$r" from "$url" to "$new-url green)
    }
  } $remotes
}

fn remotes-ssh-to-https {|@remotes|
  remotes-transform {|url| re:replace 'git(?:@|://)(.*)[:/](.*)/(.*)' 'https://$1/$2/$3' $url } $@remotes
}

fn remotes-https-to-ssh {|@remotes|
  remotes-transform {|url| re:replace 'https://(.*)/(.*)/(.*)' 'git@$1:$2/$3' $url } $@remotes
}
