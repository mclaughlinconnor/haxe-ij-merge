// Copyright 2000-2021 JetBrains s.r.o. and contributors. Use of this source code is governed by the Apache 2.0 license.
package diff.util;

import diff.fragments.LineFragment;
import diff.fragments.DiffFragment;
import exceptions.IndexOutOfBoundsException;

enum SideEnum {
	LEFT;
	RIGHT;
}

class Side {
	private final myIndex:Int;

	public function new(index:Int) {
		myIndex = index;
	}

	public static function fromEnum(from:SideEnum):Side {
		switch (from) {
			case SideEnum.LEFT:
				return new Side(0);
			case SideEnum.RIGHT:
				return new Side(1);
			default:
				throw new IndexOutOfBoundsException("from: " + from);
		}
	}

	public static function fromIndex(index:Int):Side {
		if (index == 0)
			return new Side(index);
		if (index == 1)
			return new Side(index);
		throw new IndexOutOfBoundsException("index: " + index);
	}

	public static function fromLeft(isLeft:Bool):SideEnum {
		return isLeft ? SideEnum.LEFT : SideEnum.RIGHT;
	}

	public static function fromRight(isRight:Bool):SideEnum {
		return isRight ? RIGHT : LEFT;
	}

	public function getIndex():Int {
		return myIndex;
	}

	public function isLeft():Bool {
		return myIndex == 0;
	}

	public function other(other:Null<Bool>):SideEnum {
		return isLeft() ? RIGHT : LEFT;
	}

	//
	// Helpers
	//

	@:generic
	public function selectA<T>(left:Null<T>, right:Null<T>):T {
		return isLeft() ? left : right;
	}

	@:generic
	public function selectNotNullA<T>(left:T, right:T):T {
		return isLeft() ? left : right;
	}

	@:generic
	public function selectB<T>(array:Array<T>):T {
		// assert array.length == 2;
		return array[myIndex];
	}

	@:generic
	public function selectNotNullB<T>(array:Array<T>):T {
		// assert array.length == 2;
		return array[myIndex];
	}

	//
	// Fragments
	//

	public function getStartOffset(fragment:DiffFragment):Int {
		return isLeft() ? fragment.getStartOffset1() : fragment.getStartOffset2();
	}

	public function getEndOffset(fragment:DiffFragment):Int {
		return isLeft() ? fragment.getEndOffset1() : fragment.getEndOffset2();
	}

	public function getStartLine(fragment:LineFragment):Int {
		return isLeft() ? fragment.getStartLine1() : fragment.getStartLine2();
	}

	public function getEndLine(fragment:LineFragment):Int {
		return isLeft() ? fragment.getEndLine1() : fragment.getEndLine2();
	}
}
