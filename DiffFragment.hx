// Copyright 2000-2021 JetBrains s.r.o. and contributors. Use of this source code is governed by the Apache 2.0 license.

/**
 * Modified part of the text
 */
interface DiffFragment {
	public function getStartOffset1():Int;

	public function getEndOffset1():Int;

	public function getStartOffset2():Int;

	public function getEndOffset2():Int;
}

class DiffFragmentImpl implements DiffFragment {
	private final myStartOffset1:Int;
	private final myEndOffset1:Int;
	private final myStartOffset2:Int;
	private final myEndOffset2:Int;

	public function new(startOffset1:Int, endOffset1:Int, startOffset2:Int, endOffset2:Int) {
		myStartOffset1 = startOffset1;
		myEndOffset1 = endOffset1;
		myStartOffset2 = startOffset2;
		myEndOffset2 = endOffset2;

		if (myStartOffset1 == myEndOffset1 && myStartOffset2 == myEndOffset2) {
			trace("DiffFragmentImpl should not be empty: " + toString());
		}
		if (myStartOffset1 > myEndOffset1 || myStartOffset2 > myEndOffset2) {
			trace("DiffFragmentImpl is invalid: " + toString());
		}
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

	public function toString():String {
		return "DiffFragmentImpl [" + myStartOffset1 + ", " + myEndOffset1 + ") - [" + myStartOffset2 + ", " + myEndOffset2 + ")";
	}
}
