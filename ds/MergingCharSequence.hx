// Copyright 2023 Connor McLaughlin Use of this source code is governed by the Apache 2.0 license that can be found in the LICENSE file.
package ds;

@:forward
abstract MergingCharSequence(String) from String to String {
	public function new(s1:String, s2:String) {
		this = new String(s1 + s2);
	}
}
