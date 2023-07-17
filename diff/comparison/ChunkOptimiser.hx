// Copyright 2000-2021 JetBrains s.r.o. and contributors. Use of this source code is governed by the Apache 2.0 license.
package diff.comparison;

import diff.util.Side;
import diff.comparison.ByLineRt.Line;
import diff.comparison.ByWordRt;
import diff.comparison.iterables.FairDiffIterable;
import diff.util.Range;

@:generic
abstract class ChunkOptimizer<T> {
	private final myData1:Array<T>;
	private final myData2:Array<T>;
	private final myIterable:FairDiffIterable;

	private final myRanges:Array<Range>;

	public function new(data1:Array<T>, data2:Array<T>, iterable:FairDiffIterable) {
		myData1 = data1;
		myData2 = data2;
		myIterable = iterable;

		myRanges = new Array();
	}

	public function build():FairDiffIterable {
		for (range in myIterable.iterateUnchanged()) {
			myRanges.push(range);
			processLastRanges();
		}

		return DiffIterableUtil.fair(createUnchanged(myRanges, myData1.length, myData2.length));
	}

	private function processLastRanges():Void {
		if (myRanges.length < 2)
			return; // nothing to do

		var range1:Range = myRanges[myRanges.length - 2];
		var range2:Range = myRanges[myRanges.length - 1];
		if (range1.end1 != range2.start1 && range1.end2 != range2.start2) {
			// if changes do not touch and we still can perform one of these optimisations,
			// it means that given DiffIterable is not LCS (because we can build a smaller one). This should not happen.
			return;
		}

		var count1:Int = range1.end1 - range1.start1;
		var count2:Int = range2.end1 - range2.start1;

		var equalForward:Int = expandForward(myData1, myData2, range1.end1, range1.end2, range1.end1 + count2, range1.end2 + count2);
		var equalBackward:Int = expandBackward(myData1, myData2, range2.start1 - count1, range2.start2 - count1, range2.start1, range2.start2);

		// nothing to do
		if (equalForward == 0 && equalBackward == 0)
			return;

		// merge chunks left [A]B[B] -> [AB]B
		if (equalForward == count2) {
			myRanges.remove(myRanges.length - 1);
			myRanges.remove(myRanges.length - 1);
			myRanges.push(new Range(range1.start1, range1.end1 + count2, range1.start2, range1.end2 + count2));
			processLastRanges();
			return;
		}

		// merge chunks right [A]A[B] -> A[AB]
		if (equalBackward == count1) {
			myRanges.remove(myRanges.length - 1);
			myRanges.remove(myRanges.length - 1);
			myRanges.push(new Range(range2.start1 - count1, range2.end1, range2.start2 - count1, range2.end2));
			processLastRanges();
			return;
		}

		var touchSide:Side = Side.fromLeft(range1.end1 == range2.start1);

		var shift:Int = getShift(touchSide, equalForward, equalBackward, range1, range2);
		if (shift != 0) {
			myRanges.remove(myRanges.length - 1);
			myRanges.remove(myRanges.length - 1);
			myRanges.push(new Range(range1.start1, range1.end1 + shift, range1.start2, range1.end2 + shift));
			myRanges.push(new Range(range2.start1 + shift, range2.end1, range2.start2 + shift, range2.end2));
		}
	}

	// 0 - do nothing
	// >0 - shift forward
	// <0 - shift backward
	abstract private function getShift(touchSide:Side, equalForward:Int, equalBackward:Int, range1:Range, range2:Range):Int;

	//
	// Implementations
	//
	/*
	 * 1. Minimise amount of chunks
	 *      good: "AX[AB]" - "[AB]"
	 *      bad: "[A]XA[B]" - "[A][B]"
	 *
	 * 2. Minimise amount of modified 'sentences', where sentence is a sequence of words, that are not separated by whitespace
	 *      good: "[AX] [AZ]" - "[AX] AY [AZ]"
	 *      bad: "[AX A][Z]" - "[AX A]Y A[Z]"
	 *      ex: "1.0.123 1.0.155" vs "1.0.123 1.0.134 1.0.155"
	 */
}

class WordChunkOptimizer extends ChunkOptimizer<InlineChunk> {
	private final myText1:String;
	private final myText2:String;

	public function new(words1:Array<InlineChunk>, words2:Array<InlineChunk>, text1:String, text2:String, changes:FairDiffIterable) {
		super(words1, words2, changes);
		myText1 = text1;
		myText2 = text2;
	}

	private function getShift(touchSide:Side, equalForward:Int, equalBackward:Int, range1:Range, range2:Range):Int {
		var touchWords:Array<InlineChunk> = touchSide.selectA(myData1, myData2);
		var touchText:String = touchSide.selectA(myText1, myText2);
		var touchStart:Int = touchSide.selectA(range2.start1, range2.start2);

		// check if chunks are already separated by whitespaces
		if (isSeparatedWithWhitespace(touchText, touchWords[touchStart - 1], touchWords.get(touchStart)))
			return 0;

		// shift chunks left [X]A Y[A ZA] -> [XA] YA [ZA]
		//                   [X][A ZA] -> [XA] [ZA]
		var leftShift:Int = findSequenceEdgeShift(touchText, touchWords, touchStart, equalForward, true);
		if (leftShift > 0)
			return leftShift;

		// shift chunks right [AX A]Y A[Z] -> [AX] AY [AZ]
		//                    [AX A][Z] -> [AX] [AZ]
		var rightShift:Int = findSequenceEdgeShift(touchText, touchWords, touchStart - 1, equalBackward, false);
		if (rightShift > 0)
			return -rightShift;

		// nothing to do
		return 0;
	}

