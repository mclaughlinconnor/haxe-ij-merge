// Copyright 2000-2021 JetBrains s.r.o. and contributors. Use of this source code is governed by the Apache 2.0 license.
package ds;

import haxe.ds.ObjectMap;

@:generic
class Enumerator<T:{}> {
	private final myNumbers:ObjectMap<T, Int>;
	private var myNextNumber:Int = 1;

	public function new(expectNumber:Int) {
		myNumbers = new ObjectMap();
	}

	public function clear():Void {
		myNumbers.clear();
		myNextNumber = 1;
	}

	public function enumerateA(objects:Array<T>):Array<Int> {
		return enumerateB(objects, 0, 0);
	}

	public function enumerateB(objects:Array<T>, startShift:Int, endCut:Int):Array<Int> {
		var idx:Array<Int> = [for (_ in 0...objects.length - startShift - endCut) 0];
		for (i in startShift...objects.length - endCut) {
			final object:T = objects[i];
			final number:Int = enumerateC(object);
			idx[i - startShift] = number;
		}
		return idx;
	}

	public function enumerateC(object:T):Int {
		final res:Int = enumerateImpl(object);
		return Std.int(Math.max(res, -res));
	}

	public function add(object:T):Bool {
		final res:Int = enumerateImpl(object);
		return res < 0;
	}

	public function enumerateImpl(object:T):Int {
		if (object == null) {
			return 0;
		}

		var number:Int = myNumbers.get(object);
		if (number == 0) {
			number = myNextNumber++;
			myNumbers.set(object, number);
			return -number;
		}
		return number;
	}

	public function contains(object:T):Bool {
		return myNumbers.get(object) != 0;
	}

	public function get(object:T):Int {
		if (object == null) {
			return 0;
		}
		final res:Int = myNumbers.get(object);

		return res;
	}
}
