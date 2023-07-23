// Copyright 2000-2021 JetBrains s.r.o. and contributors. Use of this source code is governed by the Apache 2.0 license.
package diff.comparison;

import ds.Pair;
import thx.BitSet;
import diff.util.MergeRange;
import diff.util.Range;

// import com.intellij.openapi.util.text.Strings.isWhiteSpace
// import java.util.Dynamic
class TrimUtil {
	static public function isPunctuationA(c:String):Bool {
		return isPunctuationB(c.charCodeAt(0));
	}

	static public function isPunctuationB(b:Int):Bool {
		if (b == 95) {
			return false;
		} // exclude '_'

		return b >= 33
			&& b <= 47
			|| // !"#$%&'()Dynamic+,-./
			b >= 58
			&& b <= 64
			|| // :;<=>?@
			b >= 91
			&& b <= 96
			|| // [\]^_`
			b >= 123
			&& b <= 126; // {|}~
	}

	static public function isAlpha(c:Int):Bool {
		if (isWhiteSpaceCodePoint(c)) {
			return false;
		}
		return !isPunctuationB(c);
	}

	static public function isWhiteSpaceCodePoint(c:Int):Bool {
		return c < 128 && StringTools.isSpace(String.fromCharCode(c), 0);
	}

	static public function isContinuousScript(c:Int):Bool {
		if (c < 128) {
			return false;
		}
		if (Std.parseInt(String.fromCharCode(c)) != null) {
			return false;
		}

		return true;
	}

	static public function trimA(text:String, start:Int, end:Int):Pair<Int, Int> {
		return inlineTrimC(start, end, (index -> StringTools.isSpace(text, index)));
	}

	static public function trimB(start:Int, end:Int, ignored:BitSet):Pair<Int, Int> {
		return inlineTrimC(start, end, (index -> ignored[index]));
	}

	static public function trimStart(text:String, start:Int, end:Int):Int {
		return inlineTrimStartA(start, end, (index -> StringTools.isSpace(text, index)));
	}

	static public function trimEnd(text:String, start:Int, end:Int):Int {
		return inlineTrimEndA(start, end, (index -> StringTools.isSpace(text, index)));
	}

	static public function trimC(text1:String, text2:String, start1:Int, start2:Int, end1:Int, end2:Int):Range {
		return inlineTrimA(start1, start2, end1, end2, (index -> StringTools.isSpace(text1, index)), (index -> StringTools.isSpace(text2, index)));
	}

	static public function trimD(text1:String, text2:String, text3:String, start1:Int, start2:Int, start3:Int, end1:Int, end2:Int, end3:Int):MergeRange {
		return inlineTrimB(start1, start2, start3, end1, end2, end3, (index -> StringTools.isSpace(text1, index)),
			(index -> StringTools.isSpace(text2, index)), (index -> StringTools.isSpace(text3, index)));
	}

	static public function expandA(text1:Array<Dynamic>, text2:Array<Dynamic>, start1:Int, start2:Int, end1:Int, end2:Int):Range {
		return inlineExpand(start1, start2, end1, end2, ((index1, index2) -> text1[index1] == text2[index2]));
	}

	static public function expandForwardA(text1:Array<Dynamic>, text2:Array<Dynamic>, start1:Int, start2:Int, end1:Int, end2:Int):Int {
		return inlineExpandForwardA(start1, start2, end1, end2, ((index1, index2) -> text1[index1] == text2[index2]));
	}

	static public function expandBackwardA(text1:Array<Dynamic>, text2:Array<Dynamic>, start1:Int, start2:Int, end1:Int, end2:Int):Int {
		return inlineExpandBackwardA(start1, start2, end1, end2, ((index1, index2) -> text1[index1] == text2[index2]));
	}

	@:generic
	static public function expandB<T>(text1:Array<T>, text2:Array<T>, start1:Int, start2:Int, end1:Int, end2:Int, equals:(T, T) -> Bool):Range {
		return inlineExpand(start1, start2, end1, end2, ((index1, index2) -> equals(text1[index1], text2[index2])));
	}

	static public function expandC(text1:String, text2:String, start1:Int, start2:Int, end1:Int, end2:Int):Range {
		return inlineExpand(start1, start2, end1, end2, ((index1, index2) -> text1.charAt(index1) == text2.charAt(index2)));
	}

