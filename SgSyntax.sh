#!/bin/bash
# WF 2018-07-10
# WF 2025-02-07 adds Atom support
# check smartGENERATOR syntax highlighting support
#
# for Atom
# for Ultraedit
# for VIM
# for Eclipse

# uncomment do debug
# set -x

#ansi colors
#http://www.csc.uvic.ca/~sae/seng265/fall04/tips/s265s047-tips/bash-using-colors.html
blue='\033[0;34m'
red='\033[0;31m'
green='\033[0;32m' # '\e[1;32m' is too bright for white bg.
endColor='\033[0m'

#
# a colored message
#   params:
#     1: l_color - the color of the message
#     2: l_msg - the message to display
#
color_msg() {
  local l_color="$1"
  local l_msg="$2"
  echo -e "${l_color}$l_msg${endColor}"
}

#
# error
#
#   show an error message and exit
#
#   params:
#     1: l_msg - the message to display
error() {
  local l_msg="$1"
  # use ansi red for error
  color_msg $red "Error: $l_msg" 1>&2
  exit 1
}

#
# show the usage
#
usage() {
  echo "usage: $0 [--vim] [--ue] [--eclipse] [--atom] [--all]"
  echo "  --vim     install vim syntax highlighting"
  echo "  --ue      install UltraEdit syntax highlighting"
  echo "  --eclipse install Eclipse syntax highlighting"
  echo "  --atom    install Atom syntax highlighting"
  echo "  --all     install all syntax highlighting"
  exit 1
}

vimtemplate() {
cat << EOF
" Vim syntax file smartgen.vim
" Language:     BITPlan smartGENERATOR templates
" Maintainer:   Wolfgang Fahl - original by Bastian Mathes
" Original: 2000-10-16
" Last change:  2018-07-11
" Filenames:    *.in
" Version Info: 0.2

" For older versions of vim you need to manually add in synload.vim and filetype.vim
" synload.vim:
" SynAu smartgen
" filetype.vim:
" au BufNewFile,BufRead *.in               set ft=smartgen
"
" newer versions:
" au BufNewFile,BufRed  *.in               setft=smartgen

" clear any unwanted syntax defs
if exists("b:current_syntax")
  finish
endif

syn clear

syn case ignore
syn match  metaTag            "#META.*"
syn match  metaTag            "#IMPORT.*"
syn match  metaTag            "#TYPE.*"
syn match  for                "#for"
syn match  for                "#endfor"
syn match  if                 "#if"
syn match  if                 "#else"
syn match  if                 "#endif"
syn match  comment            "^#\..*"
syn match  java               "^\..*"
syn match  marker             "<.*>"

hi link metaTag           Statement
hi link for               Special
hi link if                Special
hi link comment           Comment
hi link java              Identifier
hi link marker            Constant

let b:current_syntax = "smartgen"

EOF
#" vim:ts=8
}

#
# get the locations where vim keeps it's stuff
#
scriptnames() {
local l_script=/tmp/script$$.vim
local l_scriptnames=/tmp/scriptnames$$
cat << EOF > $l_script
set nomore
:scriptnames
q
EOF
vim -S $l_script > $l_scriptnames 2>/dev/null
grep filetype.vim $l_scriptnames
grep synload.vim $l_scriptnames
rm $l_script
rm $l_scriptnames
}


#
# sgfiletype
#
sgfiletype() {
cat << EOF
" smartGENERATOR *.in files
au BufNewFile,BufRead *.in setf smartgen
"
EOF
}

#
# viminstall
#
viminstall() {
  vimfiles=/tmp/vimfiles$$
  scriptnames | cut -c6- | tr -d '\r' > $vimfiles
  filetype=$(grep filetype $vimfiles)
  if [ $? -eq 0 ]
  then
    vimdir=$(dirname $filetype)
    sgvim=$vimdir/syntax/smartgen.vim
    if [ ! -f $sgvim ]
    then
       color_msg $blue "installing $sgvim"
       vimtmp=/tmp/smartgen.vim
       vimtemplate > $vimtmp
       #ls -l $vimtmp
       sudo mv $vimtmp $sgvim
       #ls -l $sgvim
    else
       color_msg $green "$sgvim already installed"
    fi
    grep "setf smartgen" $filetype > /dev/null
    if [ $? -ne 0 ]
    then
      color_msg $blue "adding smartgen filetype .in to vim $filetype ..."
      sgfiletype | sudo tee -a  $filetype > /dev/null
    else
      color_msg $green "smartgen filetype .in already available in $filetype"
    fi
  fi
  #synload=$(grep synload  $vimfiles)
  #if [ $? -eq 0 ]
  #then
  #  echo $synload
  #  grep "SynAu" $synload
  #  if [ $? -ne 0 ]
  #  then
  #    color_msg $blue "adding smartgen Syntax Loading for .in to vim $synload ..."
  #    sudo sh -c echo "SynAu smartgen">> $synload
  #  else
  #    color_msg $green "smartgen filetype .in already available in $synloaad"
  #  fi
  #fi
  rm $vimfiles
}

