// Copyright 2000-2023 JetBrains s.r.o. and contributors. Use of this source code is governed by the Apache 2.0 license.
interface RangeType {
	public function compareTo(a:Dynamic):Int;

	public function equals(a:Dynamic):Int;
}

@:generic
class Range<T:RangeType> {
	private final myFrom:T;
	private final myTo:T;

	public function new(from:T, to:T) {
		myFrom = from;
		myTo = to;
	}

	public function isWithinA(object:T):Bool {
		return isWithinB(object, true);
	}

	public function isWithinB(object:T, includingEndpoints:Bool):Bool {
		if (includingEndpoints) {
			return object.compareTo(myFrom) >= 0 && object.compareTo(myTo) <= 0;
		}
		return object.compareTo(myFrom) > 0 && object.compareTo(myTo) < 0;
	}

	public function getFrom():T {
		return myFrom;
	}

	public function getTo():T {
		return myTo;
	}

	public function toString():String {
		return "(" + myFrom + "," + myTo + ")";
	}

	public function equals(o: Range<Dynamic>):Bool {
		return this.getFrom() == o.getFrom() && this.getTo() == o.getTo();
	}
}
