// Copyright 2000-2022 JetBrains s.r.o. and contributors. Use of this source code is governed by the Apache 2.0 license.
package diff.comparison.iterables;

import diff.util.Range;

/**
 * Represents computed differences between two sequences.
 * <p/>
 * All {@link Range} are not empty (have at least one element in one of the sides). Ranges do not overlap.
 * <p/>
 * Differences are guaranteed to be 'squashed': there are no two changed or two unchanged {@link Range} with
 * <code>(range1.end1 == range2.start1 && range1.end2 == range2.start2)</code>.
 *
 * @see FairDiffIterable
 * @see DiffIterableUtil#iterateAll(DiffIterable)
 * @see DiffIterableUtil#verify(DiffIterable)
 */
@:generic
class GenericIterable<T> {
	public var data:Iterator<T>;

	public function new(data:Iterator<T>) {
		this.data = data;
	}

	public function iterator() {
		return this.data;
	}
}

abstract class DiffIterable {
	/**
	 * @return length of the first sequence
	 */
	public abstract function getLength1():Int;

	/**
	 * @return length of the second sequence
	 */
	public abstract function getLength2():Int;

	public abstract function changes():Iterator<Range>;

	public abstract function unchanged():Iterator<Range>;

	public function iterateChanges():Iterable<Range> {
		return new GenericIterable(this.changes());
	}

	public function iterateUnchanged():Iterable<Range> {
		return new GenericIterable(this.unchanged());
	}
}
