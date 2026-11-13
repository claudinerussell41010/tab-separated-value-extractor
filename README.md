# tab-separated-value-extractor

Splits TSV rows into fields, keeping tabs and newlines that appear inside
double-quoted fields.

```bash
source tab_separated_value_extractor.sh

# One field per line:
tsv_extract_fields $'name\tage\tcity'
# name
# age
# city

# Quoted tabs stay inside the field:
tsv_extract_fields $'a\t"b\tc"\td'
# a
# b	c
# d

# Pick a single column (zero-based):
tsv_extract_field $'a\tb\tc' 1
# b
```

## Why this exists

Shell pipelines often need one column out of TSV output.  `cut -f` is fine
until a field contains a quoted tab or a quoted newline, at which point the
column boundaries shift.  This library reads the whole string, tracks quote
state, and emits fields one per line, so the result can be fed straight into
`read` or `mapfile`.

The trade-off is that the parser is a small state machine written in pure
Bash.  It is not a streaming parser and it does not support backslash
escapes; if you need those, a real parser is the right tool.  The whole input
is read as one record only when it is a single row; multi-row input is split
on unquoted newlines first, which is the common case for command output.

## Edge you will hit

A newline inside a quoted field is preserved, but an unquoted newline ends the
record.  `tsv_extract_fields` therefore prints a blank line between records,
which makes the output easy to split back into rows with a simple loop.

## API

- `tsv_extract_fields <text>` -- print one field per line.  Returns 0.
- `tsv_extract_field <text> <index>` -- print the zero-based field at
  `<index>`.  Returns 1 if the index is out of range.