	static private function findSequenceEdgeShift(text:String, words:Array<InlineChunk>, offset:Int, count:Int, leftToRight:Bool):Int {
		for (i in 0...count) {
			var word1:InlineChunk;
			var word2:InlineChunk;
			if (leftToRight) {
				word1 = words[offset + i];
				word2 = words[offset + i + 1];
			} else {
				word1 = words[offset - i - 1];
				word2 = words[offset - i];
			}
			if (isSeparatedWithWhitespace(text, word1, word2))
				return i + 1;
		}
		return -1;
	}

	static private function isSeparatedWithWhitespace(text:String, word1:InlineChunk, word2:InlineChunk):Bool {
		if (Std.downcast(word1, NewlineChunk) != null || std.downcast(word2, NewlineChunk) != null) {
			return true;
		}
		var offset1:Int = word1.getOffset2();
		var offset2:Int = word2.getOffset1();
		for (i in offset1...offset2) {
			if (isWhiteSpace(text.charAt(i))) {
				return true;
			}
		}
		return false;
	}
}

/*
 * 1. Minimise amount of chunks
 *      good: "AX[AB]" - "[AB]"
 *      bad: "[A]XA[B]" - "[A][B]"
 *
 * 2. Prefer insertions/deletions, that are bounded by empty(or 'unimportant') line
 *      good: "ABooYZ [ABuuYZ ]ABzzYZ" - "ABooYZ []ABzzYZ"
 *      bad: "ABooYZ AB[uuYZ AB]zzYZ" - "ABooYZ AB[]zzYZ"
 */
class LineChunkOptimizer extends ChunkOptimizer<Line> {
	public function new(lines1:Array<Line>, lines2:Array<Line>, changes:FairDiffIterable) {
		super(lines1, lines2, changes);
	}

	private function getShiftA(touchSide:Side, equalForward:Int, equalBackward:Int, range1:Range, range2:Range):Int {
		var shift:Integer;
		var threshold:Int = ComparisonUtil.getUnimportantLineCharCount();

		shift = getUnchangedBoundaryShift(touchSide, equalForward, equalBackward, range1, range2, 0);
		if (shift != null) {
			return shift;
		}

		shift = getChangedBoundaryShift(touchSide, equalForward, equalBackward, range1, range2, 0);
		if (shift != null) {
			return shift;
		}

		shift = getUnchangedBoundaryShift(touchSide, equalForward, equalBackward, range1, range2, threshold);
		if (shift != null) {
			return shift;
		}

		shift = getChangedBoundaryShift(touchSide, equalForward, equalBackward, range1, range2, threshold);
		if (shift != null) {
			return shift;
		}

		return 0;
	}

	static private function getShiftB(shiftForward:Int, shiftBackward:Int):Int {
		if (shiftForward == -1 && shiftBackward == -1) {
			return null;
		}
		if (shiftForward == 0 || shiftBackward == 0) {
			return 0;
		}

		return shiftForward != -1 ? shiftForward : -shiftBackward;
	}

	/**
	 * search for an empty line boundary in unchanged lines
	 * ie: we want insertion/deletion to go right before/after of an empty line
	 */
	private function getUnchangedBoundaryShift(touchSide:Side, equalForward:Int, equalBackward:Int, range1:Range, range2:Range, threshold:Int):Int {
		var touchLines:Array<Line> = touchSide.selectA(myData1, myData2);
		var touchStart:Int = touchSide.selectA(range2.start1, range2.start2);

		var shiftForward:Int = findNextUnimportantLine(touchLines, touchStart, equalForward + 1, threshold);
		var shiftBackward:Int = findPrevUnimportantLine(touchLines, touchStart - 1, equalBackward + 1, threshold);

		return getShift(shiftForward, shiftBackward);
	}

	/**
	 * search for an empty line boundary in changed lines
	 * ie: we want insertion/deletion to start/end with an empty line
	 */
	private function getChangedBoundaryShift(touchSide:Side, equalForward:Int, equalBackward:Int, range1:Range, range2:Range, threshold:Int):Int {
		var nonTouchSide:Side = touchSide.other();
		var nonTouchLines:Array<Line> = nonTouchSide.select(myData1, myData2);
		var changeStart:Int = nonTouchSide.select(range1.end1, range1.end2);
		var changeEnd:Int = nonTouchSide.select(range2.start1, range2.start2);

		var shiftForward:Int = findNextUnimportantLine(nonTouchLines, changeStart, equalForward + 1, threshold);
		var shiftBackward:Int = findPrevUnimportantLine(nonTouchLines, changeEnd - 1, equalBackward + 1, threshold);

		return getShift(shiftForward, shiftBackward);
	}

	static private function findNextUnimportantLine(lines:Array<Line>, offset:Int, count:Int, threshold:Int):Int {
		for (i in 0...count) {
			if (lines[offset + i].getNonSpaceChars() <= threshold) {
				return i;
			}
		}
		return -1;
	}

	static private function findPrevUnimportantLine(lines:Array<Line>, offset:Int, count:Int, threshold:Int):Int {
		for (i in 0...count) {
			if (lines[offset - i].getNonSpaceChars() <= threshold) {
				return i;
			}
		}
		return -1;
	}
}
