package util;

function trimTrailingNewline(string:String):String {
	if (StringTools.endsWith(string, "\n")) {
		return string.substring(0, string.length - 1);
	}

	return string;
}
