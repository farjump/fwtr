#!/bin/sh

# immediately exit on error
set -e

# current working directory
cwd=${0%/*}

source $cwd/lib/sh/utils.sh

#
# Transform the text to a path following fwtr naming rule:
#   - fully lower case
#   - ' ' becomes '-'
#   - '/' becomes '_'
# The argument should be already text-sanitized.
#
fwtr_sanitize_path_() {
  gawk '{                     \
          l = tolower($0);    \
          gsub(/ /, "-", l);  \
          gsub(/\//, "_", l); \
          print l;            \
        }' <<EOF
$@
EOF
}

#
# Print the help message
#
fwtr_help() {
  cat <<EOF
Usage: $0 [--help] <command> <args>

COMMANDS
  add [<options>] <logs>...
    Add new test results in the repository. Retrieve data from the logs and
    store them accordingly.

    Options:
      --dry-run
        Do not execute the commands adding the results in the repository.
        Useful to see what would happen and what can be retrieved from the logs.

      --test-id=ID
        Force the test ID. Default is the test date in the logs.

      --system-vendor=NAME
        Force the system vendor name. Default is retrieved from the
        BIOS Information Table in the logs.

      --bios-vendor=NAME
        Force the BIOS vendor name.

      --product-name=NAME
        Force the product name.

      --board-name=NAME
        Force the board name.

      --bios-version=NAME
        Force the BIOS version.

EXAMPLES
  $0 add my-results-1/results.html my-results-2/results.log my-results-3/luv.html
    Add \`my-results-1/\`, \`my-results-2/\` and \`my-results-3/\` in the repository.

  $0 add --system-vendor=intel --product-name=nuc my-results/results.log
    Add \`my-results/\` in the repository and force the names of the system
    vendor and product. Useful when the BIOS Information Table is incomplete or
    wrong.
EOF
}

#
# Helper function to call gawk including the `utils.awk` file.
#
fwtr_gawk_() {
  gawk -i $cwd/lib/awk/utils.awk $@
}

#
# Probe the testing tool that has been used and its version.
# Global variables are set accordingly but empty if unknown:
#   - FWTR_TOOL
#   - FWTR_TOOL_VERSION
#
fwtr_probe_() {
  # probe.awk outputs shell variables
  eval "`fwtr_gawk_ -f $cwd/lib/awk/probe.awk $1`"
  FWTR_TEST_ID=$FWTR_DATE
}

#
# Print "[forced]" if the first argument is not empty.
#
fwtr_print_forced_() {
  [ -n "$1" ] && echo -n '[forced]'
}

#
# Retrieve BIOS informations from the test result.
# Global variables are set accordingly but empty if unknown:
#    - FWTR_BIOS_INFO_BIOS_VENDOR
#    - FWTR_BIOS_INFO_BIOS_VERSION
#    - FWTR_BIOS_INFO_BIOS_RELEASE_DATE
#    - FWTR_BIOS_INFO_BOARD_NAME
#    - FWTR_BIOS_INFO_BOARD_VERSION
#    - FWTR_BIOS_INFO_PRODUCT_NAME
#    - FWTR_BIOS_INFO_PRODUCT_VERSION
#    - FWTR_BIOS_INFO_SYSTEM_VENDOR
#
fwtr_bios_info_() {
  bios_info_script="$cwd/lib/awk/$FWTR_TOOL/bios_info.awk"
  if ! [ -f $bios_info_script ]; then
    log_error "bios info: missing parser script \`$bios_info_script\`"
    return 1
  fi
  # bios_info.awk outputs shell variables
  eval "`fwtr_gawk_ -f $bios_info_script $1`"
}

#
# Print the BIOS variables
#
fwtr_print_bios_info_() {
  cat <<EOF
${1}BIOS Vendor:       $FWTR_BIOS_INFO_BIOS_VENDOR `fwtr_print_forced_ $force_bios_vendor`
${1}BIOS Version:      $FWTR_BIOS_INFO_BIOS_VERSION `fwtr_print_forced_ $force_bios_version`
${1}BIOS Release Date: $FWTR_BIOS_INFO_BIOS_RELEASE_DATE
${1}Board Name:        $FWTR_BIOS_INFO_BOARD_NAME `fwtr_print_forced_ $force_board_name`
${1}Board Version:     $FWTR_BIOS_INFO_BOARD_VERSION
${1}Product Name:      $FWTR_BIOS_INFO_PRODUCT_NAME `fwtr_print_forced_ $force_product_name`
${1}Product Version:   $FWTR_BIOS_INFO_PRODUCT_VERSION
${1}System Vendor:     $FWTR_BIOS_INFO_SYSTEM_VENDOR `fwtr_print_forced_ $force_system_vendor`
EOF
}

#
# Print the target directory according to every collected informations.
#
fwtr_target_directory_ () {
  system=`fwtr_sanitize_path_ "$FWTR_BIOS_INFO_SYSTEM_VENDOR"`
  product=`fwtr_sanitize_path_ "$FWTR_BIOS_INFO_PRODUCT_NAME"`
  board=`fwtr_sanitize_path_ "$FWTR_BIOS_INFO_BOARD_NAME"`
  bios=`fwtr_sanitize_path_ "$FWTR_BIOS_INFO_BIOS_VENDOR"`
  bios_version=`fwtr_sanitize_path_ "$FWTR_BIOS_INFO_BIOS_VERSION"`
  tool=`fwtr_sanitize_path_ "$FWTR_TOOL"`
  test_id=${FWTR_TEST_ID:-unknown-test-id}

  # The main entry point is one of the two vendors name in the BIOS
  # Privilege the system vendor.
  vendor=`ffs "$system" "$bios"`

  vendor=${vendor:-unknown-vendor}
  product=${product:-unknown-product}
  board=${board:-unknown-board}
  bios=${bios:-unknown-bios}
  bios_version=${bios_version:-unknown-bios-version}
  tool=${tool:-unknown-tool}

  prefix="$cwd/../$vendor/$product"

  # The board and the product name may be the same.
  [ "$product" != "$board" ] && prefix="$prefix/$board"

  echo "$prefix/$bios/$bios_version/$tool/$test_id"
}

#
# Actual `fwtr add` shell program to run once the target directory ($2) is correctly computed.
# Return text so that it can be dynamically evaluated and printed to be reviewed by the user.
#
fwtr_add_text_() {
  cat <<EOF
# create destination directory
mkdir -p $2
# copy the source directory
cp -rv $1/* $2
# create a README.md template if not already done
[ -f $2/README.md ] ||
  cat > $2/README.md <<EOR
# Overview

TODO


# Important Firmware Settings

TODO
EOR
EOF
}

#
# Add new results in the repository
#
fwtr_add() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --dry-run*)
        dry_run=y
        shift
        ;;

      --system-vendor*)
        getopt_longopt_arg arg shift "$1" "$2"
        force_system_vendor="$arg"
        shift $shift
        ;;
      --bios-vendor*)
        getopt_longopt_arg arg shift "$1" "$2"
        force_bios_vendor="$arg"
        shift $shift
        ;;
      --test-id*)
        getopt_longopt_arg arg shift "$1" "$2"
        force_test_id="$arg"
        shift $shift
        ;;
      --product-name*)
        getopt_longopt_arg arg shift "$1" "$2"
        force_product_name="$arg"
        shift $shift
        ;;
      --board-name*)
        getopt_longopt_arg arg shift "$1" "$2"
        force_board_name="$arg"
        shift $shift
        ;;
      --bios-version*)
        getopt_longopt_arg arg shift "$1" "$2"
        force_bios_version="$arg"
        shift $shift
        ;;

      -*)
        log_error  "fwtr add: illegal option −− $1"
        return 1
        ;;

      --)
        shift
        ;;

      *)
        files="$files $1"
        shift
        ;;
    esac
  done

  for f in $files; do
    log_info 'fwtr add: probing the result format...'
    fwtr_probe_ $f
    log_info "fwtr add: \`$FWTR_TOOL\` version \`$FWTR_TOOL_VERSION\` detected."

    log_info 'fwtr add: retrieving BIOS informations...'
    fwtr_bios_info_ $f
    log_info

    # forced values
    [ -n "$force_system_vendor" ] &&
      FWTR_BIOS_INFO_SYSTEM_VENDOR=$force_system_vendor
    [ -n "$force_product_name" ] &&
      FWTR_BIOS_INFO_PRODUCT_NAME=$force_product_name
    [ -n "$force_board_name" ] &&
      FWTR_BIOS_INFO_BOARD_NAME=$force_board_name
    [ -n "$force_bios_vendor" ] &&
      FWTR_BIOS_INFO_BIOS_VENDOR=$force_bios_vendor
    [ -n "$force_bios_version" ] &&
      FWTR_BIOS_INFO_BIOS_VERSION=$force_bios_version
    [ -n "$force_test_id" ] &&
      FWTR_TEST_ID=$force_test_id

    log_info 'fwtr add: Collected data:'
    fwtr_print_bios_info_ 'fwtr add: '
    log_info
    log_info "fwtr add: Test ID:                       $FWTR_TEST_ID `fwtr_print_forced_ $force_test_id`"
    src="${f%/*}"
    log_info "fwtr add: Source Test Results Path:      $src"
    dst="`fwtr_target_directory_`"
    log_info "fwtr add: Destination Test Results Path: $dst"
    log_info
    log_info 'fwtr add: please review previous logs before continuing.'
    log_info 'fwtr add: options are available in order to correct wrong informations by forcing values.'
    log_info 'fwtr add: continue? (C-c or C-d to exit)'
    read # set -e assumed

    log_info 'fwtr add: this shell program is about to be launched:'
    prog="`fwtr_add_text_ $src $dst`"
    echo "$prog"
    log_info
    log_info 'fwtr add: continue? (C-c or C-d to exit)'
    read # set -e assumed

    [ -z "$dry_run" ] && eval "$prog"

    log_info
    log_info 'fwtr add: you are now ready to commit.'
  done
}

#
# script entry function
#
fwtr() {
  cmd=fwtr_help
  while [ $# -gt 0 ]; do
    case $1 in
      --help)
        fwtr_help
        return 1 # note: doing this makes only one --help message possible
        ;;

      add)
        cmd=fwtr_add
        shift
        ;;

      *)
        args="$args $1"
        shift
        ;;
    esac
  done

  $cmd $args
}

# call the entry function `fwtr` if in interactive mode.
process_is_interactive &&
  fwtr $@