#
# smartGENERATOR Wordfile
# verbatim version
#
sg_uew() {
cat << EOF
/L21"BITPlan-Macro" NoQuote Block Comment On = #.  Block Comment On Alt = . File Extensions = in cgp sgen  IN CGP SGEN
/Indent Strings = "#for" "#if"
/Unindent Strings = "#endfor" "#endif"
/Function String = "%#META Code.gen*([~;^p]+$"
/Marker Characters = "<>"
/C1"META-Keywords"
#META
/C2"KeyWords"
#IMPORT
for
endfor
** #
/C3"Marker"
<>
EOF
}

#
# ultraedit install
#
ultraedit_install() {
  case $(uname -a) in
    Darwin*)
      uebase="$HOME/Library/Application Support/UltraEdit/wordfiles";
    ;;
    *)
      uebase="$HOME/.idm/uex/wordfiles"
    ;;
  esac
  sguewfile="$uebase/smartgenerator.uew"
  if [ ! -f  "$sguewfile" ]
  then
    color_msg $blue "installing Ultraedit wordfile $sguewfile"
    sg_uew > "$sguewfile"
  else
    color_msg $green "Ultraedit wordfile $sguewfile" already installed
  fi
}

#
#
#
eclipse_install() {
 case $(uname -a) in
    Darwin*)
      eclipse="/Applications/Eclipse.app/Contents/Eclipse"
    ;;
    *)
      eclipse="/usr/lib/eclipse"
    ;;
  esac
  edropins="$eclipse/dropins/eclipse"
  if [ ! -d $edropins/plugins/com.bitplan.eclipse.smartgen_1.0.0 ]
  then
    color_msg $blue "installing Eclipse smartGENERATOR Syntax-Highlighting plugin to $edropins"
    pluginzip=smartGenEditorPlugin.zip
    if [ ! -f /tmp/$pluginzip ]
    then
      cd /tmp
      wget http://wiki.bitplan.com/images/wiki/9/98/SmartGenEditorPlugin.zip
      #scp capri:/bitplan/Source/Product/smartGENERATOR/Eclipse/smartGenEditorPlugin.zip /tmp
    fi
    sudo mkdir -p $edropins
    cd $edropins
    # do a quiet unzip - the plugins folder is part of the zip ...
    sudo unzip -q /tmp/$pluginzip
  else
    color_msg $green "smartGENERATOR Eclipse Syntax-Highlighting plugin already installed at $edropins"
  fi
  # check for the org.eclipse.osgi.compatibilty.plugins
  # see https://stackoverflow.com/a/24519677/1497139
  # https://serverfault.com/questions/225798/can-i-make-find-return-non-0-when-no-matching-files-are-found
  find  $eclipse/plugins -name org.eclipse.osgi.compatibility.plugins* | egrep '.*'
  if [ $? -ne 0 ]
  then
    color_msg $red "you might want to install the Eclipse version 2.0 legacy plugin support from the Eclipse Tests, Examples and extras category from the update repository see https://stackoverflow.com/a/24519677/1497139"
  else
    color_msg $green "legacy plugin support is installed"
  fi
}

#
# atom install
#
atom_install() {
  atomdir="$HOME/.atom/packages/atom-syntax-smartgenerator"
  if [ ! -d "$atomdir" ]
  then
    color_msg $blue "installing Atom smartGENERATOR syntax highlighting to $atomdir"
    cd "$HOME/.atom/packages"
    git clone https://github.com/WolfgangFahl/atom-syntax-smartgenerator
  else
    color_msg $green "Atom smartGENERATOR syntax highlighting already installed at $atomdir"
  fi
}

if [ $# -eq 0 ]; then
  usage
fi

# Parse command line arguments
while [ $# -gt 0 ]; do
  case "$1" in
    --vim)
      viminstall
      ;;
    --ue)
      ultraedit_install
      ;;
    --eclipse)
      eclipse_install
      ;;
    --atom)
      atom_install
      ;;
    --all)
      viminstall
      ultraedit_install
      eclipse_install
      atom_install
      ;;
    *)
      error "unknown option $1"
      ;;
  esac
  shift
done
