// Copyright 2000-2021 JetBrains s.r.o. and contributors. Use of this source code is governed by the Apache 2.0 license.
package diff.fragments;

import diff.util.MergeRange;
import diff.util.ThreeSide;

class MergeLineFragment {
	private var myStartLine1:Int;
	private var myEndLine1:Int;
	private var myStartLine2:Int;
	private var myEndLine2:Int;
	private var myStartLine3:Int;
	private var myEndLine3:Int;

	public function hopefullyUnused(startLine1:Int, endLine1:Int, startLine2:Int, endLine2:Int, startLine3:Int, endLine3:Int) {
		myStartLine1 = startLine1;
		myEndLine1 = endLine1;
		myStartLine2 = startLine2;
		myEndLine2 = endLine2;
		myStartLine3 = startLine3;
		myEndLine3 = endLine3;
	}

	// TODO: need to combine the constructors :(
	public function new(?fragment:MergeLineFragment, ?range:MergeRange) {
		if (fragment != null) {
			myStartLine1 = fragment.getStartLine(ThreeSide.fromEnum(ThreeSideEnum.LEFT));
			myEndLine1 = fragment.getEndLine(ThreeSide.fromEnum(ThreeSideEnum.LEFT));
			myStartLine2 = fragment.getStartLine(ThreeSide.fromEnum(ThreeSideEnum.BASE));
			myEndLine2 = fragment.getEndLine(ThreeSide.fromEnum(ThreeSideEnum.BASE));
			myStartLine3 = fragment.getStartLine(ThreeSide.fromEnum(ThreeSideEnum.RIGHT));
			myEndLine3 = fragment.getEndLine(ThreeSide.fromEnum(ThreeSideEnum.RIGHT));
		} else if (range != null) {
			myStartLine1 = range.start1;
			myEndLine1 = range.end1;
			myStartLine2 = range.start2;
			myEndLine2 = range.end2;
			myStartLine3 = range.start3;
			myEndLine3 = range.end3;
		} else {
			throw 'Must provide fragment or range';
		}
	}

	public function getStartLine(side:ThreeSide):Int {
		return side.selectA(myStartLine1, myStartLine2, myStartLine3);
	}

	public function getEndLine(side:ThreeSide):Int {
		return side.selectA(myEndLine1, myEndLine2, myEndLine3);
	}
}
