#
# Warning: this script used GNU Awk features.
#

#@include "../utils.awk"

BEGIN {
  # boolean value
  parsing_fwts_bios_info=0;
}

parse_fwts_bios_info();

END {
  print_shell_variables();
}

#
# Print shell variables that may be required for scripting.
# So far:
#   - part of the BIOS Information table to build the directory where results should be stored.
#
function print_shell_variables() {
  print "# automatically parsed from ", FILENAME, ". Please check.";
  print_shell_variables_bios_info();
}

#
# Print BIOS information as POSIX shell variables.
# For each bios information entry, print a variable assignment of the value quoted.
# Example:
# VENDOR_BIOS='intel'
#
function print_shell_variables_bios_info() {
  print to_shell_variable("FWTR_BIOS_INFO_BIOS_VENDOR",       sanitize_vendor(bios_vendor));
  print to_shell_variable("FWTR_BIOS_INFO_BIOS_VERSION",      sanitize_text(bios_version));
  print to_shell_variable("FWTR_BIOS_INFO_BIOS_RELEASE_DATE", sanitize_text(bios_release_date));
  print to_shell_variable("FWTR_BIOS_INFO_BOARD_NAME",        sanitize_text(board_name));
  print to_shell_variable("FWTR_BIOS_INFO_BOARD_VERSION",     sanitize_text(board_version));
  print to_shell_variable("FWTR_BIOS_INFO_PRODUCT_NAME",      sanitize_text(product_name));
  print to_shell_variable("FWTR_BIOS_INFO_PRODUCT_VERSION",   sanitize_text(product_version));
  print to_shell_variable("FWTR_BIOS_INFO_SYSTEM_VENDOR",     sanitize_vendor(system_vendor));
}

#
# Parse the BIOS Information Table from FWTS test results.
# Assumed beginning with `bios_info:` and ending with `System Vendor:` rows.
#
# Example:
# > bios_info: Gather BIOS DMI information.
# > --------------------------------------------------------------------------------
# > Test 1 of 1: Gather BIOS DMI information
# > BIOS Vendor       : Intel Corp.
# > BIOS Version      : TYBYT10H.86A.0046.2015.1014.1057
# > BIOS Release Date : 10/14/2015
# > Board Name        : DE3815TYKH
# > Board Serial #    :
# > Board Version     : H26998-401
# > Board Asset Tag   :
# > Chassis Serial #  :
# > Chassis Type      : 3
# > Chassis Vendor    :
# > Chassis Version   :
# > Chassic Asset Tag :
# > Product Name      :
# > Product Serial #  :
# > Product UUID      :
# > Product Version   :
# > System Vendor     :
#
function parse_fwts_bios_info() {
  if ($0 ~ /bios_info:/) {
    parsing_fwts_bios_info=1; # true, we are parsing the BIOS Infos
    FS=":"; # `:` as field-separator. Cf. the bios info table example
  }

  if (parsing_fwts_bios_info) {
    parse_fwts_bios_info_entry("BIOS Vendor",       "bios_vendor");
    parse_fwts_bios_info_entry("BIOS Version",      "bios_version");
    parse_fwts_bios_info_entry("BIOS Release Date", "bios_release_date");
    parse_fwts_bios_info_entry("Board Name",        "board_name");
    # ignored: Board Serial #
    parse_fwts_bios_info_entry("Board Version",     "board_version");
    # ignored: Board Asset Tag
    # ignored: Chassis Serial #
    # ignored: Chassis Type
    # ignored: Chassis Vendor
    # ignored: Chassis Version
    # ignored: Chassis Asset Tag
    parse_fwts_bios_info_entry("Product Name",      "product_name");
    # ignored: Product Serial #
    # ignored: Product UUID
    parse_fwts_bios_info_entry("Product Version",   "product_version");
    # last line of the bios info table reached
    parse_fwts_bios_info_entry("System Vendor",     "system_vendor") && parsing_fwts_bios_info=0;

  }
}

#
# Return the vendor ID string: a lower-case unique and single company name.
# Instead of trying to remove `Inc.`, `Corp.`, etc. directly match company substrings.
#
function to_vendor_id(vendor)
{
  vendor = tolower(vendor);

  switch (vendor) {
    # Apple Inc.
    case /apple/:
      return "apple";

    # Phoenix Technologies Ltd.
    case /phoenix/:
      return "phoenix"

    # Intel Corp.
    case /intel/:
      return "intel";

    case /american megatrends/:
      return "ami";

    case /award/:
      return "award";

    case /gigabyte/:
      return "gigabyte";

    case /dell/:
      return "dell";

    case /samsung/:
      return "samsung";

    # ASUSTeK Computer Inc.
    case /asus/:
      return "asus";

    # failsafe attempt:
    # vendor names with a single word sould be usable as they are.
    # matches things like: ibm, asus, intel, lenovo, dell...
    # Names compound with `Inc.`
    case /^[[:alnum:]]{2,}$/:
      return vendor;

    default:
      print "ERROR: unknown vendor name `" vendor "`" > "/dev/stderr";
      print "       please add your new vendor name in `to_vendor_id()` function"  > "/dev/stderr";
      return "error";
  }
}

#
# Sanitize a vendor text string.
#
function sanitize_vendor(vendor) {
  if (vendor ~ /^$/)
    return "";

  vendor=sanitize_text(vendor);
  vendor=to_vendor_id(vendor)
  gsub(/[^/\-_ \\[:alnum:]]/, "", vendor);
  return vendor;
}

#
# Retrieve an entry value from the BIOS DMI table into `variable` when it matches `pattern`.
#
function parse_fwts_bios_info_entry(pattern, variable) {
  if ($0 ~ pattern) {
    sub(/<.*>/, "", $2);
    set(variable, trim($2));
    return 1;
  }
  return 0;
}

#
# Setter functions required by `set()`.
#
function set_bios_vendor(value)       { bios_vendor=value; }
function set_bios_version(value)      { bios_version=value; }
function set_bios_release_date(value) { bios_release_date=value; }
function set_board_name(value)        { board_name=value; }
function set_board_version(value)     { board_version=value; }
function set_product_name(value)      { product_name=value; }
function set_product_version(value)   { product_version=value; }
function set_system_vendor(value)     { system_vendor=value; }
