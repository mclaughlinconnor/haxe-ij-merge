// Copyright 2000-2021 JetBrains s.r.o. and contributors. Use of this source code is governed by the Apache 2.0 license.
package diff.comparison.iterables;

import diff.comparison.iterables.ChangeDiffIterableBase.ChangeIterable;
import diff.util.Range;

class RangesDiffIterable extends ChangeDiffIterableBase {
	private final myRanges:Array<Range>;

	public function new(ranges:Array<Range>, length1:Int, length2:Int) {
		super(length1, length2);
		myRanges = ranges;
	}

	private function createChangeIterable():ChangeIterable {
		return new RangesChangeIterable(myRanges);
	}
}

class RangesChangeIterable implements ChangeIterable {
	private final myIterator:Iterator<Range>;
	private var myLast:Range;

	private function new(ranges:Array<Range>) {
		myIterator = ranges.iterator();

		next();
	}

	public function valid():Bool {
		return myLast != null;
	}

	public function next():Void {
		myLast = myIterator.hasNext() ? myIterator.next() : null;
	}

	public function getStart1():Int {
		return myLast.start1;
	}

	public function getStart2():Int {
		return myLast.start2;
	}

	public function getEnd1():Int {
		return myLast.end1;
	}

	public function getEnd2():Int {
		return myLast.end2;
	}
}
