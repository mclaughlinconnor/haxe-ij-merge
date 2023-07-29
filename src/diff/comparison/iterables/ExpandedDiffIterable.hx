// Copyright 2000-2021 JetBrains s.r.o. and contributors. Use of this source code is governed by the Apache 2.0 license.
package diff.comparison.iterables;

import diff.comparison.iterables.ChangeDiffIterableBase.ChangeIterable;
import diff.util.Range;

class ExpandedDiffIterable extends ChangeDiffIterableBase {
	private final myIterable:DiffIterable;
	private final myOffset1:Int;
	private final myOffset2:Int;

	public function new(iterable:DiffIterable, offset1:Int, offset2:Int, length1:Int, length2:Int) {
		super(length1, length2);
		myIterable = iterable;
		myOffset1 = offset1;
		myOffset2 = offset2;
	}

	private function createChangeIterable():ChangeIterable {
		return new ShiftedChangeIterable(myIterable, myOffset1, myOffset2);
	}
}

class ShiftedChangeIterable implements ChangeIterable {
	private final myIterator:Iterator<Range>;
	private final myOffset1:Int;
	private final myOffset2:Int;

	private var myLast:Range;

	public function new(iterable:DiffIterable, offset1:Int, offset2:Int) {
		myIterator = iterable.changes();
		myOffset1 = offset1;
		myOffset2 = offset2;

		next();
	}

	public function valid():Bool {
		return myLast != null;
	}

	public function next():Void {
		myLast = myIterator.hasNext() ? myIterator.next() : null;
	}

	public function getStart1():Int {
		return myLast.start1 + myOffset1;
	}

	public function getStart2():Int {
		return myLast.start2 + myOffset2;
	}

	public function getEnd1():Int {
		return myLast.end1 + myOffset1;
	}

	public function getEnd2():Int {
		return myLast.end2 + myOffset2;
	}
}
