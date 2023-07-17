// Copyright 2000-2022 JetBrains s.r.o. and contributors. Use of this source code is governed by the Apache 2.0 license.
package ds;

/**
 * Generic wrapper around two related values.
 */
class Pair<A, B> {
	public final first:A;
	public final second:B;

	@:generic
	public static function create<A, B>(first:Null<A>, second:Null<B>):Pair<A, B> {
		return new Pair(first, second);
	}

	@NotNull
	public static function createNonNull<A, B>(first:A, second:B):NonNull<A, B> {
		return new NonNull(first, second);
	}

	@NotNull
	public static function pair<A, B>(first:A, second:B):Pair<A, B> {
		return new Pair(first, second);
	}

	public static function getFirstA<T>(pair:Pair<T, Dynamic>):T {
		return pair != null ? pair.first : null;
	}

	public static function getSecondA<T>(pair:Pair<Dynamic, T>):T {
		return pair != null ? pair.second : null;
	}

	public static function empty<A, B>():Pair<A, B> {
		return create(null, null);
	}

	/**
	 * @see #create(Object, Object)
	 */
	public function new(first:A, second:B) {
		this.first = first;
		this.second = second;
	}

	public function getFirstB():A {
		return first;
	}

	public function getSecondB():B {
		return second;
	}

	// public boolean equals(Object o) {
	//   return o instanceof Pair && Comparing.equal(first, ((Pair<?, ?>)o).first) && Comparing.equal(second, ((Pair<?, ?>)o).second);
	// }

	// public function hashCode():Int {
	// 	var result:Int = first != null ? first.hashCode() : 0;
	// 	result = 31 * result + (second != null ? second.hashCode() : 0);
	// 	return result;
	// }

	public function toString():String {
		return "<" + first + "," + second + ">";
	}

	// /**
	//  * @param <A> first value type (Comparable)
	//  * @param <B> second value type
	//  * @return a comparator that compares pair values by first value
	//  */
	// public static <A extends Comparable<? super A>, B> Comparator<Pair<A, B>> comparingByFirst() {
	//   return new Comparator<Pair<A, B>>() {
	//     @Override
	//     public int compare(Pair<A, B> o1, Pair<A, B> o2) {
	//       return o1.first.compareTo(o2.first);
	//     }
	//   };
	// }
	//
	// /**
	//  * @param <A> first value type
	//  * @param <B> second value type (Comparable)
	//  * @return a comparator that compares pair values by second value
	//  */
	// public static <A, B extends Comparable<? super B>> Comparator<Pair<A, B>> comparingBySecond() {
	//   return new Comparator<Pair<A, B>>() {
	//     @Override
	//     public int compare(Pair<A, B> o1, Pair<A, B> o2) {
	//       return o1.second.compareTo(o2.second);
	//     }
	//   };
	// }
}

class NonNull<A, B> extends Pair</*@NotNull*/ A, /*@NotNull*/ B> {
	public function new(first:A, second:B) {
		super(first, second);
	}
}
