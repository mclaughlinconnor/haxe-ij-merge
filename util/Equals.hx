package util;

@:generic
interface Equals<T> {
	public function equals(a:T):Bool;
}

typedef EqualsType<T> = {
	public function equals(a:T):Bool;
}
