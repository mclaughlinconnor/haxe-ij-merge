package util;

function pushLinesUntil(formattedString:StringBuf, lines:Array<String>, start: Int, end:Int) {
  while (start < end) {
    formattedString.add(lines[start]);
    formattedString.add("\n");
    start++;
  }

  return start;
}
