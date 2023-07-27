// Copyright 2000-2022 JetBrains s.r.o. and contributors. Use of this source code is governed by the Apache 2.0 license.
package diff.comparison.iterables;

import exceptions.UnsupportedOperationException;
import util.diff.FilesTooBigForDiffException;
import ds.Pair;
import diff.comparison.DiffTooBigException;
import diff.fragments.DiffFragment;
import diff.util.Range;
import util.diff.Diff;

class DiffIterableUtil {
	private static var SHOULD_VERIFY_ITERABLE = false;

	/*
	 * Compare two integer arrays
	 */
	public static function diffA(data1:Array<Int>, data2:Array<Int>):FairDiffIterable {
		var fair:FairDiffIterable;
		try {
			var change:Change = Diff.buildChangesC(data1, data2);
			fair = DiffIterableUtil.fair(DiffIterableUtil.createA(change, data1.length, data2.length));
		} catch (e:FilesTooBigForDiffException) {
			throw new DiffTooBigException('');
		}

		return fair;
	}

	/*
	 * Compare two arrays, basing on equals() and hashCode() of it's elements
	 */
	@:generic
	public static function diffB<T:{}>(data1:Array<T>, data2:Array<T>):FairDiffIterable {
		var fairIter;
		FairDiffIterable;
		try {
			// TODO: use CancellationChecker inside
			var change:Change = Diff.buildChangesB(data1, data2);
			fairIter = DiffIterableUtil.fair(DiffIterableUtil.createA(change, data1.length, data2.length));
		} catch (e:FilesTooBigForDiffException) {
			throw new DiffTooBigException('');
		}

		return fairIter;
	}

	//
	// Iterable
	//

	public static function createA(change:Change, length1:Int, length2:Int):DiffIterable {
		var iterable:DiffChangeDiffIterable = new DiffChangeDiffIterable(change, length1, length2);
		verifyA(iterable);
		return iterable;
	}

	public static function createB(ranges:Array<Range>, length1:Int, length2:Int):DiffIterable {
		var iterable:DiffIterable = new RangesDiffIterable(ranges, length1, length2);
		verifyA(iterable);
		return iterable;
	}

	public static function createFragments(fragments:Array<DiffFragment>, length1:Int, length2:Int):DiffIterable {
		var iterable:DiffIterable = new DiffFragmentsDiffIterable(fragments, length1, length2);
		verifyA(iterable);
		return iterable;
	}

	public static function createUnchanged(ranges:Array<Range>, length1:Int, length2:Int):DiffIterable {
		var invert:DiffIterable = invert(createB(ranges, length1, length2));
		verifyA(invert);
		return invert;
	}

	public static function invert(iterable:DiffIterable):DiffIterable {
		var wrapper:DiffIterable = new InvertedDiffIterableWrapper(iterable);
		verifyA(wrapper);
		return wrapper;
	}

	public static function fair(iterable:DiffIterable):FairDiffIterable {
		if (Std.downcast(iterable, FairDiffIterable) != null) {
			return cast(iterable, FairDiffIterable);
		}
		var wrapper:FairDiffIterable = new FairDiffIterableWrapper(iterable);
		verifyFair(wrapper);
		return wrapper;
	}

	public static function expandedIterable(iterable:DiffIterable, offset1:Int, offset2:Int, length1:Int, length2:Int):DiffIterable {
		// assert offset1 + iterable.getLength1() <= length1 &&
		// offset2 + iterable.getLength2() <= length2;
		return new ExpandedDiffIterable(iterable, offset1, offset2, length1, length2);
	}

	//
	// Misc
	//

	/**
	 * Iterate both changed and unchanged ranges one-by-one.
	 */
	public static function iterateAll(iterable:DiffIterable):Iterator<Pair<Range, /* isUnchanged */ Bool>> {
		return new IterateAllIterator(iterable);
	}

	public static function getRangeDelta(range:Range):Int {
		var deleted:Int = range.end1 - range.start1;
		var inserted:Int = range.end2 - range.start2;
		return inserted - deleted;
	}

	//
	// Verification
	//

	public static function setVerifyEnabled(value:Bool):Void {
		SHOULD_VERIFY_ITERABLE = value;
	}

	private static function isVerifyEnabled() {
		return SHOULD_VERIFY_ITERABLE;
	}

	public static function verifyA(iterable:DiffIterable):Void {
		if (!isVerifyEnabled())
			return;

		verifyB(iterable.iterateChanges());
		verifyB(iterable.iterateUnchanged());

		verifyFullCover(iterable);
	}

	private static function verifyB(iterable:Iterable<Range>):Void {
		for (range in iterable) {
			// verify range
			// assert range.start1 <= range.end1;
			// assert range.start2 <= range.end2;
			// assert range.start1 != range.end1 || range.start2 != range.end2;
		}
	}

	public static function verifyFair(iterable:DiffIterable):Void {
		if (!isVerifyEnabled())
			return;

		verifyA(iterable);

		for (range in iterable.iterateUnchanged()) {
			// assert range.end1 - range.start1 == range.end2 - range.start2;
		}
	}

	private static function verifyFullCover(iterable:DiffIterable):Void {
		var last1:Int = 0;
		var last2:Int = 0;
		var lastEquals:Bool = null;

		for (pair in iterateAll(iterable)) {
			var range:Range = pair.first;
			var equal:Bool = pair.second;

			// assert last1 == range.start1;
			// assert last2 == range.start2;
			// assert! Comparing.equal(lastEquals, equal);

			last1 = range.end1;
			last2 = range.end2;
			lastEquals = equal;
		}

		// assert last1 == iterable.getLength1();
		// assert last2 == iterable.getLength2();
	}

