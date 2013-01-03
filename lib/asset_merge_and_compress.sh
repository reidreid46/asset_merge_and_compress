#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Set the path to YUI Compressor .jar file
yui_compressor_path="${DIR}/yuicompressor-2.4.8pre.jar"

# Initialize array of messages to display to user
messages=()

error_messages[0]="Error: could't process the file: "

status_messages[0]="Compiled and compressed file: "
status_messages[1]="Imported file: "

warning_messages[0]="Warning: skipping this file because it was not found: "
warning_messages[1]="Warning: skipping this file because it is not .css or .js file: "
warning_messages[2]="Warning: file contained no import statements (we'll just compress it): "
warning_messages[3]="Warning: YUI Compressor not found in the same directory as this script.
  Will merge all the files, but will not compress."

regex_import_statement="(.*)(@import[[:space:]]+url\(\"([a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+)\"\)\;)(.*)"

# Displays a message from the $error_messages array
# Params:
#   1: integer
#   2: file name
# Returns:
#   echo string
function display_error_message() {
  echo "${error_messages[$1]} ${2}"
}

# Displays messages saved from processing
# Returns:
#   echo strings
function display_messages() {
  local msgs=( "$@" )

  for message in "${msgs[@]}"
  do
    echo "${message}"
  done
}

# Displays a message from the $status_messages array
# Params:
#   1: integer
#   2: file name
# Returns:
#   echo string
function display_status_message() {
  echo "${status_messages[$1]} ${2}"
}

# Displays a message from the $warning_messages array
# Params:
#   1: integer
#   2: file name
# Returns:
#   echo string
function display_warning_message() {
  echo "${warning_messages[$1]} ${2}"
}

# Determine if string contains import statements
# Params:
#   1: string (assumed a CSS or JS file)
# Returns:
#   integer (0 if found import statements, 1 otherwise)
function file_has_imports() {
  local result=1

  if [[ (${1} =~ $regex_import_statement) ]] ; then
    local result=0
  fi

  return $result
}

# Determine file directory from a string
# Params:
#   1: string (assumed a file name or a path to file)
# Returns:
#   echo string (file path)
function get_file_directory() {

  # Check to see if it's just a file in the same directory or if it's a path
  if [[ "${1}" =~ \/ ]] ; then
    local result=`echo "${1}" | sed -E "s/(.*)\/.*/\1/g"`
    local result="${pwd}${result}/"
  else
    local result="${PWD}"
  fi

  echo $result
}

# Determine file extention of a string
# Params:
#   1: string (assumed a file name or a path to file)
# Returns:
#   echo string (file extension)
function get_file_extention() {
  local result=`echo "${1}" | sed -E "s/.*\.(.*)/\1/g"`
  echo $result
}

# Determine if a string is a valid path to a file
# Params:
#   1: string (assumed a file name or a path to file)
# Returns:
#   echo string (file extension)
function is_valid_file() {
  # Ensure the file exists
  if [[ -f $1 ]] ; then
    # Ensure the file extention is .css or .js

    local file_extention=`get_file_extention $1`

    if [[ ($file_extention == 'css') ||  ($file_extention == 'js')]] ; then
        local result=0
    else
      local result=2
    fi
  else
    local result=1
  fi

  return $result
}

# Takes a string, looks for imports and imports them recursively. Returns a string.
# Params:
#   1: array (the files array)
# Returns:
#   files
function merge_and_compress_imports() {
  local f=( "$@" )
  for filename in "${f[@]}"
    do

      is_valid_file "${filename}" # call the function
      local file_status=$? # store the return value from the function

      case "${file_status}" in
        0)
          local file_directory=`get_file_directory $filename`
          local merged_file=`merge_imports $filename $file_directory`
          local merged_file_path=`echo "${filename}" | sed -E "s/(.*\/.*)\.(.*)/\1\.min\.\2/"`
          local file_extention=`get_file_extention $filename`
          echo "${merged_file}" | java -jar $yui_compressor_path --type $file_extention -o "${merged_file_path}"
          local message=`display_status_message 0 $filename`
          ;;
        1)
          local message=`display_warning_message 0 ${filename}`
          ;;
        2)
          local message=`display_warning_message 1 ${filename}`
          ;;
        *)
          local message=`display_error_message 0 ${filename}`
          ;;
      esac

      messages[${#messages[*]}]="${message}"
  done
  
}

# Takes a string, looks for imports and imports them recursively. Returns a string.
# Params:
#   1: string (assumed it's the path to a CSS or JS file)
#   2: directory path of file from param 1 (so that relative imports can be found)
# Returns:
#   echo string (CSS or JS file)
function merge_imports() {
  local result=`cat ${1}`
  file_has_imports $result
  local has_imports=$?

  if [[ $has_imports ]] ; then

     # FIXME: should me used as a check interval where the user has the option to stop or continue
    local check_interval=100
    local index=0

    # loop over the imports and call this method on each file
    while [[ ($result =~ $regex_import_statement) && ($index -lt $check_interval )]]
    do
      let index++

      local import_statement=${BASH_REMATCH[2]}
      local import_file=${BASH_REMATCH[3]}
      local import_file_path="${2}${import_file}"
      is_valid_file "${import_file_path}" # call the function
      local file_status=$? # store the return value from the function
      local replacement=""
      local replace=`echo "${import_statement}" | sed -E "s/(\.|\"|\(|\)|\/)/\[\1\]/g"`

      case "${file_status}" in
        0)
          local message=`display_status_message 1 ${import_file_path}`
          local replacement=`merge_imports $import_file_path ${2}`
          ;;
        1)
          local message=`display_warning_message 0 ${import_file_path}`
          ;;
        2)
          local message=`display_warning_message 1 ${import_file_path}`
          ;;
        *)
          local message=`display_error_message 0 ${import_file_path}`
          ;;
      esac

      messages[${#messages[*]}]="${message}"
      local result="${BASH_REMATCH[1]}""${replacement}""${BASH_REMATCH[4]}"
      local result=`echo "${result}" | sed -E "s/$replace/\/\* imported ${import_file} \*\//"`
    done
  fi

  echo "${result}"
}


# The function that runs when script is run.
function main() {
  local f=( "$@" ) # recreate array from parameter, which is an array
  merge_and_compress_imports "${f[@]}"
  display_messages "${messages[@]}"
}

# This is the parameter that is passed into the script when the script is executed. Assumed that a
# function name is passed as the first parameter and the other parameters are parameters for that
# function. E.g.
# ./asset_merge_and_compress.sh main test_1.css test_2.css
# ./asset_merge_and_compress.sh main ../spec/asset_merge_and_compress/css/set_1/level_1.css
$*