	static public function expandForwardB(text1:String, text2:String, start1:Int, start2:Int, end1:Int, end2:Int):Int {
		return inlineExpandForwardA(start1, start2, end1, end2, ((index1, index2) -> text1.charAt(index1) == text2.charAt(index2)));
	}

	static public function expandBackwardB(text1:String, text2:String, start1:Int, start2:Int, end1:Int, end2:Int):Int {
		return inlineExpandBackwardA(start1, start2, end1, end2, ((index1, index2) -> text1.charAt(index1) == text2.charAt(index2)));
	}

	static public function expandWhitespacesA(text1:String, text2:String, start1:Int, start2:Int, end1:Int, end2:Int):Range {
		return inlineExpandIgnoredA(start1, start2, end1, end2, ((index1, index2) -> text1.charAt(index1) == text2.charAt(index2)),
			(index -> StringTools.isSpace(text1, index)));
	}

	static public function expandWhitespacesForwardA(text1:String, text2:String, start1:Int, start2:Int, end1:Int, end2:Int):Int {
		return inlineExpandIgnoredForwardA(start1, start2, end1, end2, ((index1, index2) -> text1.charAt(index1) == text2.charAt(index2)),
			(index -> StringTools.isSpace(text1, index)));
	}

	static public function expandWhitespacesBackwardA(text1:String, text2:String, start1:Int, start2:Int, end1:Int, end2:Int):Int {
		return inlineExpandIgnoredBackwardA(start1, start2, end1, end2, ((index1, index2) -> text1.charAt(index1) == text2.charAt(index2)),
			(index -> StringTools.isSpace(text1, index)));
	}

	static public function expandWhitespacesB(text1:String, text2:String, text3:String, start1:Int, start2:Int, start3:Int, end1:Int, end2:Int,
			end3:Int):MergeRange {
		return inlineExpandIgnoredB(start1, start2, start3, end1, end2, end3, ((index1, index2) -> text1.charAt(index1) == text2.charAt(index2)),
			((index1, index3) -> text1.charAt(index1) == text3.charAt(index3)), (index -> StringTools.isSpace(text1, index)));
	}

	static public function expandWhitespacesForwardB(text1:String, text2:String, text3:String, start1:Int, start2:Int, start3:Int, end1:Int, end2:Int,
			end3:Int):Int {
		return inlineExpandIgnoredForwardB(start1, start2, start3, end1, end2, end3, ((index1, index2) -> text1.charAt(index1) == text2.charAt(index2)),
			((index1, index3) -> text1.charAt(index1) == text3.charAt(index3)), (index -> StringTools.isSpace(text1, index)));
	}

	static public function expandWhitespacesBackwardB(text1:String, text2:String, text3:String, start1:Int, start2:Int, start3:Int, end1:Int, end2:Int,
			end3:Int):Int {
		return inlineExpandIgnoredBackwardB(start1, start2, start3, end1, end2, end3, ((index1, index2) -> text1.charAt(index1) == text2.charAt(index2)),
			((index1, index3) -> text1.charAt(index1) == text3.charAt(index3)), (index -> StringTools.isSpace(text1, index)));
	}

	static public function trimExpandRange(start1:Int, start2:Int, end1:Int, end2:Int, equals:(Int, Int) -> Bool, ignored1:(Int) -> Bool,
			ignored2:(Int) -> Bool):Range {
		return inlineTrimExpandA(start1, start2, end1, end2, ((index1, index2) -> equals(index1, index2)), (index->ignored1(index)), (index->ignored2(index)));
	}

	static public function trimExpandText(text1:String, text2:String, start1:Int, start2:Int, end1:Int, end2:Int, ignored1:BitSet, ignored2:BitSet):Range {
		return inlineTrimExpandA(start1, start2, end1, end2, ((index1, index2) -> text1.charAt(index1) == text2.charAt(index2)), (index -> ignored1[index]),
			(index -> ignored2[index]));
	}

	static public function trimE(text1:String, text2:String, range:Range):Range {
		return trimC(text1, text2, range.start1, range.start2, range.end1, range.end2);
	}

	static public function trimF(text1:String, text2:String, text3:String, range:MergeRange):MergeRange {
		return trimD(text1, text2, text3, range.start1, range.start2, range.start3, range.end1, range.end2, range.end3);
	}

