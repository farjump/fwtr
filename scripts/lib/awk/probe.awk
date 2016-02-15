#
# Warning: this script used GNU Awk features.
#

#@include "./utils.awk"

BEGIN {
  # case sensitivity disabled
  IGNORECASE = 1;

  # tool weights to be compared at the end to determine which tool has been used
  fwts = 0;
  luv = 0;
}

# count the number of times a line contains the test-suite name
/fwts/ || (/firmware/ && /test/ && /suite/) { ++fwts; }
/luv/ || (/linux/ && /uefi/ && /validation/) { ++luv; }

# match version tags - which are also a good hint, so significantly increase hint counters.
match($0, /Linux UEFI Validation Distribution ([^, <]+)/, m) {
  luv_version = m[1];
  luv += 1000;
}
match($0, /fwts: version ([^ ,<]+)/, m) {
  fwts_version = m[1];
  fwts += 1000;
}

# fwts testing date: day/month/year hour:minute:second
match($0,
      /This test run on ([0-9]{1,2})\/([0-9]{1,2})\/([0-9]{1,4}) at ([0-9]{1,2}):([0-9]{1,2}):([0-9]{1,2})/,
      m) {
  # fixme: replace "20" before 2100 :p
  year  = length(m[3]) == 2 ? "20" m[3] : m[3];
  month = length(m[2]) == 1 ? "0" m[2] : m[2];
  day   = length(m[1]) == 1 ? "0" m[1] : m[1];
  fwts_date = year month day "_" m[4] m[5] m[6];
  fwts += 1000;
}

# luv testing date:
# fwts testing date: day/month/year hour:minute:second
match($0,
      /Date and time of the system :([0-9]{1,4})-([0-9]{1,2})-([0-9]{1,2})--([0-9]{1,2})-([0-9]{1,2})-([0-9]{1,2})/,
      m) {
  # fixme: replace "20" before 2100 :p
  year  = length(m[1]) == 2 ? "20" m[1] : m[1];
  month = length(m[2]) == 1 ? "0" m[2] : m[2];
  day   = length(m[3]) == 1 ? "0" m[3] : m[3];
  luv_date = year m[2] m[3] "_" m[4] m[5] m[6];
  luv += 1000;
}

END {
  if (fwts > luv) {
    tool         = "fwts"
    tool_version = fwts_version;
    date         = fwts_date;
  }
  else if (luv > fwts) {
    tool         = "luv"
    tool_version = luv_version;
    date         = luv_date;
  }
  # empty strings if hint values are equals
  print to_shell_variable("FWTR_TOOL", trim(tool));
  print to_shell_variable("FWTR_DATE", trim(date));
  print to_shell_variable("FWTR_TOOL_VERSION", trim(tool_version));
}
