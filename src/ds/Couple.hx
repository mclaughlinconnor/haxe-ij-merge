package ds;

class Couple<T> {
	public var first:T;
	public var second:T;

	public function new(first:T, second:T) {
		this.first = first;
		this.second = second;
	}

	@:generic
	static public function of<T>(first:T, second:T):Couple<T> {
		return new Couple(first, second);
	}
}
