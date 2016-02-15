#!/bin/sh

#
# Toolbox of POSIX compliant and general-purpose functions.
#

#
# Get an option argument of a long option.
# Return the number of time argc must be shifted.
#
getopt_longopt_arg() {
  if [ $# -lt 3 ]; then
    log_error "getopt_longopt_arg: missing arguments"
    return 1
  fi

  # try first the `--long-option=value` form
  shift=1
  arg="${3#*=}" # equals $3 if it does not match

  # or the `--long-option value` form
  if [ "$arg" = "$3" ]; then
    arg="$4"
    shift=2
  fi

  eval "$1=$arg"
  eval "$2=$shift"
}

#
# Timestamp in Unix time.
#
timestamp() {
  date "+%s"
}

#
# Find first set (i.e. non-empty) argument.
#
ffs () {
  while [ $# -ne 0 ]; do
    if [ -z "$1" ]; then
       shift
    else
      break
    fi
  done

  echo "$1"
}

#
# Test current process is interactive.
# Return 0 if current process is interface, non-zero otherwise.
#
process_is_interactive() {
  [ -t 1 ]
}

#
# Log an error message to standard error
#
log_error() {
  echo "error:$@" >&2
}

#
# Log a message
#
log_info() {
  echo "$@"
}
