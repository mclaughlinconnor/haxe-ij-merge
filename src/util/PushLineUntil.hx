package util;

function pushLinesUntil(formattedString:StringBuf, lines:Array<String>, start:Int, end:Int, trailingNewline:Bool = true) {
	if (start == end) {
		return start;
	}

	while (start < end - 1) {
		formattedString.add(lines[start++]);
		formattedString.add("\n");
	}

	formattedString.add(lines[start++]);
	if (trailingNewline) {
		formattedString.add("\n");
	}

	return start;
}
