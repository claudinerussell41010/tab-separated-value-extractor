#!/usr/bin/env bash
# tab_separated_value_extractor.sh -- split TSV rows into fields.
#
# The parser follows RFC 4180-style quoting, but with tabs as the delimiter:
# a field wrapped in double quotes may contain tabs, newlines and doubled
# quotes.  The whole input is read as one record only when it is a single
# row; multi-row input is split on unquoted newlines first.
#
# Why a shell library?  Shell pipelines routinely need to pull a column out
# of TSV output without pulling in a full CSV parser.  This keeps the
# contract small: read a string, emit fields, one per line.

# shellcheck shell=bash

# tsv_extract_fields <text>
#
# Split <text> into TSV fields and print one field per line.  Quoted fields
# keep their tabs and newlines; doubled quotes inside a quoted field collapse
# to a single quote.
tsv_extract_fields() {
  local input=$1
  local len=${#input}
  local i=0 ch in_quotes=0
  local field=''

  while (( i < len )); do
    ch=${input:i:1}
    if (( in_quotes )); then
      if [[ $ch == '"' ]]; then
        if (( i + 1 < len )) && [[ ${input:i+1:1} == '"' ]]; then
          field+='"'
          (( i += 2 ))
          continue
        fi
        in_quotes=0
      else
        field+=$ch
      fi
    else
      if [[ $ch == '"' ]]; then
        in_quotes=1
      elif [[ $ch == $'\t' ]]; then
        printf '%s\n' "$field"
        field=''
      elif [[ $ch == $'\n' ]]; then
        printf '%s\n' "$field"
        field=''
        printf '\n'
      else
        field+=$ch
      fi
    fi
    (( i++ ))
  done
  printf '%s\n' "$field"
}

# tsv_extract_field <text> <index>
#
# Print the zero-based field at <index> from <text>.  Returns 1 if the index
# is out of range, because silently printing an empty string hides bugs in
# callers that assume a column exists.
tsv_extract_field() {
  local input=$1 index=$2
  local -a fields=()
  local line
  while IFS= read -r line; do
    fields+=("$line")
  done < <(tsv_extract_fields "$input")
  if (( index < 0 || index >= ${#fields[@]} )); then
    return 1
  fi
  printf '%s\n' "${fields[index]}"
}
