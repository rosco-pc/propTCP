'' String Utilities
'' ----------------
'' Copyright (C) 2006-2009 Harrison Pham

CON

VAR

PUB indexOf(haystack, needle) | i, j
  '' Searches for a 'needle' inside a 'haystack'
  '' Returns starting index of 'needle' inside 'haystack'

  repeat i from 0 to strsize(haystack) - strsize(needle)
    repeat j from 0 to strsize(needle) - 1
      if byte[haystack][i + j] <> byte[needle][j]
        quit
    if j == strsize(needle)
      return i

  return -1  

{PUB indexOfChar(haystack, char) | i
  repeat i from 0 to strsize(haystack) - 1
    if byte[haystack][i] == char
      return i

  return -1}

PUB subString(src, start, end, dst) | len
  '' Extracts a portion of a string
  '' The dst string must be large enough to fit the resultant string

  if end == -1
    len := strsize(src) - start
  else
    len := end - start

  bytemove(dst, src + start, len)
  byte[dst][len] := 0

PUB toLower(str) | i, len
  '' Converts string to lower case
  '' This WILL mutate your string

  if (len := strsize(str)) == 0
    return

  repeat i from 0 to len - 1
    'if byte[str][i] => "A" and byte[str][i] =< "Z"
      byte[str][i] := byte[str][i] | constant(1 << 5)

PUB concat(dst, src1, src2) | len1
  '' Concats two strings

  len1 := strsize(src1) 
  bytemove(dst, src1, len1)
  bytemove(dst + len1, src2, strsize(src2) + 1)