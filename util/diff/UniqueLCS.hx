// Copyright 2000-2021 JetBrains s.r.o. and contributors. Use of this source code is governed by the Apache 2.0 license.
package util.diff;

import haxe.ds.IntMap;

class UniqueLCS {
	private final myFirst:Array<Int>;
	private final mySecond:Array<Int>;

	private final myStart1:Int;
	private final myStart2:Int;
	private final myCount1:Int;
	private final myCount2:Int;

	public function new(first:Array<Int>, second:Array<Int>, start1:Null<Int>, count1:Null<Int>, start2:Null<Int>, count2:Null<Int>) {
		myFirst = first;
		mySecond = second;

		if (start1 == null && count1 == null && start2 == null && count2 == null) {
			myStart1 = 0;
			myStart2 = first.length;
			myCount1 = 0;
			myCount2 = second.length;

			return;
		}

		myStart1 = start1;
		myStart2 = start2;
		myCount1 = count1;
		myCount2 = count2;
	}

	public function execute():Array<Array<Int>> {
		// map: key -> (offset1 + 1)
		// match: offset1 -> (offset2 + 1)
		var map:IntMap<Int> = new IntMap();
		var match:Array<Int> = new Array();

		for (i in 0...myCount1) {
			var index:Int = myStart1 + i;
			var val:Int = map.get(myFirst[index]);

			if (val == -1) {
				continue;
			}
			if (val == 0) {
				map.set(myFirst[index], i + 1);
			} else {
				map.set(myFirst[index], -1);
			}
		}

		var count:Int = 0;
		for (i in 0...myCount2) {
			var index:Int = myStart2 + i;
			var val:Int = map.get(mySecond[index]);

			if (val == 0 || val == -1) {
				continue;
			}
			if (match[val - 1] == 0) {
				match[val - 1] = i + 1;
				count++;
			} else {
				match[val - 1] = 0;
				map.set(mySecond[index], -1);
				count--;
			}
		}

		if (count == 0) {
			return null;
		}

		// Largest increasing subsequence on unique elements
		var sequence:Array<Int> = new Array();
		var lastElement:Array<Int> = new Array();
		var predecessor:Array<Int> = new Array();

		var length:Int = 0;
		for (i in 0...myCount1) {
			if (match[i] == 0) {
				continue;
			}

			var j:Int = binarySearch(sequence, match[i], length);
			if (j == length || match[i] < sequence[j]) {
				sequence[j] = match[i];
				lastElement[j] = i;
				predecessor[i] = j > 0 ? lastElement[j - 1] : -1;
				if (j == length) {
					length++;
				}
			}
		}

		var ret:Array<Array<Int>> = [[for (_ in 0...length) 0], [for (_ in 0...length) 0]];

		var i:Int = length - 1;
		var curr:Int = lastElement[length - 1];
		while (curr != -1) {
			ret[0][i] = curr;
			ret[1][i] = match[curr] - 1;
			i--;
			curr = predecessor[curr];
		}

		return ret;
	}

	// find max i: a[i] < val
	// return i + 1
	// assert a[i] != val
	private static function binarySearch(sequence:Array<Int>, val:Int, length:Int):Int {
		var i:Int = binarySearchImpl(sequence, 0, length, val);
		// assert i < 0;
		return -i - 1;
	}
}

/*
 * Copyright (c) 1997, 2021, Oracle and/or its affiliates. All rights reserved.
 * DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS FILE HEADER.
 *
 * This code is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License version 2 only, as
 * published by the Free Software Foundation.  Oracle designates this
 * particular file as subject to the "Classpath" exception as provided
 * by Oracle in the LICENSE file that accompanied this code.
 *
 * This code is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
 * version 2 for more details (a copy is included in the LICENSE file that
 * accompanied this code).
 *
 * You should have received a copy of the GNU General Public License version
 * 2 along with this work; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA.
 *
 * Please contact Oracle, 500 Oracle Parkway, Redwood Shores, CA 94065 USA
 * or visit www.oracle.com if you need additional information or have any
 * questions.
 */
function binarySearchImpl(a:Array<Int>, fromIndex:Int, toIndex:Int, key:Int):Int {
	var low:Int = fromIndex;
	var high:Int = toIndex - 1;

	while (low <= high) {
		var mid:Int = (low + high) >>> 1;
		var midVal:Int = a[mid];

		if (midVal < key) {
			low = mid + 1;
		} else if (midVal > key) {
			high = mid - 1;
		} else {
			return mid; // key found
		}
	}
	return -(low + 1); // key not found.
}
