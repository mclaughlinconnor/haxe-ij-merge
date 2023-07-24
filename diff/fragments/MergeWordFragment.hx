// Copyright 2000-2021 JetBrains s.r.o. and contributors. Use of this source code is governed by the Apache 2.0 license.
package diff.fragments;

import diff.util.ThreeSide;
import diff.util.MergeRange;

class MergeWordFragment {
	private var myStartOffset1:Int;
	private var myEndOffset1:Int;
	private var myStartOffset2:Int;

	private var myEndOffset2:Int;
	private var myStartOffset3:Int;
	private var myEndOffset3:Int;

	public function new(startOffset1:Int, endOffset1:Int, startOffset2:Int, endOffset2:Int, startOffset3:Int, endOffset3:Int) {
		myStartOffset1 = startOffset1;
		myEndOffset1 = endOffset1;
		myStartOffset2 = startOffset2;
		myEndOffset2 = endOffset2;
		myStartOffset3 = startOffset3;
		myEndOffset3 = endOffset3;
	}

	public static function newFromRange(range:MergeRange): MergeWordFragment {
		return new MergeWordFragment(range.start1, range.end1, range.start2, range.end2, range.start3, range.end3);
	}

	public function getStartOffset(side:ThreeSide):Int {
		return side.selectA(myStartOffset1, myStartOffset2, myStartOffset3);
	}

	public function getEndOffset(side:ThreeSide):Int {
		return side.selectA(myEndOffset1, myEndOffset2, myEndOffset3);
	}
}
