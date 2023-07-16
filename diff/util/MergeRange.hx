// Copyright 2000-2021 JetBrains s.r.o. and contributors. Use of this source code is governed by the Apache 2.0 license.
package diff.util;

class MergeRange {
	public final start1:Int;
	public final end1:Int;
	public final start2:Int;
	public final end2:Int;
	public final start3:Int;
	public final end3:Int;

	public function new(start1:Int, end1:Int, start2:Int, end2:Int, start3:Int, end3:Int) {
		this.start1 = start1;
		this.end1 = end1;
		this.start2 = start2;
		this.end2 = end2;
		this.start3 = start3;
		this.end3 = end3;
	}

	public function equals(range:MergeRange):Bool {
		if (this == range)
			return true;

		if (start1 != range.start1)
			return false;
		if (end1 != range.end1)
			return false;
		if (start2 != range.start2)
			return false;
		if (end2 != range.end2)
			return false;
		if (start3 != range.start3)
			return false;
		if (end3 != range.end3)
			return false;

		return true;
	}

	public function toString():String {
		return "[" + start1 + ", " + end1 + ") - [" + start2 + ", " + end2 + ") - [" + start3 + ", " + end3 + ")";
	}

	public function isEmpty():Bool {
		return start1 == end1 && start2 == end2 && start3 == end3;
	}
}
