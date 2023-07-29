// Copyright 2000-2021 JetBrains s.r.o. and contributors. Use of this source code is governed by the Apache 2.0 license.
package diff.comparison.iterables;

import diff.comparison.iterables.ChangeDiffIterableBase.ChangeIterable;
import util.diff.Diff.Change;

class DiffChangeDiffIterable extends ChangeDiffIterableBase {
	private final myChange:Change;

	public function new(change:Null<Change>, length1:Int, length2:Int) {
		super(length1, length2);
		myChange = change;
	}

	private function createChangeIterable():ChangeIterable {
		return new DiffChangeChangeIterable(myChange);
	}
}

class DiffChangeChangeIterable implements ChangeIterable {
	private var myChange:Change;

	public function new(change:Null<Change>) {
		myChange = change;
	}

	public function valid():Bool {
		return myChange != null;
	}

	public function next():Void {
		myChange = myChange.link;
	}

	public function getStart1():Int {
		return myChange.line0;
	}

	public function getStart2():Int {
		return myChange.line1;
	}

	public function getEnd1():Int {
		return myChange.line0 + myChange.deleted;
	}

	public function getEnd2():Int {
		return myChange.line1 + myChange.inserted;
	}
}
