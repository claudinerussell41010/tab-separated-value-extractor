#!/usr/bin/env bash
# Tests for tab_separated_value_extractor.sh.
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=tab_separated_value_extractor.sh
source "${SCRIPT_DIR}/tab_separated_value_extractor.sh"

assert_eq() {
  local expected=$1 actual=$2 label=$3
  if [[ $expected == "$actual" ]]; then
    printf 'ok - %s\n' "$label"
  else
    printf 'not ok - %s\n' "$label"
    printf '  expected: %q\n' "$expected"
    printf '  actual:   %q\n' "$actual"
    exit 1
  fi
}

# A plain row of three fields.
result=$(tsv_extract_fields $'a\tb\tc')
assert_eq $'a\nb\nc' "$result" "plain fields"

# A quoted field may contain a tab.
result=$(tsv_extract_fields $'a\t"b\tc"\td')
assert_eq $'a\nb\tc\nd' "$result" "quoted tab"

# A quoted field may contain a newline.
result=$(tsv_extract_fields $'a\t"b\nc"\td')
assert_eq $'a\nb\nc\nd' "$result" "quoted newline"

# Doubled quotes collapse to one quote.
result=$(tsv_extract_fields $'"a""b"\tc')
assert_eq $'a"b\nc' "$result" "doubled quote"

# An unquoted newline ends the record; the next row follows after a blank line.
result=$(tsv_extract_fields $'a\tb\nc\td')
assert_eq $'a\nb\n\nc\nd' "$result" "two rows"

# Empty fields are preserved.
result=$(tsv_extract_fields $'a\t\tb')
assert_eq $'a\n\nb' "$result" "empty field"

# tsv_extract_field returns the requested column.
result=$(tsv_extract_field $'a\tb\tc' 1)
assert_eq 'b' "$result" "field index 1"

# tsv_extract_field returns non-zero for an out-of-range index.
if tsv_extract_field $'a\tb' 2 >/dev/null; then
  printf 'not ok - out of range index should fail\n'
  exit 1
else
  printf 'ok - out of range index fails\n'
fi

printf '1..8\n'