	//
	// Debug
	//

	@:generic
	public static function extractDataRanges<T>(objects1:Array<T>, objects2:Array<T>, iterable:DiffIterable):Array<LineRangeData<T>> {
		var result:Array<LineRangeData<T>> = new Array();

		for (pair in iterateAll(iterable)) {
			var range:Range = pair.first;
			var equals:Bool = pair.second;

			var data1:Array<T> = new Array();
			var data2:Array<T> = new Array();

			for (i in range.start1...range.end1) {
				data1.push(objects1[i]);
			}

			for (i in range.start2...range.end2) {
				data2.push(objects2[i]);
			}

			result.push(new LineRangeData(data1, data2, equals));
		}

		return result;
	}
}

abstract class ChangeBuilderBase {
	private final myLength1:Int;
	private final myLength2:Int;

	private var myIndex1:Int = 0;
	private var myIndex2:Int = 0;

	public function new(length1:Int, length2:Int) {
		myLength1 = length1;
		myLength2 = length2;
	}

	public function getIndex1():Int {
		return myIndex1;
	}

	public function getIndex2():Int {
		return myIndex2;
	}

	public function getLength1():Int {
		return myLength1;
	}

	public function getLength2():Int {
		return myLength2;
	}

	public function markEqualA(index1:Int, index2:Int):Void {
		markEqualB(index1, index2, 1);
	}

	public function markEqualB(index1:Int, index2:Int, count:Int):Void {
		markEqualC(index1, index2, index1 + count, index2 + count);
	}

	public function markEqualC(index1:Int, index2:Int, end1:Int, end2:Int):Void {
		if (index1 == end1 && index2 == end2) {
			return;
		}

		// assert myIndex1 <= index1;
		// assert myIndex2 <= index2;
		// assert index1 <= end1;
		// assert index2 <= end2;

		if (myIndex1 != index1 || myIndex2 != index2) {
			addChange(myIndex1, myIndex2, index1, index2);
		}

		myIndex1 = end1;
		myIndex2 = end2;
	}

	private function doFinish():Void {
		// assert myIndex1 <= myLength1;
		// assert myIndex2 <= myLength2;

		if (myLength1 != myIndex1 || myLength2 != myIndex2) {
			addChange(myIndex1, myIndex2, myLength1, myLength2);
			myIndex1 = myLength1;
			myIndex2 = myLength2;
		}
	}

	private abstract function addChange(start1:Int, start2:Int, end1:Int, end2:Int):Void;
}

class ChangeBuilder extends ChangeBuilderBase {
	private var myFirstChange:Change;
	private var myLastChange:Change;

	public function new(length1:Int, length2:Int) {
		super(length1, length2);
	}

	private function addChange(start1:Int, start2:Int, end1:Int, end2:Int):Void {
		var change:Change = new Change(start1, start2, end1 - start1, end2 - start2, null);

		if (myLastChange != null) {
			myLastChange.link = change;
		} else {
			myFirstChange = change;
		}
		myLastChange = change;
	}

	public function finish():DiffIterable {
		doFinish();
		return DiffIterableUtil.createA(myFirstChange, getLength1(), getLength2());
	}
}

class ExpandChangeBuilder extends ChangeBuilder {
	private final myObjects1:Array<Dynamic>;
	private final myObjects2:Array<Dynamic>;

	public function new(objects1:Array<Dynamic>, objects2:Array<Dynamic>) {
		super(objects1.length, objects2.length);
		myObjects1 = objects1;
		myObjects2 = objects2;
	}

	override private function addChange(start1:Int, start2:Int, end1:Int, end2:Int):Void {
		var range:Range = TrimUtil.expandA(myObjects1, myObjects2, start1, start2, end1, end2);
		if (!range.isEmpty()) {
			super.addChange(range.start1, range.start2, range.end1, range.end2);
		}
	}
} //

// Debug
//

@:generic
class LineRangeData<T> {
	public final equals:Bool;
	public final objects1:Array<T>;
	public final objects2:Array<T>;

	public function new(objects1:Array<T>, objects2:Array<T>, equals:Bool) {
		this.equals = equals;
		this.objects1 = objects1;
		this.objects2 = objects2;
	}
}

class IterateAllIterator {
	private final myChanges:Iterator<Range>;
	private final myUnchanged:Iterator<Range>;

	private var lastChanged:Null<Range>;
	private var lastUnchanged:Null<Range>;

	public function new(iterable:DiffIterable) {
		this.myChanges = iterable.changes();
		this.myUnchanged = iterable.unchanged();

		this.lastChanged = myChanges.hasNext() ? myChanges.next() : null;
		this.lastUnchanged = myUnchanged.hasNext() ? myUnchanged.next() : null;
	}

	public function hasNext():Bool {
		return lastChanged != null || lastUnchanged != null;
	}

	public function next():Pair<Range, Bool> {
		var equals:Bool;
		if (lastChanged == null) {
			equals = true;
		} else if (lastUnchanged == null) {
			equals = false;
		} else {
			equals = lastUnchanged.start1 < lastChanged.start1 || lastUnchanged.start2 < lastChanged.start2;
		}

		if (equals) {
			var range:Range = lastUnchanged;
			lastUnchanged = myUnchanged.hasNext() ? myUnchanged.next() : null;
			return Pair.create(range, true);
		} else {
			var range:Range = lastChanged;
			lastChanged = myChanges.hasNext() ? myChanges.next() : null;
			return Pair.create(range, false);
		}
	}

	public function remove():Void {
		throw new UnsupportedOperationException('');
	};
}
