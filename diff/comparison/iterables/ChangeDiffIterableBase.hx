// Copyright 2000-2021 JetBrains s.r.o. and contributors. Use of this source code is governed by the Apache 2.0 license.
package diff.comparison.iterables;

import diff.util.Range;

interface ChangeIterable {
	public function valid():Bool;

	public function next():Void;

	public function getStart1():Int;

	public function getStart2():Int;

	public function getEnd1():Int;

	public function getEnd2():Int;
}

abstract class ChangeDiffIterableBase extends DiffIterable {
	private final myLength1:Int;
	private final myLength2:Int;

	public function new(length1:Int, length2:Int) {
		myLength1 = length1;
		myLength2 = length2;
	}

	public override function getLength1():Int {
		return myLength1;
	}

	public override function getLength2():Int {
		return myLength2;
	}

	public override function changes():Iterator<Range> {
		return new ChangedIterator(createChangeIterable());
	}

	public override function unchanged():Iterator<Range> {
		return new UnchangedIterator(createChangeIterable(), myLength1, myLength2);
	}

	abstract function createChangeIterable():ChangeIterable;
}

class ChangedIterator {
	private final myIterable:ChangeIterable;

	private function new(iterable:ChangeIterable) {
		myIterable = iterable;
	}

	public function hasNext():Bool {
		return myIterable.valid();
	}

	public function next():Range {
		var range:Range = new Range(myIterable.getStart1(), myIterable.getEnd1(), myIterable.getStart2(), myIterable.getEnd2());
		myIterable.next();
		return range;
	}
}

class UnchangedIterator {
	private final myIterable:ChangeIterable;
	private final myLength1:Int;
	private final myLength2:Int;

	private var lastIndex1:Int = 0;
	private var lastIndex2:Int = 0;

	private function new(iterable:ChangeIterable, length1:Int, length2:Int) {
		myIterable = iterable;
		myLength1 = length1;
		myLength2 = length2;

		if (myIterable.valid()) {
			if (myIterable.getStart1() == 0 && myIterable.getStart2() == 0) {
				lastIndex1 = myIterable.getEnd1();
				lastIndex2 = myIterable.getEnd2();
				myIterable.next();
			}
		}
	}

	public function hasNext():Bool {
		return myIterable.valid() || (lastIndex1 != myLength1 || lastIndex2 != myLength2);
	}

	public function next():Range {
		if (myIterable.valid()) {
			// assert(myIterable.getStart1() - lastIndex1 != 0) || (myIterable.getStart2() - lastIndex2 != 0);
			var chunk:Range = new Range(lastIndex1, myIterable.getStart1(), lastIndex2, myIterable.getStart2());

			lastIndex1 = myIterable.getEnd1();
			lastIndex2 = myIterable.getEnd2();

			myIterable.next();

			return chunk;
		} else {
			// assert(myLength1 - lastIndex1 != 0) || (myLength2 - lastIndex2 != 0);
			var chunk:Range = new Range(lastIndex1, myLength1, lastIndex2, myLength2);

			lastIndex1 = myLength1;
			lastIndex2 = myLength2;

			return chunk;
		}
	}
}
