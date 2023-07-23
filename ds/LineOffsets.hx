// Copyright 2000-2021 JetBrains s.r.o. and contributors. Use of this source code is governed by the Apache 2.0 license.
package ds;

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
