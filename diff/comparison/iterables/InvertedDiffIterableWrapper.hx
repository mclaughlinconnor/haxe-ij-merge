// Copyright 2000-2021 JetBrains s.r.o. and contributors. Use of this source code is governed by the Apache 2.0 license.
package diff.comparison.iterables;

import diff.util.Range;

class InvertedDiffIterableWrapper extends DiffIterable {
	private final myIterable:DiffIterable;

	public function new(iterable:DiffIterable) {
		myIterable = iterable;
	}

	public function getLength1():Int {
		return myIterable.getLength1();
	}

	public function getLength2():Int {
		return myIterable.getLength2();
	}

	public function changes():Iterator<Range> {
		return myIterable.unchanged();
	}

	public function unchanged():Iterator<Range> {
		return myIterable.changes();
	}
}