	static public function expandD(text1:String, text2:String, range:Range):Range {
		return expandC(text1, text2, range.start1, range.start2, range.end1, range.end2);
	}

	static public function expandWhitespacesC(text1:String, text2:String, range:Range):Range {
		return expandWhitespacesA(text1, text2, range.start1, range.start2, range.end1, range.end2);
	}

	static public function expandWhitespacesD(text1:String, text2:String, text3:String, range:MergeRange):MergeRange {
		return expandWhitespacesB(text1, text2, text3, range.start1, range.start2, range.start3, range.end1, range.end2, range.end3);
	}

	static public function isEqualsA(text1:String, text2:String, range:Range):Bool {
		var sequence1 = text1.substring(range.start1, range.end1);
		var sequence2 = text2.substring(range.start2, range.end2);
		return ComparisonUtil.isEqualTexts(sequence1, sequence2, ComparisonPolicy.DEFAULT);
	}

	static public function isEqualsIgnoreWhitespacesA(text1:String, text2:String, range:Range):Bool {
		var sequence1 = text1.substring(range.start1, range.end1);
		var sequence2 = text2.substring(range.start2, range.end2);
		return ComparisonUtil.isEqualTexts(sequence1, sequence2, ComparisonPolicy.IGNORE_WHITESPACES);
	}

	static public function isEqualsB(text1:String, text2:String, text3:String, range:MergeRange):Bool {
		var sequence1 = text1.substring(range.start1, range.end1);
		var sequence2 = text2.substring(range.start2, range.end2);
		var sequence3 = text3.substring(range.start3, range.end3);
		return ComparisonUtil.isEqualTexts(sequence2, sequence1, ComparisonPolicy.DEFAULT)
			&& ComparisonUtil.isEqualTexts(sequence2, sequence3, ComparisonPolicy.DEFAULT);
	}

	static public function isEqualsIgnoreWhitespacesB(text1:String, text2:String, text3:String, range:MergeRange):Bool {
		var sequence1 = text1.substring(range.start1, range.end1);
		var sequence2 = text2.substring(range.start2, range.end2);
		var sequence3 = text3.substring(range.start3, range.end3);
		return ComparisonUtil.isEqualTexts(sequence2, sequence1, ComparisonPolicy.IGNORE_WHITESPACES)
			&& ComparisonUtil.isEqualTexts(sequence2, sequence3, ComparisonPolicy.IGNORE_WHITESPACES);
	}

	//
	// Trim
	//

	static private inline function inlineTrimA(start1:Int, start2:Int, end1:Int, end2:Int, ignored1:(Int) -> Bool, ignored2:(Int) -> Bool):Range {
		var start1 = start1;
		var start2 = start2;
		var end1 = end1;
		var end2 = end2;

		start1 = inlineTrimStartA(start1, end1, ignored1);
		end1 = inlineTrimEndA(start1, end1, ignored1);
		start2 = inlineTrimStartA(start2, end2, ignored2);
		end2 = inlineTrimEndA(start2, end2, ignored2);

		return new Range(start1, end1, start2, end2);
	}

	static private inline function inlineTrimB(start1:Int, start2:Int, start3:Int, end1:Int, end2:Int, end3:Int, ignored1:(Int) -> Bool,
			ignored2:(Int) -> Bool, ignored3:(Int) -> Bool):MergeRange {
		var start1 = start1;
		var start2 = start2;
		var start3 = start3;
		var end1 = end1;
		var end2 = end2;
		var end3 = end3;

		start1 = inlineTrimStartA(start1, end1, ignored1);
		end1 = inlineTrimEndA(start1, end1, ignored1);
		start2 = inlineTrimStartA(start2, end2, ignored2);
		end2 = inlineTrimEndA(start2, end2, ignored2);
		start3 = inlineTrimStartA(start3, end3, ignored3);
		end3 = inlineTrimEndA(start3, end3, ignored3);

		return new MergeRange(start1, end1, start2, end2, start3, end3);
	}

	static private inline function inlineTrimC(start:Int, end:Int, ignored:(Int) -> Bool):Pair<Int, Int> {
		var start = start;
		var end = end;

		start = inlineTrimStartA(start, end, ignored);
		end = inlineTrimEndA(start, end, ignored);

		return new Pair(start, end);
	}

