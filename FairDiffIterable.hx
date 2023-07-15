// TODO: this is mostly all wrong I think

// Copyright 2000-2022 JetBrains s.r.o. and contributors. Use of this source code is governed by the Apache 2.0 license.

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
abstract class DiffIterable {
	/**
	 * @return length of the first sequence
	 */
	abstract public function getLength1():Int;

	/**
	 * @return length of the second sequence
	 */
	abstract public function getLength2():Int;

	abstract public function changes():Iterable<Range>;

	abstract public function unchanged():Iterable<Range>;

	public function iterateChanges():Iterable<Range> {
		return this.changes();
	}

	public function iterateUnchanged():Iterable<Range> {
		return this.unchanged();
	}
}

/**
 * Marker interface indicating that elements are compared one-by-one.
 * <p>
 * If range [a, b) is equal to [a', b'), than element(a + i) is equal to element(a' + i) for all i in [0, b-a)
 * Therefore, {@link #unchanged} ranges are guaranteed to have {@link DiffIterableUtil#getRangeDelta(Range)} equal to 0.
 *
 * @see DiffIterableUtil#fair(DiffIterable)
 * @see DiffIterableUtil#verifyFair(DiffIterable)
 */
class FairDiffIterable {
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

	public function changes():Iterable<Range> {
		return myIterable.changes();
	}

	public function unchanged():Iterable<Range> {
		return myIterable.unchanged();
	}
}
