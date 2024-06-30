// Copyright 2000-2021 JetBrains s.r.o. and contributors. Use of this source code is governed by the Apache 2.0 license.
package diff.util;

import exceptions.IllegalStateException;
import exceptions.IndexOutOfBoundsException;

enum ThreeSideEnum {
	LEFT;
	BASE;
	RIGHT;
}

class ThreeSide {
	private final myIndex:Int;

	public function new(index:Int) {
		myIndex = index;
	}

	public static function fromEnum(from:ThreeSideEnum):ThreeSide {
		var index:Int;
		switch (from) {
			case ThreeSideEnum.LEFT:
				index = 0;
			case ThreeSideEnum.BASE:
				index = 1;
			case ThreeSideEnum.RIGHT:
				index = 2;
		}

		return new ThreeSide(index);
	}

	public static function fromIndex(index:Int):ThreeSideEnum {
		if (index == 0)
			return LEFT;
		if (index == 1)
			return BASE;
		if (index == 2)
			return RIGHT;
		throw new IndexOutOfBoundsException("index: " + index);
	}

	public function getIndex():Int {
		return myIndex;
	}

	//
	// Helpers
	//

	@:generic
	public function selectA<T>(left:Null<T>, base:Null<T>, right:Null<T>):T {
		if (myIndex == 0)
			return left;
		if (myIndex == 1)
			return base;
		if (myIndex == 2)
			return right;
		throw new IllegalStateException('');
	}

	public function selectB(left:Int, base:Int, right:Int):Int {
		if (myIndex == 0)
			return left;
		if (myIndex == 1)
			return base;
		if (myIndex == 2)
			return right;
		throw new IllegalStateException('');
	}

	@:generic
	public function selectC<T>(array:Array<T>):T {
		// assert array.length == 3;
		return array[myIndex];
	}

	@:generic
	public function selectNotNullA<T>(left:Null<T>, base:Null<T>, right:Null<T>):T {
		if (myIndex == 0)
			return left;
		if (myIndex == 1)
			return base;
		if (myIndex == 2)
			return right;
		throw new IllegalStateException('');
	}

	@:generic
	public function selectNotNullB<T>(array:Array<T>):T {
		// assert array.length == 3;
		return array[myIndex];
	}

	@:generic
	public static function map<T>(f:(t:ThreeSide) -> T):Array<T> {
		return [f(fromEnum(LEFT)), f(fromEnum(BASE)), f(fromEnum(RIGHT))];
	}
}
