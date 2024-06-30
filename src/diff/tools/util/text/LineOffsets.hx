// Copyright 2000-2021 JetBrains s.r.o. and contributors. Use of this source code is governed by the Apache 2.0 license.
package diff.tools.util.text;

import util.diff.Reindexer.binarySearch;
import exceptions.IndexOutOfBoundsException;

interface LineOffsets {
	public function getLineStart(line:Int):Int;

	/**
	 * includeNewline = false
	 */
	public function getLineEndA(line:Int):Int;

	public function getLineEndB(line:Int, includeNewline:Bool):Int;

	public function getLineNumber(offset:Int):Int;

	public function getLineCount():Int;

	public function getTextLength():Int;
}

class LineOffsetsImpl implements LineOffsets {
	public static function create(text:String):LineOffsets {
		var ends:Array<Int> = [];

		var index:Int = 0;
		while (true) {
			var lineEnd:Int = text.indexOf('\n', index);
			if (lineEnd != -1) {
				ends.push(lineEnd);
				index = lineEnd + 1;
			} else {
				ends.push(text.length);
				break;
			}
		}

		return new LineOffsetsImpl(ends, text.length);
	}

	private final myLineEnds:Array<Int>;

	private final myTextLength:Int;

	private function new(lineEnds: Array<Int>, textLength: Int ) {
		myLineEnds = lineEnds;
		myTextLength = textLength;
	}

	public function getLineStart(line:Int):Int {
		checkLineIndex(line);
		if (line == 0) {
			return 0;
		}
		return myLineEnds[line - 1] + 1;
	}

	public function getLineEndA(line:Int):Int {
		checkLineIndex(line);
		return myLineEnds[line];
	}

	public function getLineEndB(line:Int, includeNewline:Bool):Int {
		checkLineIndex(line);
		return myLineEnds[line] + (includeNewline && line != myLineEnds.length - 1 ? 1 : 0);
	}

	public function getLineNumber(offset:Int):Int {
		if (offset < 0 || offset > getTextLength()) {
			throw new IndexOutOfBoundsException("Wrong offset: " + offset + ". Available text length: " + getTextLength());
		}
		if (offset == 0) {
			return 0;
		}
		if (offset == getTextLength()) {
			return getLineCount() - 1;
		}

		var bsResult:Int = binarySearch(myLineEnds, offset);
		return bsResult >= 0 ? bsResult : -bsResult - 1;
	}

	public function getLineCount():Int {
		return myLineEnds.length;
	}

	public function getTextLength():Int {
		return myTextLength;
	}

	private function checkLineIndex(index:Int):Void {
		if (index < 0 || index >= getLineCount()) {
			throw new IndexOutOfBoundsException("Wrong line: " + index + ". Available lines count: " + getLineCount());
		}
	}
}
