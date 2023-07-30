package util;

import util.Hashable;

@:forward
abstract HashableStringArray(Array<HashableString>) from Array<String> to Array<String> {
	@:to(HashableType)
	public function toHashable():Array<HashableType> {
		return cast(this);
	}

	@:arrayAccess
	public inline function get(index:Int): HashableString {
		return this[index];
	}
}

@:forward
abstract HashableString(String) from String to String {
	public function new(s:String) {
		this = s;
	}

	@:to(HashableType)
	public function toHashable():HashableType {
		return cast(this);
	}

	public function hashCode():Int {
		var hash:Int = 7;
		for (i in 0...this.length) {
			hash = hash * 31 + this.charCodeAt(i);
		}

		return hash;
	}
}
