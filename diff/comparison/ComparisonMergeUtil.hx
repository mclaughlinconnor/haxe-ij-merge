// Copyright 2000-2021 JetBrains s.r.o. and contributors. Use of this source code is governed by the Apache 2.0 license.
package diff.comparison;

import diff.util.Range;
import diff.util.MergeRange;
import diff.comparison.iterables.FairDiffIterable;
import diff.util.Side;
import config.DiffConfig;
import diff.util.Side.SideEnum;
import iterators.PeakableIteratorWrapper.PeekableIteratorWrapper;

interface SideEquality {
	function equals(leftIndex:Int, baseIndex:Int, rightIndex:Int):Bool;
}

class ComparisonMergeUtil {
	public static function buildSimple(fragments1:FairDiffIterable, fragments2:FairDiffIterable):Array<MergeRange> {
		// assert fragments1.getLength1() == fragments2.getLength1();
		return new FairMergeBuilder().execute(fragments1, fragments2);
	}

	public static function buildMerge(fragments1:FairDiffIterable, fragments2:FairDiffIterable, trueEquality:SideEquality):Array<MergeRange> {
		// assert fragments1.getLength1() == fragments2.getLength1();
		return new FairMergeBuilder(trueEquality).execute(fragments1, fragments2);
	}

	public static function tryResolveConflict(leftText:String, baseText:String, rightText:String):String {
		if (DiffConfig.USE_GREEDY_MERGE_MAGIC_RESOLVE) {
			return MergeResolveUtil.tryGreedyResolve(leftText, baseText, rightText);
		} else {
			return MergeResolveUtil.tryResolve(leftText, baseText, rightText);
		}
	}
}

class FairMergeBuilder {
	private final myChangesBuilder:ChangeBuilder;

	public function new(?trueEquality:SideEquality) {
		if (trueEquality != null) {
			myChangesBuilder = new IgnoringChangeBuilder(trueEquality);
			return;
		}
		myChangesBuilder = new ChangeBuilder();
	}

	public function execute(fragments1:FairDiffIterable, fragments2:FairDiffIterable):Array<MergeRange> {
		var unchanged1:PeekableIteratorWrapper<Range> = new PeekableIteratorWrapper(fragments1.iterateUnchanged());
		var unchanged2:PeekableIteratorWrapper<Range> = new PeekableIteratorWrapper(fragments2.iterateUnchanged());

		while (unchanged1.hasNext() && unchanged2.hasNext()) {
			var sideEnum:SideEnum = add(unchanged1.peek(), unchanged2.peek());
			var side:Side = new Side(0);
			side.selectA(unchanged1, unchanged2).next();
		}

		return myChangesBuilder.finish(fragments1.getLength2(), fragments1.getLength1(), fragments2.getLength2());
	}

	private function add(range1:Range, range2:Range):SideEnum {
		var start1:Int = range1.start1;
		var end1:Int = range1.end1;

		var start2:Int = range2.start1;
		var end2:Int = range2.end1;

		if (end1 <= start2) {
			return SideEnum.LEFT;
		}
		if (end2 <= start1) {
			return SideEnum.RIGHT;
		}

		var startBase:Int = Std.int(Math.max(start1, start2));
		var endBase:Int = Std.int(Math.min(end1, end2));
		var count:Int = endBase - startBase;

		var startShift1:Int = startBase - start1;
		var startShift2:Int = startBase - start2;

		var startLeft:Int = range1.start2 + startShift1;
		var endLeft:Int = startLeft + count;
		var startRight:Int = range2.start2 + startShift2;
		var endRight:Int = startRight + count;

		myChangesBuilder.markEqual(startLeft, startBase, startRight, endLeft, endBase, endRight);

		return Side.fromLeft(end1 <= end2);
	}
}

class ChangeBuilder {
	final myChanges:Array<MergeRange> = new Array();

	private var myIndex1:Int = 0;
	private var myIndex2:Int = 0;
	private var myIndex3:Int = 0;

	public function new() {}

	private function addChange(start1:Int, start2:Int, start3:Int, end1:Int, end2:Int, end3:Int):Void {
		if (start1 == end1 && start2 == end2 && start3 == end3) {
			return;
		}
		myChanges.push(new MergeRange(start1, end1, start2, end2, start3, end3));
	}

	public function markEqual(start1:Int, start2:Int, start3:Int, end1:Int, end2:Int, end3:Int):Void {
		// assert myIndex1 <= start1;
		// assert myIndex2 <= start2;
		// assert myIndex3 <= start3;
		// assert start1 <= end1;
		// assert start2 <= end2;
		// assert start3 <= end3;

		processChange(myIndex1, myIndex2, myIndex3, start1, start2, start3);

		myIndex1 = end1;
		myIndex2 = end2;
		myIndex3 = end3;
	}

	public function finish(length1:Int, length2:Int, length3:Int):Array<MergeRange> {
		// assert myIndex1 <= length1;
		// assert myIndex2 <= length2;
		// assert myIndex3 <= length3;

		processChange(myIndex1, myIndex2, myIndex3, length1, length2, length3);

		return myChanges;
	}

	private function processChange(start1:Int, start2:Int, start3:Int, end1:Int, end2:Int, end3:Int):Void {
		addChange(start1, start2, start3, end1, end2, end3);
	}
}

class IgnoringChangeBuilder extends ChangeBuilder {
	private var myTrueEquality:SideEquality;

	public function new(trueEquality:SideEquality) {
		super();
		myTrueEquality = trueEquality;
	}

	private function processChange(start1:Int, start2:Int, start3:Int, end1:Int, end2:Int, end3:Int):Void {
		var lastChange:MergeRange = myChanges.isEmpty() ? null : myChanges.get(myChanges.length - 1);
		var unchangedStart1:Int = lastChange != null ? lastChange.end1 : 0;
		var unchangedStart2:Int = lastChange != null ? lastChange.end2 : 0;
		var unchangedStart3:Int = lastChange != null ? lastChange.end3 : 0;

		addIgnoredChanges(unchangedStart1, unchangedStart2, unchangedStart3, start1, start2, start3);
		addChange(start1, start2, start3, end1, end2, end3);
	}

	private function addIgnoredChanges(start1:Int, start2:Int, start3:Int, end1:Int, end2:Int, end3:Int):Void {
		var count:Int = end2 - start2;
		// assert end1 - start1 == count;
		// assert end3 - start3 == count;

		var firstIgnoredCount:Int = -1;
		for (i in 0..count) {
			var isIgnored:Bool = !myTrueEquality.equals(start1 + i, start2 + i, start3 + i);
			var previousAreIgnored:Bool = firstIgnoredCount != -1;

			if (isIgnored && !previousAreIgnored) {
				firstIgnoredCount = i;
			}
			if (!isIgnored && previousAreIgnored) {
				addChange(start1 + firstIgnoredCount, start2 + firstIgnoredCount, start3 + firstIgnoredCount, start1 + i, start2 + i, start3 + i);
				firstIgnoredCount = -1;
			}
		}

		if (firstIgnoredCount != -1) {
			addChange(start1
				+ firstIgnoredCount, start2
				+ firstIgnoredCount, start3
				+ firstIgnoredCount, start1
				+ count, start2
				+ count, start3
				+ count);
		}
	}
}