	static private inline function inlineTrimStartA(start:Int, end:Int, ignored:(Int) -> Bool):Int {
		var start = start;

		while (start < end) {
			if (!ignored(start)) {
				break;
			}
			start++;
		}
		return start;
	}

	static private inline function inlineTrimEndA(start:Int, end:Int, ignored:(Int) -> Bool):Int {
		var end = end;

		while (start < end) {
			if (!ignored(end - 1)) {
				break;
			}
			end--;
		}
		return end;
	}

	//
	// Expand
	//

	static private inline function inlineExpand(start1:Int, start2:Int, end1:Int, end2:Int, equals:(Int, Int) -> Bool):Range {
		var start1 = start1;
		var start2 = start2;
		var end1 = end1;
		var end2 = end2;

		var count1 = inlineExpandForwardA(start1, start2, end1, end2, equals);
		start1 += count1;
		start2 += count1;

		var count2 = inlineExpandBackwardA(start1, start2, end1, end2, equals);
		end1 -= count2;
		end2 -= count2;

		return new Range(start1, end1, start2, end2);
	}

	static private inline function inlineExpandForwardA(start1:Int, start2:Int, end1:Int, end2:Int, equals:(Int, Int) -> Bool):Int {
		var start1 = start1;
		var start2 = start2;

		var oldStart1 = start1;
		while (start1 < end1 && start2 < end2) {
			if (!equals(start1, start2)) {
				break;
			}
			start1++;
			start2++;
		}

		return start1 - oldStart1;
	}

	static private inline function inlineExpandBackwardA(start1:Int, start2:Int, end1:Int, end2:Int, equals:(Int, Int) -> Bool):Int {
		var end1 = end1;
		var end2 = end2;

		var oldEnd1 = end1;
		while (start1 < end1 && start2 < end2) {
			if (!equals(end1 - 1, end2 - 1)) {
				break;
			}
			end1--;
			end2--;
		}

		return oldEnd1 - end1;
	}

	//
	// Expand Ignored
	//

	static private inline function inlineExpandIgnoredA(start1:Int, start2:Int, end1:Int, end2:Int, equals:(Int, Int) -> Bool, ignored1:(Int) -> Bool):Range {
		var start1 = start1;
		var start2 = start2;
		var end1 = end1;
		var end2 = end2;

		var count1 = inlineExpandIgnoredForwardA(start1, start2, end1, end2, equals, ignored1);
		start1 += count1;
		start2 += count1;

		var count2 = inlineExpandIgnoredBackwardA(start1, start2, end1, end2, equals, ignored1);
		end1 -= count2;
		end2 -= count2;

		return new Range(start1, end1, start2, end2);
	}

	static private inline function inlineExpandIgnoredForwardA(start1:Int, start2:Int, end1:Int, end2:Int, equals:(Int, Int) -> Bool,
			ignored1:(Int) -> Bool):Int {
		var start1 = start1;
		var start2 = start2;

		var oldStart1 = start1;
		while (start1 < end1 && start2 < end2) {
			if (!equals(start1, start2)) {
				break;
			}
			if (!ignored1(start1)) {
				break;
			}
			start1++;
			start2++;
		}

		return start1 - oldStart1;
	}

	static private inline function inlineExpandIgnoredBackwardA(start1:Int, start2:Int, end1:Int, end2:Int, equals:(Int, Int) -> Bool,
			ignored1:(Int) -> Bool):Int {
		var end1 = end1;
		var end2 = end2;

		var oldEnd1 = end1;
		while (start1 < end1 && start2 < end2) {
			if (!equals(end1 - 1, end2 - 1)) {
				break;
			}
			if (!ignored1(end1 - 1)) {
				break;
			}
			end1--;
			end2--;
		}

		return oldEnd1 - end1;
	}

	static private inline function inlineExpandIgnoredB(start1:Int, start2:Int, start3:Int, end1:Int, end2:Int, end3:Int, equals12:(Int, Int) -> Bool,
			equals13:(Int, Int) -> Bool, ignored1:(Int) -> Bool):MergeRange {
		var start1 = start1;
		var start2 = start2;
		var start3 = start3;
		var end1 = end1;
		var end2 = end2;
		var end3 = end3;

		var count1 = inlineExpandIgnoredForwardB(start1, start2, start3, end1, end2, end3, equals12, equals13, ignored1);
		start1 += count1;
		start2 += count1;
		start3 += count1;

		var count2 = inlineExpandIgnoredBackwardB(start1, start2, start3, end1, end2, end3, equals12, equals13, ignored1);
		end1 -= count2;
		end2 -= count2;
		end3 -= count2;

		return new MergeRange(start1, end1, start2, end2, start3, end3);
	}

