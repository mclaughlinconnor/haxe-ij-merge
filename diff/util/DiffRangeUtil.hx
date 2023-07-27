// Copyright 2000-2022 JetBrains s.r.o. and contributors. Use of this source code is governed by the Apache 2.0 license.
package diff.util;

import diff.tools.util.text.LineOffsets;
import ds.TextRange;

class DiffRangeUtil {
	public static function getLinesContent(sequence:String, lineOffsets:LineOffsets, line1:Int, line2:Int, ?includeNewline:Bool = false) {
		// assert sequence.length() == lineOffsets.getTextLength();
		return getLinesRange(lineOffsets, line1, line2, includeNewline).subSequence(sequence);
	}

	public static function getLinesRange(lineOffsets:LineOffsets, line1:Int, line2:Int, includeNewline:Bool):TextRange {
		if (line1 == line2) {
			var lineStartOffset:Int = line1 < lineOffsets.getLineCount() ? lineOffsets.getLineStart(line1) : lineOffsets.getTextLength();
			return new TextRange(lineStartOffset, lineStartOffset);
		} else {
			var startOffset:Int = lineOffsets.getLineStart(line1);
			var endOffset:Int = lineOffsets.getLineEnd(line2 - 1);
			if (includeNewline && endOffset < lineOffsets.getTextLength()) {
				endOffset++;
			}
			return new TextRange(startOffset, endOffset);
		}
	}

	public static function getLines(text:String, lineOffsets:LineOffsets, ?sl:Null<Int>, ?el:Null<Int>):Array<String> {
		final startLine = sl == null ? 0 : sl;
		final endLine = el == null ? 0 : el;

		if (startLine < 0 || startLine > endLine || endLine > lineOffsets.getLineCount()) {
			throw new IndexOutOfBoundsException(String.format("Wrong line range: [%d, %d); lineCount: '%d'", startLine, endLine, lineOffsets.getLineCount()));
		}

		var result:Array<String> = new Array();
		for (i in startLine...endLine) {
			var start:Int = lineOffsets.getLineStart(i);
			var end:Int = lineOffsets.getLineEnd(i);
			result.add(text.subSequence(start, end).toString());
		}
		return result;
	}
}
