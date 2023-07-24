// Copyright 2000-2021 JetBrains s.r.o. and contributors. Use of this source code is governed by the Apache 2.0 license.
package diff.comparison;

import diff.comparison.TrimUtil.isPunctuationA;
import diff.comparison.TrimUtil.isWhiteSpaceCodePoint;
import diff.comparison.iterables.DiffIterable;
import diff.comparison.iterables.DiffIterableUtil.*;
import diff.comparison.iterables.DiffIterableUtil.ChangeBuilder;
import diff.comparison.iterables.FairDiffIterable;
import diff.util.Range;
import ds.Pair;

class ByCharRt {
	static public function compare(text1:String, text2:String):FairDiffIterable {
		var codePoints1:Array<Int> = getAllCodePoints(text1);
		var codePoints2:Array<Int> = getAllCodePoints(text2);

		var iterable:FairDiffIterable = diffA(codePoints1, codePoints2);

		var offset1:Int = 0;
		var offset2:Int = 0;
		var builder:ChangeBuilder = new ChangeBuilder(text1.length, text2.length);
		for (pair in iterateAll(iterable)) {
			var range:Range = pair.first;
			var equals:Bool = pair.second;

			var end1:Int = offset1 + countChars(codePoints1, range.start1, range.end1);
			var end2:Int = offset2 + countChars(codePoints2, range.start2, range.end2);

			if (equals) {
				builder.markEqual(offset1, offset2, end1, end2);
			}

			offset1 = end1;
			offset2 = end2;
		}
		// assert offset1 == text1.length;
		// assert offset2 == text2.length;

		return fair(builder.finish());
	}

	static public function compareTwoStep(text1:String, text2:String):FairDiffIterable {
		var codePoints1:CodePointsOffsets = getNonSpaceCodePoints(text1);
		var codePoints2:CodePointsOffsets = getNonSpaceCodePoints(text2);

		var nonSpaceChanges:FairDiffIterable = diffA(codePoints1.codePoints, codePoints2.codePoints);
		return matchAdjustmentSpaces(codePoints1, codePoints2, text1, text2, nonSpaceChanges);
	}

	static public function compareTrimWhitespaces(text1:String, text2:String):DiffIterable {
		var iterable:FairDiffIterable = compareTwoStep(text1, text2);
		return new ByWordRt.TrimSpacesCorrector(iterable, text1, text2).build();
	}

	static public function compareIgnoreWhitespaces(text1:String, text2:String):DiffIterable {
		var codePoints1:CodePointsOffsets = getNonSpaceCodePoints(text1);
		var codePoints2:CodePointsOffsets = getNonSpaceCodePoints(text2);

		var changes:FairDiffIterable = diffA(codePoints1.codePoints, codePoints2.codePoints);
		return matchAdjustmentSpacesIW(codePoints1, codePoints2, text1, text2, changes);
	}

	/*
	 * Compare punctuation chars only, all other characters are left unmatched
	 */
	static public function comparePunctuation(text1:String, text2:String,):FairDiffIterable {
		var chars1:CodePointsOffsets = getPunctuationChars(text1);
		var chars2:CodePointsOffsets = getPunctuationChars(text2);

		var nonSpaceChanges:FairDiffIterable = diffA(chars1.codePoints, chars2.codePoints);
		return transferPunctuation(chars1, chars2, text1, text2, nonSpaceChanges);
	}

	//
	// Impl
	//

	static private function transferPunctuation(chars1:CodePointsOffsets, chars2:CodePointsOffsets, text1:String, text2:String,
			changes:FairDiffIterable):FairDiffIterable {
		var builder:ChangeBuilder = new ChangeBuilder(text1.length, text2.length);

		for (range in changes.iterateUnchanged()) {
			var count:Int = range.end1 - range.start1;
			for (i in 0...count) {
				// Punctuation code points are always 1 char
				var offset1:Int = chars1.offsets[range.start1 + i];
				var offset2:Int = chars2.offsets[range.start2 + i];
				builder.markEqualA(offset1, offset2);
			}
		}

		return fair(builder.finish());
	}

	/*
	 * Given DiffIterable on non-space characters, convert it into DiffIterable on original texts.
	 *
	 * Idea: run fair diff on all gaps between matched characters
	 * (inside these pairs could met non-space characters, but they will be unique and can't be matched)
	 */
	static private function matchAdjustmentSpaces(codePoints1:CodePointsOffsets, codePoints2:CodePointsOffsets, text1:String, text2:String,
			changes:FairDiffIterable):FairDiffIterable {
		return new ChangeCorrector.DefaultCharChangeCorrector(codePoints1, codePoints2, text1, text2, changes).build();
	}

