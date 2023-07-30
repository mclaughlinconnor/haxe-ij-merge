// Copyright 2000-2021 JetBrains s.r.o. and contributors. Use of this source code is governed by the Apache 2.0 license.
package ds;

using util.HashableString;

import util.Hashable;
import haxe.ds.IntMap;

@:generic
class Enumerator<T:HashableType> {
	private final myNumbers:IntMap<Int>;
	private var myNextNumber:Int = 1;

	public function new(expectNumber:Int) {
		myNumbers = new IntMap();
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

		var number:Int = myNumbers.get(object.hashCode());
		if (number == null) {
			number = myNextNumber++;
			myNumbers.set(object.hashCode(), number);
			return -number;
		}
		return number;
	}

	public function contains(object:T):Bool {
		return myNumbers.get(object.hashCode()) != 0;
	}

	public function get(object:T):Int {
		if (object == null) {
			return 0;
		}
		final res:Int = myNumbers.get(object.hashCode());

		return res;
	}
}