	static private inline function inlineExpandIgnoredForwardB(start1:Int, start2:Int, start3:Int, end1:Int, end2:Int, end3:Int, equals12:(Int, Int) -> Bool,
			equals13:(Int, Int) -> Bool, ignored1:(Int) -> Bool):Int {
		var start1 = start1;
		var start2 = start2;
		var start3 = start3;

		var oldStart1 = start1;
		while (start1 < end1 && start2 < end2 && start3 < end3) {
			if (!equals12(start1, start2)) {
				break;
			}
			if (!equals13(start1, start3)) {
				break;
			}
			if (!ignored1(start1)) {
				break;
			}
			start1++;
			start2++;
			start3++;
		}

		return start1 - oldStart1;
	}

	static private inline function inlineExpandIgnoredBackwardB(start1:Int, start2:Int, start3:Int, end1:Int, end2:Int, end3:Int, equals12:(Int, Int) -> Bool,
			equals13:(Int, Int) -> Bool, ignored1:(Int) -> Bool):Int {
		var end1 = end1;
		var end2 = end2;
		var end3 = end3;

		var oldEnd1 = end1;
		while (start1 < end1 && start2 < end2 && start3 < end3) {
			if (!equals12(end1 - 1, end2 - 1)) {
				break;
			}
			if (!equals13(end1 - 1, end3 - 1)) {
				break;
			}
			if (!ignored1(end1 - 1)) {
				break;
			}
			end1--;
			end2--;
			end3--;
		}

		return oldEnd1 - end1;
	}

	//
	// Trim Expand
	//

	static private inline function inlineTrimExpandA(start1:Int, start2:Int, end1:Int, end2:Int, equals:(Int, Int) -> Bool, ignored1:(Int) -> Bool,
			ignored2:(Int) -> Bool):Range {
		var start1 = start1;
		var start2 = start2;
		var end1 = end1;
		var end2 = end2;

		var starts = inlineTrimExpandForwardA(start1, start2, end1, end2, equals, ignored1, ignored2);
		start1 = starts.first;
		start2 = starts.second;

		var ends = inlineTrimExpandBackwardA(start1, start2, end1, end2, equals, ignored1, ignored2);
		end1 = ends.first;
		end2 = ends.second;

		return new Range(start1, end1, start2, end2);
	}

	static private inline function inlineTrimExpandForwardA(start1:Int, start2:Int, end1:Int, end2:Int, equals:(Int, Int) -> Bool, ignored1:(Int) -> Bool,
			ignored2:(Int) -> Bool):Pair<Int, Int> {
		var start1 = start1;
		var start2 = start2;

		while (start1 < end1 && start2 < end2) {
			if (equals(start1, start2)) {
				start1++;
				start2++;
				continue;
			}

			var skipped = false;
			if (ignored1(start1)) {
				skipped = true;
				start1++;
			}
			if (ignored2(start2)) {
				skipped = true;
				start2++;
			}
			if (!skipped) {
				break;
			}
		}

		start1 = inlineTrimStartA(start1, end1, ignored1);
		start2 = inlineTrimStartA(start2, end2, ignored2);

		return new Pair(start1, start2);
	}

	static private inline function inlineTrimExpandBackwardA(start1:Int, start2:Int, end1:Int, end2:Int, equals:(Int, Int) -> Bool, ignored1:(Int) -> Bool,
			ignored2:(Int) -> Bool):Pair<Int, Int> {
		var end1 = end1;
		var end2 = end2;

		while (start1 < end1 && start2 < end2) {
			if (equals(end1 - 1, end2 - 1)) {
				end1--;
				end2--;
				continue;
			}

			var skipped = false;
			if (ignored1(end1 - 1)) {
				skipped = true;
				end1--;
			}
			if (ignored2(end2 - 1)) {
				skipped = true;
				end2--;
			}
			if (!skipped) {
				break;
			}
		}

		end1 = inlineTrimEndA(start1, end1, ignored1);
		end2 = inlineTrimEndA(start2, end2, ignored2);

		return new Pair(end1, end2);
	}
}
