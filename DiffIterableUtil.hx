// Copyright 2000-2022 JetBrains s.r.o. and contributors. Use of this source code is governed by the Apache 2.0 license.
class DiffIterableUtil {
	private static final SHOULD_VERIFY_ITERABLE = false;

	/*
	 * Compare two integer arrays
	 */
	public static function diffA(data1:Array<Int>, data2:Array<Int>):FairDiffIterable {
		try {
			var change:Diff.Change = Diff.buildChanges(data1, data2);
			return DiffIterableUtil.fair(DiffIterableUtil.createA(change, data1.length, data2.length));
		} catch (e:FilesTooBigForDiffException) {
			throw new DiffTooBigException('');
		}
	}

	/*
	 * Compare two arrays, basing on equals() and hashCode() of it's elements
	 */
	@:generic
	public static function diffB<T>(data1:Array<T>, data2:Array<T>):FairDiffIterable {
		try {
			// TODO: use CancellationChecker inside
			var change:Diff.Change = Diff.buildChanges(data1, data2);
			return DiffIterableUtil.fair(DiffIterableUtil.createA(change, data1.length, data2.length));
		} catch (e:FilesTooBigForDiffException) {
			throw new DiffTooBigException('');
		}
	}

	//
	// Iterable
	//

	public static function createA(change:Diff.Change, length1:Int, length2:Int):DiffIterable {
		var iterable:DiffChangeDiffIterable = new DiffChangeDiffIterable(change, length1, length2);
		verify(iterable);
		return iterable;
	}

	public static function createB(ranges:List<Range>, length1:Int, length2:Int):DiffIterable {
		var iterable:DiffIterable = new RangesDiffIterable(ranges, length1, length2);
		verify(iterable);
		return iterable;
	}

	public static function createFragments(fragments:List<DiffFragment>, length1:Int, length2:Int):DiffIterable {
		var iterable:DiffIterable = new DiffFragmentsDiffIterable(fragments, length1, length2);
		verify(iterable);
		return iterable;
	}

	public static function createUnchanged(ranges:List<Range>, length1:Int, length2:Int):DiffIterable {
		var invert:DiffIterable = invert(create(ranges, length1, length2));
		verify(invert);
		return invert;
	}

	public static function invert(iterable:DiffIterable):DiffIterable {
		var wrapper:DiffIterable = new InvertedDiffIterableWrapper(iterable);
		verify(wrapper);
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
	public static function iterateAll(iterable:DiffIterable):Iterable<Pair<Range, /* isUnchanged */ Bool>> {
		// return () -> new Iterator<Pair<Range, Bool>>() {
		//
		//
		//   public Bool hasNext() {
		//     return lastChanged != null || lastUnchanged != null;
		//   }
		//
		//   public Pair<Range, Bool> next() {
		//     Bool equals;
		//     if (lastChanged == null) {
		//       equals = true;
		//     }
		//     else if (lastUnchanged == null) {
		//       equals = false;
		//     }
		//     else {
		//       equals = lastUnchanged.start1 < lastChanged.start1 || lastUnchanged.start2 < lastChanged.start2;
		//     }
		//
		//     if (equals) {
		//       Range range = lastUnchanged;
		//       lastUnchanged = myUnchanged.hasNext() ? myUnchanged.next() : null;
		//       return Pair.create(range, true);
		//     }
		//     else {
		//       Range range = lastChanged;
		//       lastChanged = myChanges.hasNext() ? myChanges.next() : null;
		//       return Pair.create(range, false);
		//     }
		//   }
		//
		//   public Void remove() {
		//     throw new UnsupportedOperationException();
		//   }
		// };
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

		verify(iterable.iterateChanges());
		verify(iterable.iterateUnchanged());

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

		verify(iterable);

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
	public static function extractDataRanges<T>(objects1:List<T>, objects2:List<T>, iterable:DiffIterable):List<LineRangeData<T>> {
		var result:List<LineRangeData<T>> = new List();

		for (pair in iterateAll(iterable)) {
			var range:Range = pair.first;
			var equals:Bool = pair.second;

			var data1:List<T> = new List();
			var data2:List<T> = new List();

			for (i in range.start1...range.end1) {
				data1.add(objects1.get(i));
			}

			for (i in range.start2...range.end2) {
				data2.add(objects2.get(i));
			}

			result.add(new LineRangeData(data1, data2, equals));
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
	private var myFirstChange:Diff.Change;
	private var myLastChange:Diff.Change;

	public function new(length1:Int, length2:Int) {
		super(length1, length2);
	}

	private function addChange(start1:Int, start2:Int, end1:Int, end2:Int):Void {
		var change:Diff.Change = new Diff.Change(start1, start2, end1 - start1, end2 - start2, null);

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
	private final myObjects1:List<Dynamic>;
	private final myObjects2:List<Dynamic>;

	public function new(objects1:List<Dynamic>, objects2:List<Dynamic>) {
		super(objects1.length, objects2.length);
		myObjects1 = objects1;
		myObjects2 = objects2;
	}

	override private function addChange(start1:Int, start2:Int, end1:Int, end2:Int):Void {
		var range:Range = TrimUtil.expand(myObjects1, myObjects2, start1, start2, end1, end2);
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
	public final objects1:List<T>;
	public final objects2:List<T>;

	public function new(objects1:List<T>, objects2:List<T>, equals:Bool) {
		this.equals = equals;
		this.objects1 = objects1;
		this.objects2 = objects2;
	}
}
