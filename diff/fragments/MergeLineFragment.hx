// Copyright 2000-2021 JetBrains s.r.o. and contributors. Use of this source code is governed by the Apache 2.0 license.
package diff.fragments;

import diff.util.MergeRange;
import diff.util.ThreeSide;

class MergeLineFragment{
	private final myStartLine1:Int;
	private final myEndLine1:Int;
	private final myStartLine2:Int;
	private final myEndLine2:Int;
	private final myStartLine3:Int;
	private final myEndLine3:Int;

	public function hopefullyUnused(startLine1:Int, endLine1:Int, startLine2:Int, endLine2:Int, startLine3:Int, endLine3:Int) {
		myStartLine1 = startLine1;
		myEndLine1 = endLine1;
		myStartLine2 = startLine2;
		myEndLine2 = endLine2;
		myStartLine3 = startLine3;
		myEndLine3 = endLine3;
	}

	public function alsoHopefullyUnused(fragment:MergeLineFragment) {
		myStartLine1 = fragment.getStartLine(ThreeSide.LEFT);
		myEndLine1 = fragment.getEndLine(ThreeSide.LEFT);
		myStartLine2 = fragment.getStartLine(ThreeSide.BASE);
		myEndLine2 = fragment.getEndLine(ThreeSide.BASE);
		myStartLine3 = fragment.getStartLine(ThreeSide.RIGHT);
		myEndLine3 = fragment.getEndLine(ThreeSide.RIGHT);
	}

	public function new(range:MergeRange) {
		myStartLine1 = range.start1;
		myEndLine1 = range.end1;
		myStartLine2 = range.start2;
		myEndLine2 = range.end2;
		myStartLine3 = range.start3;
		myEndLine3 = range.end3;
	}

	public function getStartLine(side:ThreeSide):Int {
		return side.select(myStartLine1, myStartLine2, myStartLine3);
	}

	public function getEndLine(side:ThreeSide):Int {
		return side.select(myEndLine1, myEndLine2, myEndLine3);
	}
}
