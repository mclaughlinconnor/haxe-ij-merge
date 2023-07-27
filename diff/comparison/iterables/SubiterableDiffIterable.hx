// Copyright 2000-2021 JetBrains s.r.o. and contributors. Use of this source code is governed by the Apache 2.0 license.
package diff.comparison.iterables;

import diff.comparison.iterables.ChangeDiffIterableBase.ChangeIterable;
import diff.util.Range;

class SubiterableDiffIterable extends ChangeDiffIterableBase {
	private final myChanged:Array<Range>;
	private final myStart1:Int;
	private final myStart2:Int;
	private final myEnd1:Int;
	private final myEnd2:Int;
	private final myFirstIndex:Int;

	/**
	 * @param firstIndex First range in {@code changed} that might affects our range.
	 *                   This is an optimization to avoid O(changed.size) lookups of the first element for each subIterable.
	 */
	public function new(changed:Array<Range>, start1:Int, end1:Int, start2:Int, end2:Int, firstIndex:Int) {
		super(end1 - start1, end2 - start2);
		myChanged = changed;
		myStart1 = start1;
		myStart2 = start2;
		myEnd1 = end1;
		myEnd2 = end2;
		myFirstIndex = firstIndex;
	}

	private function createChangeIterable():ChangeIterable {
		return new SubiterableChangeIterable(myChanged, myStart1, myEnd1, myStart2, myEnd2, myFirstIndex);
	}
}

class SubiterableChangeIterable implements ChangeIterable {
	private final myChanged:Array<Range>;
	private final myStart1:Int;
	private final myEnd1:Int;
	private final myStart2:Int;
	private final myEnd2:Int;

	private var myIndex:Int;
	private var myLast:Range;

	public function new(changed:Array<Range>, start1:Int, end1:Int, start2:Int, end2:Int, firstIndex:Int) {
		myChanged = changed;
		myStart1 = start1;
		myEnd1 = end1;
		myStart2 = start2;
		myEnd2 = end2;
		myIndex = firstIndex;

		next();
	}

	public function valid():Bool {
		return myLast != null;
	}

	public function next():Void {
		myLast = null;

		while (myIndex < myChanged.length) {
			var range:Range = myChanged[myIndex];
			myIndex++;

			if (range.end1 < myStart1 || range.end2 < myStart2) {
				continue;
			}
			if (range.start1 > myEnd1 || range.start2 > myEnd2) {
				break;
			}

			var newRange:Range = new Range(Std.int(Math.max(myStart1, range.start1))
				- myStart1, Std.int(Math.min(myEnd1, range.end1))
				- myStart1,
				Std.int(Math.max(myStart2, range.start2))
				- myStart2, Std.int(Math.min(myEnd2, range.end2))
				- myStart2);

			if (newRange.isEmpty()) {
				continue;
			}

			myLast = newRange;
			break;
		}
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