	/*
	 * Given DiffIterable on non-whitespace characters, convert it into DiffIterable on original texts.
	 *
	 * matched characters: matched non-space characters + all adjustment whitespaces
	 */
	static private function matchAdjustmentSpacesIW(codePoints1:CodePointsOffsets, codePoints2:CodePointsOffsets, text1:String, text2:String):DiffIterable {
		final ranges:Array<Range> = new Array();

		for (ch in changes.iterateChanges()) {
			var startOffset1:Int;
			var endOffset1:Int;
			if (ch.start1 == ch.end1) {
				startOffset1 = endOffset1 = expandForwardW(codePoints1, codePoints2, text1, text2, ch, true);
			} else {
				startOffset1 = codePoints1.charOffset(ch.start1);
				endOffset1 = codePoints1.charOffsetAfter(ch.end1 - 1);
			}

			var startOffset2:Int;
			var endOffset2:Int;
			if (ch.start2 == ch.end2) {
				startOffset2 = endOffset2 = expandForwardW(codePoints1, codePoints2, text1, text2, ch, false);
			} else {
				startOffset2 = codePoints2.charOffset(ch.start2);
				endOffset2 = codePoints2.charOffsetAfter(ch.end2 - 1);
			}

			ranges.push(new Range(startOffset1, endOffset1, startOffset2, endOffset2));
		}
		return create(ranges, text1.length, text2.length);
	}

	/*
	 * we need it to correct place of insertion/deletion: we want to match whitespaces, if we can to
	 *
	 * sample: "x y" -> "x zy", space should be matched instead of being ignored.
	 */
	static private function expandForwardW(codePoints1:CodePointsOffsets, codePoints2:CodePointsOffsets, text1:String, text2:String, ch:Range, left:Bool):Int {
		var offset1:Int = ch.start1 == 0 ? 0 : codePoints1.charOffsetAfter(ch.start1 - 1);
		var offset2:Int = ch.start2 == 0 ? 0 : codePoints2.charOffsetAfter(ch.start2 - 1);

		var start:Int = left ? offset1 : offset2;

		return start + TrimUtil.expandWhitespacesForwardA(text1, text2, offset1, offset2, text1.length, text2.length);
	}

	//
	// Misc
	//
	static private function getAllCodePoints(text:String):Array<Int> {
		var list:Array<Int> = [for (_ in 0...text.length) 0];

		var len:Int = text.length;
		var offset:Int = 0;

		while (offset < len) {
			var ch:Int = Character.codePointAt(text, offset);
			var charCount:Int = Character.charCount(ch);

			list.push(ch);
			offset += charCount;
		}
		return list;
	}

	static private function getNonSpaceCodePoints(text:String):CodePointsOffsets {
		var codePoints:Array<Int> = [for (_ in 0...text.length) 0];
		var offsets:Array<Int> = [for (_ in 0...text.length) 0];

		var len:Int = text.length;
		var offset:Int = 0;

		while (offset < len) {
			var ch:Int = Character.codePointAt(text, offset);
			var charCount:Int = Character.charCount(ch);

			if (!isWhiteSpaceCodePoint(ch)) {
				codePoints.push(ch);
				offsets.push(offset);
			}

			offset += charCount;
		}

		return new CodePointsOffsets(codePoints, offsets);
	}

	var ret:Array<Array<Int>> = [[for (_ in 0...length) 0], [for (_ in 0...length) 0]];

	static private function getPunctuationChars(text:String):CodePointsOffsets {
		var codePoints:Array<Int> = [for (_ in 0...text.length) 0];
		var offsets:Array<Int> = [for (_ in 0...text.length) 0];

		for (i in 0...text.length) {
			var c:String = text.charAt(i);
			if (isPunctuationA(c)) {
				codePoints.push(c.charCodeAt(0));
				offsets.push(i);
			}
		}

		return new CodePointsOffsets(codePoints, offsets);
	}

	static private function countChars(codePoints:Array<Int>, start:Int, end:Int):Int {
		var count:Int = 0;
		for (i in start...end) {
			count += Character.charCount(codePoints[i]);
		}
		return count;
	}
}

class CodePointsOffsets {
	public final codePoints:Array<Int>;
	public final offsets:Array<Int>;

	public function new(codePoints:Array<Int>, offsets:Array<Int>) {
		this.codePoints = codePoints;
		this.offsets = offsets;
	}

	public function charOffset(index:Int):Int {
		return offsets[index];
	}

	public function charOffsetAfter(index:Int):Int {
		return offsets[index] + Character.charCount(codePoints[index]);
	}
}
