#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
script_path="${DIR}/../../lib/asset_merge_and_compress.sh"

function display_error_message() {
  local result=1

  local t=`eval $script_path display_error_message 0 'example.css'`

  if [[ $t =~ Error:.*example\.css ]] ; then
    local result=0
  fi

  return $result
}

function display_messages() {
  local result=1

  local msg='test_message'
  local t=`eval $script_path display_messages $msg`

  if [[ $t == $msg ]] ; then
    local result=0
  fi

  return $result
}

function display_status_message() {
  local result=1

  local t=`eval $script_path display_status_message 0 'example.css'`

  if [[ $t =~ Compiled.*example\.css ]] ; then
    local result=0
  fi

  return $result
}

function display_warning_message() {
  local result=1

  local t=`eval $script_path display_warning_message 0 'example.css'`

  if [[ $t =~ Warning.*example\.css ]] ; then
    local result=0
  fi

  return $result
}

function includes_file_has_imports() {
  local result=1

  local css="@import url(\"test.css\");"
  $script_path file_has_imports <<< echo "${css}"
  local t=$?

  if [[ $t == 0 ]] ; then
    local result=0
  fi

  return $result
}

function excludes_file_has_imports() {
  local result=1

  local t=`eval $script_path file_has_imports <<< "hello world"`

  if [[ $t != 0 ]] ; then
    local result=0
  fi

  return $result
}

function get_file_directory_without_path() {
  local result=1

  local t=`eval $script_path get_file_directory "example.css"`
  local d="/${PWD#*/}"


  if [[ $t ==  "${d}" ]] ; then
    local result=0
  fi

  return $result
}

function get_file_directory_with_relative_path() {
  local result=1
  local t=`eval $script_path get_file_directory "../example.css"`
  local d="/${PWD#*/}/"

  if [[ $t ==  "../" ]] ; then
    local result=0
  fi

  return $result
}

function get_file_directory_with_absolute_path() {
  local result=1

  local t=`eval $script_path get_file_directory "/tmp/example.css"`

  if [[ $t ==  "/tmp/" ]] ; then
    local result=0
  fi

  return $result
}

function get_file_extention_css() {
  local result=1

  local t=`eval $script_path get_file_extention '../sample/path/example.css'`

  if [[ $t == 'css' ]] ; then
    local result=0
  fi

  return $result
}

function get_file_extention_js() {
  local result=1

  local t=`eval $script_path get_file_extention '../sample/path/example.js'`

  if [[ $t == 'js' ]] ; then
    local result=0
  fi

  return $result
}

function is_valid_file() {
  local result=1

  echo '@import url("example.css");' > 'is_valid_file.css'
  $script_path is_valid_file 'is_valid_file.css'
  local t=$?

  if [[ $t == 0 ]] ; then
    local result=0
  fi

  rm 'is_valid_file.css'
  return $result
}

function is_invalid_file() {
  local result=1

  $script_path is_valid_file 'invalid_file.css'
  local t=$?

  if [[ $t != 0 ]] ; then
    local result=0
  fi

  return $result
}

function main() {
  local result=1

  echo 'p { margin: 0; }' > "${DIR}/nested.css"
  echo '@import url("nested.css"); a { padding: 0; }' > "${DIR}/main.css"
  local foo=`$script_path main "${DIR}/main.css"`

  if [[ -f "${DIR}/main.min.css" ]] ; then
    if [[ $(cat "${DIR}/main.min.css") == 'p{margin:0}a{padding:0}' ]] ; then
      local result=0
    fi

    rm "${DIR}/main.min.css"
   fi

  rm "${DIR}/main.css"
  rm "${DIR}/nested.css"
  return $result
}

function run_tests() {
  tsts=()
  tsts[${#tsts[*]}]='display_error_message'
  tsts[${#tsts[*]}]='display_messages'
  tsts[${#tsts[*]}]='display_status_message'
  tsts[${#tsts[*]}]='display_warning_message'
  tsts[${#tsts[*]}]='includes_file_has_imports'
  tsts[${#tsts[*]}]='excludes_file_has_imports'
  tsts[${#tsts[*]}]='get_file_directory_without_path'
  tsts[${#tsts[*]}]='get_file_directory_with_relative_path'
  tsts[${#tsts[*]}]='get_file_directory_with_absolute_path'
  tsts[${#tsts[*]}]='get_file_extention_css'
  tsts[${#tsts[*]}]='get_file_extention_js'
  tsts[${#tsts[*]}]='is_valid_file'
  tsts[${#tsts[*]}]='is_invalid_file'
  tsts[${#tsts[*]}]='main'

  for tst in "${tsts[@]}"
    do
      echo ''
      eval $tst
      local result=$?
      if [[ $result == 0 ]] ; then
        echo "`tput setaf 2; tput smso`+Passed:`tput rmso; tput setaf 0` ${tst}"
      else
        echo "`tput setaf 1; tput smso`-Failed:`tput rmso; tput setaf 0` ${tst}"
      fi
 done
 echo ''
}

# This is the parameter that is passed into the script when the script is executed. Assumed that a
# function name is passed as the first parameter and the other parameters are parameters for that
# function. E.g.
# ./asset_merge_and_compress_spec.sh run_tests
$*
