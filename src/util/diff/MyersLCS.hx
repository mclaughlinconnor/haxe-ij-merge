// Copyright 2000-2021 JetBrains s.r.o. and contributors. Use of this source code is governed by the Apache 2.0 license.
package util.diff;

import config.DiffConfig;
import iterators.StepIterator;
import exceptions.IllegalStateException;
import thx.BitSet;

/**
 * Algorithm for finding the longest common subsequence of two strings
 * Based on E.W. Myers / An O(ND) Difference Algorithm and Its Variations / 1986
 * O(ND) runtime, O(N) memory
 * <p/>
 * Created by Anton Bannykh
 */
class MyersLCS {
	private final myFirst:Array<Int>;
	private final mySecond:Array<Int>;

	private final myStart1:Int;
	private final myStart2:Int;
	private final myCount1:Int;
	private final myCount2:Int;

	private final myChanges1:BitSet;
	private final myChanges2:BitSet;

	private final VForward:Array<Int>;
	private final VBackward:Array<Int>;

	public function new(first:Array<Int>, second:Array<Int>, ?start1:Int, ?count1:Int, ?start2:Int, ?count2:Int, ?changes1:BitSet, ?changes2:BitSet) {
		myFirst = first;
		mySecond = second;

		if (start1 == null && count1 == null && start2 == null && count2 == null && changes1 == null && changes2 == null) {
			myStart1 = 0;
			myStart2 = 0;
			myCount1 = first.length;
			myCount2 = second.length;
			myChanges1 = new BitSet(first.length);
			myChanges2 = new BitSet(second.length);
		} else {
			myStart1 = start1;
			myStart2 = start2;
			myCount1 = count1;
			myCount2 = count2;

			myChanges1 = changes1;
			myChanges2 = changes2;
		}

		for (i in myStart1...myStart1 + myCount1 + 1) {
			myChanges1.setAt(i, true);
		}

		for (i in myStart2...myStart2 + myCount2 + 1) {
			myChanges2.setAt(i, true);
		}

		final totalSequenceLength:Int = myCount1 + myCount2;
		VForward = [for (_ in 0...totalSequenceLength + 1) 0];
		VBackward = [for (_ in 0...totalSequenceLength + 1) 0];
	}

	/**
	 * Runs O(ND) Myers algorithm where D is bound by A + B * sqrt(N)
	 * <p/>
	 * Under certains assumptions about the distribution of the elements of the sequences the expected
	 * running time of the myers algorithm is O(N + D^2). Thus under given constraints it reduces to O(N).
	 */
	public function executeLinear():Void {
		try {
			var threshold:Int = 20000 + 10 * Std.int(Math.sqrt(myCount1 + myCount2));
			executeB(threshold, false);
		} catch (e:FilesTooBigForDiffException) {
			throw new IllegalStateException('');
		}
	}

	public function executeA():Void {
		try {
			executeB(myCount1 + myCount2, false);
		} catch (e:FilesTooBigForDiffException) {
			throw new IllegalStateException(''); // should not happen
		}
	}

	public function executeWithThreshold():Void {
		var threshold:Int = Std.int(Math.max(20000 + 10 * Std.int(Math.sqrt(myCount1 + myCount2)), DiffConfig.DELTA_THRESHOLD_SIZE));
		executeB(threshold, true);
	}

	private function executeB(threshold:Int, throwException:Bool):Void {
		if (myCount1 == 0 || myCount2 == 0) {
			return;
		}
		executeC(0, myCount1, 0, myCount2, Std.int(Math.min(threshold, myCount1 + myCount2)), throwException);
	}

