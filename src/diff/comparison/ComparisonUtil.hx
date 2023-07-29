// Copyright 2000-2021 JetBrains s.r.o. and contributors. Use of this source code is governed by the Apache 2.0 license.
package diff.comparison;

import config.DiffConfig;
import exceptions.IllegalArgumentException;
import diff.comparison.TrimUtil.trimEnd;
import diff.comparison.TrimUtil.trimStart;

class ComparisonUtil {
	static public function isEquals(text1:Null<String>, text2:Null<String>, policy:ComparisonPolicy):Bool {
		if (text1 == text2) {
			return true;
		}
		if (text1 == null || text2 == null) {
			return false;
		}

		switch (policy) {
			case DEFAULT:
				return text1 == text2;
			case TRIM_WHITESPACES:
				return StringTools.trim(text1) == StringTools.trim(text2);
			case IGNORE_WHITESPACES:
				return equalsIgnoreWhitespaces(text1, text2);
			default:
				throw new IllegalArgumentException('');
		}
	}

	static public function isEqualTexts(text1:String, text2:String, policy:ComparisonPolicy):Bool {
		switch (policy) {
			case DEFAULT:
				return text1 == text2;
			case TRIM_WHITESPACES:
				return StringTools.trim(text1) == StringTools.trim(text2);
			case IGNORE_WHITESPACES:
				return equalsIgnoreWhitespaces(text1, text2);
			default:
				throw new IllegalArgumentException('');
		}
	}

	/**
	 * Method is different from {@link Strings#equalsTrimWhitespaces(String, String)}.
	 * <p>
	 * Here, leading/trailing whitespaces for *inner* lines will be ignored as well.
	 * Ex: "\nXY\n" and "\n XY \n" strings are equal, "\nXY\n" and "\nX Y\n" strings are different.
	 */
	static public function equalsTrimWhitespaces(s1:String, s2:String):Bool {
		var index1:Int = 0;
		var index2:Int = 0;

		while (true) {
			var lastLine1:Bool = false;
			var lastLine2:Bool = false;

			var end1:Int = s1.indexOf('\n', index1) + 1;
			var end2:Int = s2.indexOf('\n', index2) + 1;
			if (end1 == 0) {
				end1 = s1.length;
				lastLine1 = true;
			}
			if (end2 == 0) {
				end2 = s2.length;
				lastLine2 = true;
			}
			var x = lastLine1 ? 1 : 0;
			var y = lastLine2 ? 1 : 0;
			if ((x ^ y) == 1) {
				return false;
			}

			var line1:String = s1.substring(index1, end1);
			var line2:String = s2.substring(index2, end2);
			if (StringTools.trim(line1) != StringTools.trim(line2)) {
				return false;
			}

			index1 = end1;
			index2 = end2;
			if (lastLine1) {
				return true;
			}
		}
	}

	static public function getUnimportantLineCharCount():Int {
		return DiffConfig.UNIMPORTANT_LINE_CHAR_COUNT;
	}
}

function equalsIgnoreWhitespaces(s1:Null<String>, s2:Null<String>):Bool {
	var x = s2 == null ? 1 : 0;
	var y = s1 == null ? 1 : 0;
	if ((x ^ y) == 1) {
		return false;
	}

	if (s1 == null) {
		return true;
	}

	var len1:Int = s1.length;
	var len2:Int = s2.length;

	var index1:Int = 0;
	var index2:Int = 0;
	while (index1 < len1 && index2 < len2) {
		if (s1.charCodeAt(index1) == s2.charCodeAt(index2)) {
			index1++;
			index2++;
			continue;
		}

		var skipped:Bool = false;
		while (index1 != len1 && StringTools.isSpace(s1, index1)) {
			skipped = true;
			index1++;
		}
		while (index2 != len2 && StringTools.isSpace(s2, index2)) {
			skipped = true;
			index2++;
		}

		if (!skipped) {
			return false;
		}
	}

	while (index1 != len1) {
		if (!StringTools.isSpace(s1, index1)) {
			return false;
		}
		index1++;
	}
	while (index2 != len2) {
		if (!StringTools.isSpace(s2, index2)) {
			return false;
		}
		index2++;
	}

	return true;
}
