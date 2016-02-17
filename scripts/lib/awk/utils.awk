#
# Toolbox of GNU Awk functions.
#

#
# Return the string of a shell variable definition named `name` with quoted value `value`".
#
function to_shell_variable(name, value) {
  return name "='" escape_shell_quoted_text(value) "'"
}

#
# Escape a quoted text by adding backspaces behind simple quotes.
#
function escape_shell_quoted_text(text) {
  # escape simple quotes
  gsub(/'/, "\\'", text);
  return text;
}

#
# Sanitize a string by removing non ascii chars and truncating multiple spaces into a single one.
#
function sanitize_text(text) {
  # remove non-ascii characters
  # this set may evolve with time and only reflects the set of characters required for the
  # set of results we have so far.
  gsub(/[^[\x00-\x7F]]|[\(\)]/, "", text);
  gsub(/[[:space:]]{2,}/, " ", text);
  return trim(text);
}

#
# Trim functions
#
function ltrim(s) { sub(/^[ \t\r\n]+/, "", s); return s }
function rtrim(s) { sub(/[ \t\r\n]+$/, "", s); return s }
function trim(s)  { return rtrim(ltrim(s)); }

#
# Return the text of current row starting from the nth column `c`.
#
function text_from_nth_col(c) {
  for (i = c - 1; i >= 1; --i)
    $i="";
  return $0;
}

#
# Setter of dynamically-named variable (aka indirect reference).
# Users of this functions are required to implement a setter function for each variable
# named `set_<variable>(value)`.
# gawk does not support dynamically name variables, but it does support indirect *function*
# calls. So the trick here is to call a dedicated setter of the variable.
#
function set(variable, value) {
  call="set_" variable
  @call(value)
}