	// LCS( old[oldStart, oldEnd), new[newStart, newEnd) )
	private function executeC(oldStart:Int, oldEnd:Int, newStart:Int, newEnd:Int, differenceEstimate:Int, throwException:Bool):Void {
		// assert oldStart <= oldEnd && newStart <= newEnd;

		if (oldStart < oldEnd && newStart < newEnd) {
			final oldLength:Int = oldEnd - oldStart;
			final newLength:Int = newEnd - newStart;
			VForward[newLength + 1] = 0;
			VBackward[newLength + 1] = 0;

			final halfD:Int = Std.int((differenceEstimate + 1) / 2);

			var xx, kk, td:Int;
			xx = kk = td = -1;

			for (d in 0...halfD + 1) {
				final L:Int = newLength + Std.int(Math.max(-d, -newLength + ((d ^ newLength) & 1)));
				final R:Int = newLength + Std.int(Math.min(d, oldLength - ((d ^ oldLength) & 1)));

				for (k in new StepIterator(L, R, 2, true)) {
					var x:Int = k == L || k != R && VForward[k - 1] < VForward[k + 1] ? VForward[k + 1] : VForward[k - 1] + 1;
					var y:Int = x - k + newLength;
					x += commonSubsequenceLengthForward(oldStart + x, newStart + y, Std.int(Math.min(oldEnd - oldStart - x, newEnd - newStart - y)));
					VForward[k] = x;
				}
				if ((oldLength - newLength) % 2 != 0) {
					var b:Bool = false;
					for (k in new StepIterator(L, R, 2, true)) {
						if (oldLength - (d - 1) <= k && k <= oldLength + (d - 1)) {
							if (VForward[k] + VBackward[newLength + oldLength - k] >= oldLength) {
								xx = VForward[k];
								kk = k;
								td = 2 * d - 1;

								b = true;
								break;
							}
						}
					}

					if (b) {
						break;
					}
				}
				for (k in new StepIterator(L, R, 2, true)) {
					var x:Int = k == L || k != R && VBackward[k - 1] < VBackward[k + 1] ? VBackward[k + 1] : VBackward[k - 1] + 1;
					var y:Int = x - k + newLength;

					x += commonSubsequenceLengthBackward(oldEnd - 1 - x, newEnd - 1 - y, Std.int(Math.min(oldEnd - oldStart - x, newEnd - newStart - y)));
					VBackward[k] = x;
				}
				if ((oldLength - newLength) % 2 == 0) {
					var b:Bool = false;

					for (k in new StepIterator(L, R, 2, true)) {
						if (oldLength - d <= k && k <= oldLength + d) {
							if (VForward[oldLength + newLength - k] + VBackward[k] >= oldLength) {
								xx = oldLength - VBackward[k];
								kk = oldLength + newLength - k;
								td = 2 * d;

								b = true;
								break;
							}
						}
					}

					if (b) {
						break;
					}
				}
			}

			if (td > 1) {
				final yy:Int = xx - kk + newLength;
				final oldDiff:Int = Std.int((td + 1) / 2);

				if (0 < xx && 0 < yy) {
					executeC(oldStart, oldStart + xx, newStart, newStart + yy, oldDiff, throwException);
				}
				if (oldStart + xx < oldEnd && newStart + yy < newEnd) {
					executeC(oldStart + xx, oldEnd, newStart + yy, newEnd, td - oldDiff, throwException);
				}
			} else if (td >= 0) {
				var x:Int = oldStart;
				var y:Int = newStart;

				while (x < oldEnd && y < newEnd) {
					final commonLength:Int = commonSubsequenceLengthForward(x, y, Std.int(Math.min(oldEnd - x, newEnd - y)));
					if (commonLength > 0) {
						addUnchanged(x, y, commonLength);
						x += commonLength;
						y += commonLength;
					} else if (oldEnd - oldStart > newEnd - newStart) {
						++x;
					} else {
						++y;
					}
				}
			} else {
				// The difference is more than the given estimate
				if (throwException) {
					throw new FilesTooBigForDiffException('');
				}
			}
		}
	}

	private function addUnchanged(start1:Int, start2:Int, count:Int):Void {
		for (i in myStart1 + start1...myStart1 + start1 + count) {
			myChanges1.setAt(i, false);
		}

		for (i in myStart2 + start2...myStart2 + start2 + count) {
			myChanges2.setAt(i, false);
		}
	}

	private function commonSubsequenceLengthForward(oldIndex:Int, newIndex:Int, maxLength:Int):Int {
		var x:Int = oldIndex;
		var y:Int = newIndex;

		maxLength = Std.int(Math.min(maxLength, Math.min(myCount1 - oldIndex, myCount2 - newIndex)));
		while (x - oldIndex < maxLength && myFirst[myStart1 + x] == mySecond[myStart2 + y]) {
			++x;
			++y;
		}

		return x - oldIndex;
	}

	private function commonSubsequenceLengthBackward(oldIndex:Int, newIndex:Int, maxLength:Int):Int {
		var x:Int = oldIndex;
		var y:Int = newIndex;

		maxLength = Std.int(Math.min(maxLength, Math.min(oldIndex, newIndex) + 1));
		while (oldIndex - x < maxLength && myFirst[myStart1 + x] == mySecond[myStart2 + y]) {
			--x;
			--y;
		}

		return oldIndex - x;
	}

	public function getChanges():Array<BitSet> {
		return [myChanges1, myChanges2];
	}
}
