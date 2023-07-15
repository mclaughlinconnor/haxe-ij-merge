// Copyright 2000-2023 JetBrains s.r.o. and contributors. Use of this source code is governed by the Apache 2.0 license.
// interface RangeType {
// 	public function compareTo(a:Dynamic):Int;
//
// 	public function equals(a:Dynamic):Int;
// }
//
// @:generic
// class Range<T:RangeType> {
// 	private final myFrom:T;
// 	private final myTo:T;
//
// 	public function new(from:T, to:T) {
// 		myFrom = from;
// 		myTo = to;
// 	}
//
// 	public function isWithinA(object:T):Bool {
// 		return isWithinB(object, true);
// 	}
//
// 	public function isWithinB(object:T, includingEndpoints:Bool):Bool {
// 		if (includingEndpoints) {
// 			return object.compareTo(myFrom) >= 0 && object.compareTo(myTo) <= 0;
// 		}
// 		return object.compareTo(myFrom) > 0 && object.compareTo(myTo) < 0;
// 	}
//
// 	public function getFrom():T {
// 		return myFrom;
// 	}
//
// 	public function getTo():T {
// 		return myTo;
// 	}
//
// 	public function toString():String {
// 		return "(" + myFrom + "," + myTo + ")";
// 	}
//
// 	public function equals(o: Range<Dynamic>):Bool {
// 		return this.getFrom() == o.getFrom() && this.getTo() == o.getTo();
// 	}
// }
// Copyright 2000-2022 JetBrains s.r.o. and contributors. Use of this source code is governed by the Apache 2.0 license.

/**
 * Stores half-open intervals [start, end).
 */
class Range {
	public final start1:Int;
	public final end1:Int;
	public final start2:Int;
	public final end2:Int;

	public function new(start1:Int, end1:Int, start2:Int, end2:Int) {
		// assert start1 <= end1 && start2 <= end2 : String.format("[%s, %s, %s, %s]", start1, end1, start2, end2);
		this.start1 = start1;
		this.end1 = end1;
		this.start2 = start2;
		this.end2 = end2;
	}

	public function equals(range:Range):Bool {
		if (this == range) {
			return true;
		}

		if (start1 != range.start1) {
			return false;
		}
		if (end1 != range.end1) {
			return false;
		}
		if (start2 != range.start2) {
			return false;
		}

		if (end2 != range.end2) {
			return false;
		}

		return true;
	}

	public function toString():String {
		return "[" + start1 + ", " + end1 + ") - [" + start2 + ", " + end2 + ")";
	}

	public function isEmpty():Bool {
		return start1 == end1 && start2 == end2;
	}
}
