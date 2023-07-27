// Copyright 2000-2021 JetBrains s.r.o. and contributors. Use of this source code is governed by the Apache 2.0 license.
package diff.comparison.iterables;

import diff.comparison.iterables.ChangeDiffIterableBase.ChangeIterable;
import diff.fragments.DiffFragment;

class DiffFragmentsDiffIterable extends ChangeDiffIterableBase {
	private final myFragments:Array<DiffFragment>;

	public function new(ranges:Array<DiffFragment>, length1:Int, length2:Int) {
		super(length1, length2);
		myFragments = ranges;
	}

	private function createChangeIterable():ChangeIterable {
		return new FragmentsChangeIterable(myFragments);
	}
}

class FragmentsChangeIterable implements ChangeIterable {
	private final myIterator:Iterator<DiffFragment>;
	private var myLast:DiffFragment;

	public function new(fragments:Array<DiffFragment>) {
		myIterator = fragments.iterator();

		next();
	}

	public function valid():Bool {
		return myLast != null;
	}

	public function next():Void {
		myLast = myIterator.hasNext() ? myIterator.next() : null;
	}

	public function getStart1():Int {
		return myLast.getStartOffset1();
	}

	public function getStart2():Int {
		return myLast.getStartOffset2();
	}

	public function getEnd1():Int {
		return myLast.getEndOffset1();
	}

	public function getEnd2():Int {
		return myLast.getEndOffset2();
	}
}
