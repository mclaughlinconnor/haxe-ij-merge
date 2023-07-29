// Copyright 2000-2021 JetBrains s.r.o. and contributors. Use of this source code is governed by the Apache 2.0 license.
package util.diff;

using util.SafeBitSetAt;

import thx.BitSet;
import util.diff.UniqueLCS.binarySearchImpl;

class Reindexer {
	private final myOldIndices:Array<Array<Int>> = [for (_ in 0...2) new Array()];

	private final myOriginalLengths:Array<Int> = [-1, -1];
	private final myDiscardedLengths:Array<Int> = [-1, -1];

	public function new() {}

	public function discardUnique(Ints1:Array<Int>, Ints2:Array<Int>):Array<Array<Int>> {
		var discarded1:Array<Int> = discard(Ints2, Ints1, 0);
		return [discarded1, discard(discarded1, Ints2, 1)];
	}

	private function discard(needed:Array<Int>, toDiscard:Array<Int>, arrayIndex:Int):Array<Int> {
		myOriginalLengths[arrayIndex] = toDiscard.length;
		var sorted1:Array<Int> = createSorted(needed);
		var discarded:Array<Int> = [];
		var oldIndices:Array<Int> = [];
		for (i in 0...toDiscard.length) {
			var index:Int = toDiscard[i];
			if (binarySearch(sorted1, index) >= 0) {
				discarded.push(index);
				oldIndices.push(i);
			}
		}
		myOldIndices[arrayIndex] = oldIndices;
		myDiscardedLengths[arrayIndex] = discarded.length;
		return discarded;
	}

	private static function createSorted(Ints1:Array<Int>):Array<Int> {
		var sorted1:Array<Int> = Ints1.copy();
		sorted1.sort((a, b) -> a - b);
		return sorted1;
	}

	public function reindex(discardedChanges:Array<BitSet>, builder:LCSBuilder):Void {
		var changes1:BitSet;
		var changes2:BitSet;

		if (myDiscardedLengths[0] == myOriginalLengths[0] && myDiscardedLengths[1] == myOriginalLengths[1]) {
			changes1 = discardedChanges[0];
			changes2 = discardedChanges[1];
		} else {
			changes1 = new BitSet(myOriginalLengths[0]);
			changes2 = new BitSet(myOriginalLengths[1]);
			var x:Int = 0;
			var y:Int = 0;
			while (x < myDiscardedLengths[0] || y < myDiscardedLengths[1]) {
				if ((x < myDiscardedLengths[0] && y < myDiscardedLengths[1])
					&& !discardedChanges[0].safeAt(x)
					&& !discardedChanges[1].safeAt(y)) {

					x = increment(myOldIndices[0], x, changes1, myOriginalLengths[0]);
					y = increment(myOldIndices[1], y, changes2, myOriginalLengths[1]);
				} else if (discardedChanges[0].safeAt(x)) {
					bitSetSetBetween(changes1, getOriginal(myOldIndices[0], x));
					x = increment(myOldIndices[0], x, changes1, myOriginalLengths[0]);
				} else if (discardedChanges[1].safeAt(y)) {
					bitSetSetBetween(changes2, getOriginal(myOldIndices[1], y));
					y = increment(myOldIndices[1], y, changes2, myOriginalLengths[1]);
				}
			}
			if (myDiscardedLengths[0] == 0) {
				bitSetSetBetween(changes1, 0, myOriginalLengths[0]);
			} else {
				bitSetSetBetween(changes1, 0, myOldIndices[0][0]);
			}
			if (myDiscardedLengths[1] == 0) {
				bitSetSetBetween(changes2, 0, myOriginalLengths[1]);
			} else {
				bitSetSetBetween(changes2, 0, myOldIndices[1][0]);
			}
		}

		var x:Int = 0;
		var y:Int = 0;
		while (x < myOriginalLengths[0] && y < myOriginalLengths[1]) {
			var startX:Int = x;
			while (x < myOriginalLengths[0] && y < myOriginalLengths[1] && !changes1.at(x) && !changes2.at(y)) {
				x++;
				y++;
			}
			if (x > startX)
				builder.addEqual(x - startX);
			var dx:Int = 0;
			var dy:Int = 0;
			while (x < myOriginalLengths[0] && changes1.at(x)) {
				dx++;
				x++;
			}
			while (y < myOriginalLengths[1] && changes2.at(y)) {
				dy++;
				y++;
			}
			if (dx != 0 || dy != 0) {
				builder.addChange(dx, dy);
			}
		}
		if (x != myOriginalLengths[0] || y != myOriginalLengths[1])
			builder.addChange(myOriginalLengths[0] - x, myOriginalLengths[1] - y);
	}

	private static function getOriginal(indexes:Array<Int>, i:Int):Int {
		return indexes[i];
	}

	private static function increment(indexes:Array<Int>, i:Int, set:BitSet, length:Int):Int {
		if (i + 1 < indexes.length) {
			bitSetSetBetween(set, indexes[i] + 1, indexes[i + 1]);
		} else {
			bitSetSetBetween(set, indexes[i] + 1, length);
		}
		return i + 1;
	}
}

function binarySearch(sequence:Array<Int>, val:Int):Int {
	return binarySearchImpl(sequence, 0, sequence.length, val);
}

function bitSetSetBetween(bitset:BitSet, start:Int, ?end:Null<Int>, ?value:Null<Bool>):Void {
	final setValue = value == null ? true : value;
	final endIndex = end == null ? bitset.length : end;

	for (i in start...endIndex) {
		bitset.setAt(i, value);
	}
}
