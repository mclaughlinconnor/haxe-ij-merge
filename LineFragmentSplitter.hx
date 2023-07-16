// Copyright 2000-2021 JetBrains s.r.o. and contributors. Use of this source code is governed by the Apache 2.0 license.

/*
 * Given matchings on words, split initial line block into 'logically different' line blocks
 */
class LineFragmentSplitter {
	private final myText1:String;
	private final myText2:String;

	private final myWords1:Array<InlineChunk>;
	private final myWords2:Array<InlineChunk>;
	private final myIterable:FairDiffIterable;

	private final myResult:Array<WordBlock> = new Array();

	public function new(text1:String, text2:String, words1:Array<InlineChunk>, words2:Array<InlineChunk>, iterable:FairDiffIterable) {
		this.myText1 = text1;
		this.myText2 = text2;
		this.myWords1 = words1;
		this.myWords2 = words2;
		this.myIterable = iterable;
	}

	private var last1:Int = -1;
	private var last2:Int = -1;
	private var pendingChunk:PendingChunk = null;

	// indexes here are a bit tricky
	// -1 - the beginning of file, words.length - end of file, everything in between - InlineChunks (words or newlines)

	public function run():Array<WordBlock> {
		var hasEqualWords:Bool = false;
		for (range in myIterable.iterateUnchanged()) {
			var count:Int = range.end1 - range.start1;
			for (i in 0...count) {
				var index1:Int = range.start1 + i;
				var index2:Int = range.start2 + i;

				if (isNewline(myWords1, index1) && isNewline(myWords2, index2)) { // split by matched newlines
					addLineChunk(index1, index2, hasEqualWords);
					hasEqualWords = false;
				} else {
					if (isFirstInLine(myWords1, index1) && isFirstInLine(myWords2, index2)) { // split by matched first word in line
						addLineChunk(index1 - 1, index2 - 1, hasEqualWords);
						hasEqualWords = false;
					}
					// TODO: split by 'last word in line' + 'last word in whole sequence' ?
					hasEqualWords = true;
				}
			}
		}
		addLineChunk(myWords1.length, myWords2.length, hasEqualWords);

		if (pendingChunk != null) {
			myResult.push(pendingChunk.block);
		}

		return myResult;
	}

	private function addLineChunk(end1:Int, end2:Int, hasEqualWords:Bool):Void {
		if (last1 > end1 || last2 > end2) {
			return;
		}

		var chunk:PendingChunk = createChunk(last1, last2, end1, end2, hasEqualWords);
		if (chunk.block.offsets.isEmpty()) {
			return;
		}

		if (pendingChunk != null && shouldMergeChunks(pendingChunk, chunk)) {
			pendingChunk = mergeChunks(pendingChunk, chunk);
		} else {
			if (pendingChunk != null)
				myResult.push(pendingChunk.block);
			pendingChunk = chunk;
		}

		last1 = end1;
		last2 = end2;
	}

	private function createChunk(start1:Int, start2:Int, end1:Int, end2:Int, hasEqualWords:Bool):PendingChunk {
		var startOffset1:Int = getOffset(myWords1, myText1, start1);
		var startOffset2:Int = getOffset(myWords2, myText2, start2);
		var endOffset1:Int = getOffset(myWords1, myText1, end1);
		var endOffset2:Int = getOffset(myWords2, myText2, end2);

		start1 = Std.int(Math.max(0, start1 + 1));
		start2 = Std.int(Math.max(0, start2 + 1));
		end1 = Std.int(Math.min(end1 + 1, myWords1.length));
		end2 = Std.int(Math.min(end2 + 1, myWords2.length));

		var block:WordBlock = new WordBlock(new Range(start1, end1, start2, end2), new Range(startOffset1, endOffset1, startOffset2, endOffset2));

		return new PendingChunk(block, hasEqualWords, hasWordsInside(block), isEqualsIgnoreWhitespace(block));
	}

	private static function shouldMergeChunks(chunk1:PendingChunk, chunk2:PendingChunk):Bool {
		// combine lines, that matched only by '\n'
		if (!chunk1.hasEqualWords && !chunk2.hasEqualWords) {
			return true;
		}

		if (chunk1.isEqualIgnoreWhitespaces && chunk2.isEqualIgnoreWhitespaces) {
			return true; // combine whitespace-only changed lines
		}

		// squash block without words in it
		if (!chunk1.hasWordsInside || !chunk2.hasWordsInside) {
			return true;
		}

		return false;
	}

	private static function mergeChunks(chunk1:PendingChunk, chunk2:PendingChunk):PendingChunk {
		var block1:WordBlock = chunk1.block;
		var block2:WordBlock = chunk2.block;
		var newBlock:WordBlock = new WordBlock(new Range(block1.words.start1, block2.words.end1, block1.words.start2, block2.words.end2),
			new Range(block1.offsets.start1, block2.offsets.end1, block1.offsets.start2, block2.offsets.end2));
		return
			new PendingChunk(newBlock, chunk1.hasEqualWords || chunk2.hasEqualWords, chunk1.hasWordsInside || chunk2.hasWordsInside, chunk1.isEqualIgnoreWhitespaces && chunk2.isEqualIgnoreWhitespaces);
	}

	private function isEqualsIgnoreWhitespace(block:WordBlock):Bool {
		var sequence1:String = myText1.substring(block.offsets.start1, block.offsets.end1);
		var sequence2:String = myText2.substring(block.offsets.start2, block.offsets.end2);
		return ComparisonUtil.isEquals(sequence1, sequence2, ComparisonPolicy.IGNORE_WHITESPACES);
	}

	private function hasWordsInside(block:WordBlock):Bool {
		for (i in block.words.start1...block.words.end1) {
			if (Std.downcast(myWords1[i], NewlineChunk) == null) {
				return true;
			}
		}
		for (i in block.words.start2...block.words.end2) {
			if (Std.downcast(myWords2[i], NewlineChunk) == null) {
				return true;
			}
		}
		return false;
	}

	private static function getOffset(words:Array<InlineChunk>, text:String, index:Int):Int {
		if (index == -1) {
			return 0;
		}
		if (index == words.length) {
			return text.length;
		}
		var chunk:InlineChunk = words[index];
		// assert chunk instanceof NewlineChunk;
		return chunk.getOffset2();
	}

	private static function isNewline(words1:Array<InlineChunk>, index:Int):Bool {
		return Std.downcast(words1[index], NewlineChunk) != null;
	}

	private static function isFirstInLine(words1:Array<InlineChunk>, index:Int):Bool {
		if (index == 0) {
			return true;
		}
		return Std.downcast(words1[index - 1], NewlineChunk) != null;
	}
}

//
// Helpers
//

class WordBlock {
	public final words:Range;
	public final offsets:Range;

	public function new(words:Range, offsets:Range) {
		this.words = words;
		this.offsets = offsets;
	}
}

class PendingChunk {
	public final block:WordBlock;
	public final hasEqualWords:Bool;
	public final hasWordsInside:Bool;
	public final isEqualIgnoreWhitespaces:Bool;

	public function new(block:WordBlock, hasEqualWords:Bool, hasWordsInside:Bool, isEqualIgnoreWhitespaces:Bool) {
		this.block = block;
		this.hasEqualWords = hasEqualWords;
		this.hasWordsInside = hasWordsInside;
		this.isEqualIgnoreWhitespaces = isEqualIgnoreWhitespaces;
	}
}
