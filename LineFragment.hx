// Copyright 2000-2021 JetBrains s.r.o. and contributors. Use of this source code is governed by the Apache 2.0 license.
class LineFragment {
	private var myStartLine1:Int;
	private var myEndLine1:Int;
	private var myStartLine2:Int;
	private var myEndLine2:Int;

	private var myStartOffset1:Int;
	private var myEndOffset1:Int;
	private var myStartOffset2:Int;
	private var myEndOffset2:Int;

	private var myInnerFragments:Array<DiffFragment>;

	public function newFromExpanded(startLine1:Int, endLine1:Int, startLine2:Int, endLine2:Int, startOffset1:Int, endOffset1:Int, startOffset2:Int,
			endOffset2:Int) {
		newFromSomethingDifferent(startLine1, endLine1, startLine2, endLine2, startOffset1, endOffset1, startOffset2, endOffset2, null);
	}

	public function newFromFragment(fragment:LineFragment, fragments:Null<Array<DiffFragment>>) {
		newFromSomethingDifferent(fragment.getStartLine1(), fragment.getEndLine1(), fragment.getStartLine2(), fragment.getEndLine2(), fragment.getStartOffset1(),
			fragment.getEndOffset1(), fragment.getStartOffset2(), fragment.getEndOffset2(), fragments);
	}

	public function newFromSomethingDifferent(startLine1:Int, endLine1:Int, startLine2:Int, endLine2:Int, startOffset1:Int, endOffset1:Int, startOffset2:Int,
			endOffset2:Int, innerFragments:Null<Array<DiffFragment>>) {
		myStartLine1 = startLine1;
		myEndLine1 = endLine1;
		myStartLine2 = startLine2;
		myEndLine2 = endLine2;
		myStartOffset1 = startOffset1;
		myEndOffset1 = endOffset1;
		myStartOffset2 = startOffset2;
		myEndOffset2 = endOffset2;

		myInnerFragments = dropWholeChangedFragments(innerFragments, endOffset1 - startOffset1, endOffset2 - startOffset2);

		if (myStartLine1 == myEndLine1 && myStartLine2 == myEndLine2) {
			trace("LineFragmentImpl should not be empty: " + toString());
		}
		if (myStartLine1 > myEndLine1 || myStartLine2 > myEndLine2 || myStartOffset1 > myEndOffset1 || myStartOffset2 > myEndOffset2) {
			trace("LineFragmentImpl is invalid: " + toString());
		}
	}

	public function getStartLine1():Int {
		return myStartLine1;
	}

	public function getEndLine1():Int {
		return myEndLine1;
	}

	public function getStartLine2():Int {
		return myStartLine2;
	}

	public function getEndLine2():Int {
		return myEndLine2;
	}

	public function getStartOffset1():Int {
		return myStartOffset1;
	}

	public function getEndOffset1():Int {
		return myEndOffset1;
	}

	public function getStartOffset2():Int {
		return myStartOffset2;
	}

	public function getEndOffset2():Int {
		return myEndOffset2;
	}

	public function getInnerFragments():Array<DiffFragment> {
		return myInnerFragments;
	}

	private static function dropWholeChangedFragments(fragments:Null<Array<DiffFragment>>, length1:Int, length2:Int):Array<DiffFragment> {
		if (fragments != null && fragments.length == 1) {
			var diffFragment: DiffFragment = fragments.first();
			if (diffFragment.getStartOffset1() == 0
				&& diffFragment.getStartOffset2() == 0
				&& diffFragment.getEndOffset1() == length1
				&& diffFragment.getEndOffset2() == length2) {
				return null;
			}
		}
		return fragments;
	}

	public function toString():String {
		return "LineFragmentImpl: Lines [" + myStartLine1 + ", " + myEndLine1 + ") - [" + myStartLine2 + ", " + myEndLine2 + "); " + "Offsets ["
			+ myStartOffset1 + ", " + myEndOffset1 + ") - [" + myStartOffset2 + ", " + myEndOffset2 + "); " + "Inner "
			+ (myInnerFragments != null ? myInnerFragments.length : null);
	}
}
