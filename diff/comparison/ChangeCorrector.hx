// Copyright 2000-2021 JetBrains s.r.o. and contributors. Use of this source code is governed by the Apache 2.0 license.
package diff.comparison;

import diff.comparison.iterables.DiffIterableUtil.ChangeBuilder;
import ds.Pair;
import diff.comparison.ByLineRt.Line;
import diff.comparison.iterables.FairDiffIterable;
import diff.util.Range;
import diff.comparison.TrimUtil.expandA;
import diff.comparison.iterables.DiffIterableUtil.diffB;
import diff.comparison.iterables.DiffIterableUtil.fair;

/*
 * Base class for two-step diff algorithms.
 * Given matching between some sub-sequences of base sequences - build matching on whole base sequences
 */
abstract class ChangeCorrector {
	private final myLength1:Int;
	private final myLength2:Int;

	private final myChanges:FairDiffIterable;

	private final myBuilder:ChangeBuilder;

	public function new(length1:Int, length2:Int, changes:FairDiffIterable) {
		myLength1 = length1;
		myLength2 = length2;
		myChanges = changes;

		myBuilder = new ChangeBuilder(length1, length2);
	}

	public function build():FairDiffIterable {
		execute();
		return fair(myBuilder.finish());
	}

	private function execute():Void {
		var last1:Int = 0;
		var last2:Int = 0;

		for (ch in myChanges.iterateUnchanged()) {
			var count:Int = ch.end1 - ch.start1;
			for (i in 0...count) {
				var range1:Pair<Int, Int> = getOriginalRange1(ch.start1 + i);
				var range2:Pair<Int, Int> = getOriginalRange2(ch.start2 + i);

				var start1:Int = range1.first;
				var start2:Int = range2.first;
				var end1:Int = range1.second;
				var end2:Int = range2.second;

				matchGap(last1, start1, last2, start2);
				myBuilder.markEqualC(start1, start2, end1, end2);

				last1 = end1;
				last2 = end2;
			}
		}
		matchGap(last1, myLength1, last2, myLength2);
	}

	// match elements in range [start1 - end1) -> [start2 - end2)
	abstract private function matchGap(start1:Int, end1:Int, start2:Int, end2:Int):Void;

	abstract private function getOriginalRange1(index:Int):Pair<Int, Int>;

	abstract private function getOriginalRange2(index:Int):Pair<Int, Int>;

	//
	// Implementations
	//
}

class DefaultCharChangeCorrector extends ChangeCorrector {
	private final myCodePoints1:ByCharRt.CodePointsOffsets;
	private final myCodePoints2:ByCharRt.CodePointsOffsets;
	private final myText1:String;
	private final myText2:String;

	public function new(codePoints1:ByCharRt.CodePointsOffsets, codePoints2:ByCharRt.CodePointsOffsets, text1:String, text2:String, changes:FairDiffIterable) {
		super(text1.length, text2.length, changes);
		myCodePoints1 = codePoints1;
		myCodePoints2 = codePoints2;
		myText1 = text1;
		myText2 = text2;
	}

	private function matchGap(start1:Int, end1:Int, start2:Int, end2:Int):Void {
		var inner1:String = myText1.substring(start1, end1);
		var inner2:String = myText2.substring(start2, end2);
		var innerChanges:FairDiffIterable = ByCharRt.compare(inner1, inner2);

		for (chunk in innerChanges.iterateUnchanged()) {
			myBuilder.markEqualB(start1 + chunk.start1, start2 + chunk.start2, chunk.end1 - chunk.start1);
		}
	}

	private function getOriginalRange1(index:Int):Pair<Int, Int> {
		var startOffset:Int = myCodePoints1.charOffset(index);
		var endOffset:Int = myCodePoints1.charOffsetAfter(index);
		return new Pair<Int, Int>(startOffset, endOffset);
	}

	private function getOriginalRange2(index:Int):Pair<Int, Int> {
		var startOffset:Int = myCodePoints2.charOffset(index);
		var endOffset:Int = myCodePoints2.charOffsetAfter(index);
		return new Pair<Int, Int>(startOffset, endOffset);
	}
}

class SmartLineChangeCorrector extends ChangeCorrector {
	private final myIndexes1:Array<Int>;
	private final myIndexes2:Array<Int>;
	private final myLines1:Array<Line>;
	private final myLines2:Array<Line>;

	public function new(indexes1:Array<Int>, indexes2:Array<Int>, lines1:Array<Line>, lines2:Array<Line>, changes:FairDiffIterable) {
		super(lines1.length, lines2.length, changes);
		myIndexes1 = indexes1;
		myIndexes2 = indexes2;
		myLines1 = lines1;
		myLines2 = lines2;
	}

	private function matchGap(start1:Int, end1:Int, start2:Int, end2:Int):Void {
		var expand:Range = expandA(myLines1, myLines2, start1, start2, end1, end2);

		var inner1:Array<Line> = myLines1.slice(expand.start1, expand.end1);
		var inner2:Array<Line> = myLines2.slice(expand.start2, expand.end2);
		var innerChanges:FairDiffIterable = diffB(inner1, inner2);

		myBuilder.markEqualC(start1, start2, expand.start1, expand.start2);

		for (chunk in innerChanges.iterateUnchanged()) {
			myBuilder.markEqualB(expand.start1 + chunk.start1, expand.start2 + chunk.start2, chunk.end1 - chunk.start1);
		}

		myBuilder.markEqualC(expand.end1, expand.end2, end1, end2);
	}

	private function getOriginalRange1(index:Int):Pair<Int, Int> {
		var offset:Int = myIndexes1[index];
		return new Pair<Int, Int>(offset, offset + 1);
	}

	private function getOriginalRange2(index:Int):Pair<Int, Int> {
		var offset:Int = myIndexes2[index];
		return new Pair<Int, Int>(offset, offset + 1);
	}
}
