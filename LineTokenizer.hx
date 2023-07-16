// Copyright 2000-2021 JetBrains s.r.o. and contributors. Use of this source code is governed by the Apache 2.0 license.
class LineTokenizer {
	private var myOffset:Int;
	private var myLength:Int;
	private var myLineSeparatorLength:Int;
	private var isAtEnd:Bool;
	private final myText:String;

	static public function tokenizeA(chars:String, includeSeparators:Bool):Array<String> {
		return tokenizeB(chars, includeSeparators, true);
	}

	static public function tokenizeB(chars:String, includeSeparators:Bool, skipLastEmptyLine:Bool):Array<String> {
		return tokenizeIntoListB(chars, includeSeparators, skipLastEmptyLine);
	}

	static public function tokenizeIntoListA(chars:String, includeSeparators:Bool):Array<String> {
		return tokenizeIntoListB(chars, includeSeparators, true);
	}

	static public function tokenizeIntoListB(chars:String, includeSeparators:Bool, skipLastEmptyLine:Bool):Array<String> {
		if (chars == null || chars.length == 0) {
			return new Array();
		}

		var tokenizer:LineTokenizer = new LineTokenizer(chars);
		var lines:Array<String> = new Array();
		while (!tokenizer.atEnd()) {
			var offset:Int = tokenizer.getOffset();
			var line:String;
			if (includeSeparators) {
				line = chars.substring(offset, offset + tokenizer.getLength() + tokenizer.getLineSeparatorLength()).toString();
			} else {
				line = chars.substring(offset, offset + tokenizer.getLength()).toString();
			}
			lines.push(line);
			tokenizer.advance();
		}

		if (!skipLastEmptyLine && stringEndsWithSeparator(tokenizer)) {
			lines.push("");
		}

		return lines;
	}

	static public function calcLineCount(chars:String, skipLastEmptyLine:Bool):Int {
		var lineCount:Int = 0;
		if (chars.length != 0) {
			final tokenizer:LineTokenizer = new LineTokenizer(chars);

			while (!tokenizer.atEnd()) {
				lineCount += 1;
				tokenizer.advance();
			}
			if (!skipLastEmptyLine && stringEndsWithSeparator(tokenizer)) {
				lineCount += 1;
			}
		}
		return lineCount;
	}

	static public function tokenizeC(chars:Array<String>, includeSeparators:Bool):Array<String> {
		return tokenizeD(chars, includeSeparators, true);
	}

	static public function tokenizeD(chars:Array<String>, includeSeparators:Bool, skipLastEmptyLine:Bool):Array<String> {
		return tokenizeE(chars, 0, chars.length, includeSeparators, skipLastEmptyLine);
	}

	static public function tokenizeE(chars:Array<String>, startOffset:Int, endOffset:Int, includeSeparators:Bool, skipLastEmptyLine:Bool):Array<String> {
		return tokenizeD(chars.splice(startOffset, startOffset + endOffset), includeSeparators, skipLastEmptyLine);
	}

	private static function stringEndsWithSeparator(tokenizer:LineTokenizer):Bool {
		return tokenizer.getLineSeparatorLength() > 0;
	}

	static public function tokenizeF(chars:Array<String>, startOffset:Int, endOffset:Int, includeSeparators:Bool):Array<String> {
		return tokenizeE(chars, startOffset, endOffset, includeSeparators, true);
	}

	public function new(text:String) {
		myText = text;
		myOffset = 0;
		advance();
	}

	public function atEnd():Bool {
		return isAtEnd;
	}

	public function getOffset():Int {
		return myOffset;
	}

	public function getLength():Int {
		return myLength;
	}

	public function getLineSeparatorLength():Int {
		return myLineSeparatorLength;
	}

	public function advance():Void {
		var i:Int = myOffset + myLength + myLineSeparatorLength;
		final textLength:Int = myText.length;
		if (i >= textLength) {
			isAtEnd = true;
			return;
		}
		while (i < textLength) {
			var c:String = myText.charAt(i);
			if (c == '\r' || c == '\n')
				break;
			i++;
		}

		myOffset += myLength + myLineSeparatorLength;
		myLength = i - myOffset;

		myLineSeparatorLength = 0;
		if (i == textLength) {
			return;
		}

		var first:String = myText.charAt(i);
		if (first == '\r' || first == '\n') {
			myLineSeparatorLength = 1;
		}

		i++;
		if (i == textLength) {
			return;
		}

		var second:String = myText.charAt(i);
		if (first == '\r' && second == '\n') {
			myLineSeparatorLength = 2;
		}
	}
}
