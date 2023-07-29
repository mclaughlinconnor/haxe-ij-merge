// Copyright 2000-2021 JetBrains s.r.o. and contributors. Use of this source code is governed by the Apache 2.0 license.
package util.diff;

import thx.BitSet;

class PatienceIntLCS {
	private final myFirst:Array<Int>;
	private final mySecond:Array<Int>;

	private final myStart1:Int;
	private final myStart2:Int;
	private final myCount1:Int;
	private final myCount2:Int;

	private final myChanges1:BitSet;
	private final myChanges2:BitSet;

	public function new(first:Array<Int>, second:Array<Int>, ?start1:Int, ?count1:Int, ?start2:Int, ?count2:Int, ?changes1:BitSet, ?changes2:BitSet) {
		myFirst = first;
		mySecond = second;

		if (start1 == null && count1 == null && start2 == null && count2 == null && changes1 == null && changes2 == null) {
			myStart1 = 0;
			myStart2 = first.length;
			myCount1 = 0;
			myCount2 = second.length;
			myChanges1 = new BitSet(first.length);
			myChanges2 = new BitSet(second.length);

			return;
		}

		myStart1 = start1;
		myStart2 = start2;
		myCount1 = count1;
		myCount2 = count2;

		myChanges1 = changes1;
		myChanges2 = changes2;
	}

	public function executeA():Void {
		executeB(false);
	}

	public function executeB(failOnSmallReduction:Bool):Void {
		var thresholdCheckCounter:Int = failOnSmallReduction ? 2 : -1;
		executeC(myStart1, myCount1, myStart2, myCount2, thresholdCheckCounter);
	}

	private function executeC(start1:Int, count1:Int, start2:Int, count2:Int, thresholdCheckCounter:Int):Void {
		if (count1 == 0 && count2 == 0) {
			return;
		}

		if (count1 == 0 || count2 == 0) {
			this.addChange(start1, count1, start2, count2);
			return;
		}

		var startOffset:Int = matchForward(start1, count1, start2, count2);
		start1 += startOffset;
		start2 += startOffset;
		count1 -= startOffset;
		count2 -= startOffset;

		var endOffset:Int = matchBackward(start1, count1, start2, count2);
		count1 -= endOffset;
		count2 -= endOffset;

		if (count1 == 0 || count2 == 0) {
			addChange(start1, count1, start2, count2);
		} else {
			if (thresholdCheckCounter == 0) {
				checkReduction(count1, count2);
			}

			thresholdCheckCounter = Std.int(Math.max(-1, thresholdCheckCounter - 1));

			var uniqueLCS:UniqueLCS = new UniqueLCS(myFirst, mySecond, start1, count1, start2, count2);
			var matching:Array<Array<Int>> = uniqueLCS.execute();

			if (matching == null) {
				if (thresholdCheckCounter >= 0)
					checkReduction(count1, count2);
				var intLCS:MyersLCS = new MyersLCS(myFirst, mySecond, start1, count1, start2, count2, myChanges1, myChanges2);
				intLCS.executeLinear();
			} else {
				var s1, s2, c1, c2:Int;
				var matched:Int = matching[0].length;
				// assert matched > 0;

				c1 = matching[0][0];
				c2 = matching[1][0];

				executeC(start1, c1, start2, c2, thresholdCheckCounter);

				for (i in 1...matching[0].length) {
					s1 = matching[0][i - 1] + 1;
					s2 = matching[1][i - 1] + 1;

					c1 = matching[0][i] - s1;
					c2 = matching[1][i] - s2;

					if (c1 > 0 || c2 > 0) {
						executeC(start1 + s1, c1, start2 + s2, c2, thresholdCheckCounter);
					}
				}

				if (matching[0][matched - 1] == count1 - 1) {
					s1 = count1 - 1;
					c1 = 0;
				} else {
					s1 = matching[0][matched - 1] + 1;
					c1 = count1 - s1;
				}
				if (matching[1][matched - 1] == count2 - 1) {
					s2 = count2 - 1;
					c2 = 0;
				} else {
					s2 = matching[1][matched - 1] + 1;
					c2 = count2 - s2;
				}

				executeC(start1 + s1, c1, start2 + s2, c2, thresholdCheckCounter);
			}
		}
	}

	private function matchForward(start1:Int, count1:Int, start2:Int, count2:Int):Int {
		final size:Int = Std.int(Math.min(count1, count2));
		var idx:Int = 0;
		for (i in 0...size) {
			if (!(myFirst[start1 + i] == mySecond[start2 + i])) {
				break;
			}
			++idx;
		}
		return idx;
	}

	private function matchBackward(start1:Int, count1:Int, start2:Int, count2:Int):Int {
		final size:Int = Std.int(Math.min(count1, count2));
		var idx:Int = 0;
		for (i in 1...size) {
			if (!(myFirst[start1 + count1 - i] == mySecond[start2 + count2 - i])) {
				break;
			}
			++idx;
		}
		return idx;
	}

	private function addChange(start1:Int, count1:Int, start2:Int, count2:Int):Void {
		for (i in myStart1...myStart1 + count1) {
			myChanges1.setAt(i, true);
		}
		for (i in myStart2...myStart2 + count2) {
			myChanges2.setAt(i, true);
		}
	}

	public function getChanges():Array<BitSet> {
		return [myChanges1, myChanges2];
	}

	private function checkReduction(count1:Int, count2:Int):Void {
		if (count1 * 2 < myCount1) {
			return;
		}
		if (count2 * 2 < myCount2) {
			return;
		}
		throw new FilesTooBigForDiffException('');
	}
}
