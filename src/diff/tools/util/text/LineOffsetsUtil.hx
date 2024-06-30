// Copyright 2000-2021 JetBrains s.r.o. Use of this source code is governed by the Apache 2.0 license that can be found in the LICENSE file.
package diff.tools.util.text;

import diff.tools.util.text.LineOffsets.LineOffsetsImpl;

class LineOffsetsUtil {
	// public static function createA(document:Document):LineOffsets {
	// 	return new LineOffsetsDocumentWrapper(document);
	// }

	/**
	 * NB: Does not support CRLF separators, use {@link com.intellij.openapi.util.text.StringUtil#convertLineSeparators}.
	 */
	public static function createB(text:String):LineOffsets {
		return LineOffsetsImpl.create(text);
	}
}
