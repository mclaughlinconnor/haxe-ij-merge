class ByWordRt {
	static function compareA(text1:String, text2:String, policy:ComparisonPolicy):List<DiffFragment> {
		var words1:List<InlineChunk> = getInlineChunks(text1);
		var words2:List<InlineChunk> = getInlineChunks(text2);

    // TODO: check naming and how overloading works
		return compareB(text1, words1, text2, words2, policy);
	}

	static function compareB(text1:String, words1:List<InlineChunk>, text2:String, words2:List<InlineChunk>, policy:ComparisonPolicy):List<DiffFragment> {
		var delimitersIterable:FairDiffIterable = matchAdjustmentDelimitersA(text1, text2, words1, words2, wordChanges);
		var iterable:DiffIterable = matchAdjustmentWhitespacesA(text1, text2, delimitersIterable, policy);

		return convertIntoDiffFragments(iterable);
	}

	static function compareC(text1:String, text2:String, text3:String, policy:ComparisonPolicy):List<MergeWordFragment> {
		var words1:List<InlineChunk> = getInlineChunks(text1);
		var words2:List<InlineChunk> = getInlineChunks(text2);
		var words3:List<InlineChunk> = getInlineChunks(text3);

		var wordChanges1:FairDiffIterable = diff(words2, words1);
		wordChanges1 = optimizeWordChunks(text2, text1, words2, words1, wordChanges1);
		var iterable1:FairDiffIterable = matchAdjustmentDelimitersA(text2, text1, words2, words1, wordChanges1);

		var wordChanges2:FairDiffIterable = diff(words2, words3);
		wordChanges2 = optimizeWordChunks(text2, text3, words2, words3, wordChanges2);
		var iterable2:FairDiffIterable = matchAdjustmentDelimitersA(text2, text3, words2, words3, wordChanges2);

		var wordConflicts:List<MergeRange> = ComparisonMergeUtil.buildSimple(iterable1, iterable2);
		var result:List<MergeRange> = matchAdjustmentWhitespacesA(text1, text2, text3, wordConflicts, policy);

		return convertIntoMergeWordFragments(result);
	}

	static function compareAndSplit(text1:String, text2:String, policy:ComparisonPolicy):List<LineBlock> {
		// TODO: figure out, what do we exactly want from 'Split' logic
		// -- it is used for trimming of ignored blocks. So we want whitespace-only leading/trailing lines to be separate block.
		// -- old approach: split by matched '\n's

		// TODO: other approach could lead to better results:
		// * Compare words-only
		// * prefer big chunks
		// -- here we can try to minimize number of matched pairs 'pair[i]' and 'pair[i+1]' such that
		//    containsNewline(pair[i].left .. pair[i+1].left) XOR containsNewline(pair[i].right .. pair[i+1].right) == true
		//    ex: "A X C" - "A Y C \n M C" - do not match with last 'C'
		//    ex: "A \n" - "A B \n \n" - do not match with last '\n'
		//    Try some greedy approach ?
		// * split into blocks
		// -- squash blocks with too small unchanged words count (1 matched word out of 40 - is a bad reason to create new block)
		// * match adjustment punctuation
		// * match adjustment whitespaces ('\n' are matched here)

		var words1:List<InlineChunk> = getInlineChunks(text1);
		var words2:List<InlineChunk> = getInlineChunks(text2);

		var wordChanges:FairDiffIterable = diff(words1, words2);
		wordChanges = optimizeWordChunks(text1, text2, words1, words2, wordChanges);

		var wordBlocks:List<WordBlock> = new LineFragmentSplitter(text1, text2, words1, words2, wordChanges).run();

		var subIterables:List<FairDiffIterable> = collectWordBlockSubIterables(wordChanges, wordBlocks);

		var lineBlocks:List<LineBlock> = new ArrayList(wordBlocks.size());
		for (i in 0..wordBlocks.size() - 1) {
			var block:WordBlock = wordBlocks.get(i);
			var offsets:Range = block.offsets;
			var words:Range = block.words;

			var subtext1:String = text1.subSequence(offsets.start1, offsets.end1);
			var subtext2:String = text2.subSequence(offsets.start2, offsets.end2);

			var subwords1:List<InlineChunk> = words1.subList(words.start1, words.end1);
			var subwords2:List<InlineChunk> = words2.subList(words.start2, words.end2);

			var subiterable:FairDiffIterable = subIterables.get(i);

			var delimitersIterable:FairDiffIterable = matchAdjustmentDelimiters(subtext1, subtext2, subwords1, subwords2, subiterable, offsets.start1,
				offsets.start2);
			var iterable:DiffIterable = matchAdjustmentWhitespaces(subtext1, subtext2, delimitersIterable, policy);

			var fragments:List<DiffFragment> = convertIntoDiffFragments(iterable);

			var newlines1:Int = countNewlines(subwords1);
			var newlines2:Int = countNewlines(subwords2);

			lineBlocks.add(new LineBlock(fragments, offsets, newlines1, newlines2));
		}

		return lineBlocks;
	}

	private static function collectWordBlockSubIterables(wordChanges:FairDiffIterable, wordBlocks:List<WordBlock>):List<FairDiffIterable> {
		var changed:List<Range> = new ArrayList();

		for (range in wordChanges.iterateChanges()) {
			changed.add(range);
		}
		var index = 0;

		var subIterables:List<FairDiffIterable> = new ArrayList(wordBlocks.size());
		for (block in wordBlocks) {
			var words:Range = block.words;

			while (index < changed.size()) {
				var range:Range = changed.get(index);

				if (range.end1 < words.start1 || range.end2 < words.start2) {
					index++;
					continue;
				}
				break;
			}
			subIterables.add(fair(new SubiterableDiffIterable(changed, words.start1, words.end1, words.start2, words.end2, index)));
		}
		return subIterables;
	}

	//
	// Impl
	//
	private static function optimizeWordChunks(text1:String, text2:String, words1:List<InlineChunk>, words2:List<InlineChunk>,
			iterable:FairDiffIterable):FairDiffIterable {
		return new ChunkOptimizer.WordChunkOptimizer(words1, words2, text1, text2, iterable).build();
	}

	private static function matchAdjustmentDelimitersA(text1:String, text2:String, words1:List<InlineChunk>, words2:List<InlineChunk>,
			changes:FairDiffIterable):FairDiffIterable {
		return matchAdjustmentDelimiters(text1, text2, words1, words2, changes, 0, 0);
	}

	private static function matchAdjustmentDelimitersB(text1:String, text2:String, words1:List<InlineChunk>, words2:List<InlineChunk>,
			changes:FairDiffIterable, startShift1:Int, startShift2:Int):FairDiffIterable {
		return new AdjustmentPunctuationMatcher(text1, text2, words1, words2, startShift1, startShift2, changes).build();
	}

	private static function matchAdjustmentWhitespacesA(text1:String, text2:String, iterable:FairDiffIterable, policy:ComparisonPolicy):DiffIterable {
		switch (policy) {
			case DEFAULT:
				return new DefaultCorrector(iterable, text1, text2).build();
			case TRIM_WHITESPACES:
				var defaultIterable:DiffIterable = new DefaultCorrector(iterable, text1, text2).build();
				return new TrimSpacesCorrector(defaultIterable, text1, text2).build();
			case IGNORE_WHITESPACES:
				return new IgnoreSpacesCorrector(iterable, text1, text2).build();
			default:
				throw new IllegalArgumentException(policy.name());
		}
	}

	private static function matchAdjustmentWhitespacesB(text1:String, text2:String, text3:String, conflicts:List<MergeRange>,
			policy:ComparisonPolicy):List<MergeRange> {
		switch (policy) {
			case DEFAULT:
				return new MergeDefaultCorrector(conflicts, text1, text2, text3).build();
			case TRIM_WHITESPACES:
				List<MergeRange>defaultConflicts = new MergeDefaultCorrector(conflicts, text1, text2, text3).build();
				return new MergeTrimSpacesCorrector(defaultConflicts, text1, text2, text3).build();
			case IGNORE_WHITESPACES:
				return new MergeIgnoreSpacesCorrector(conflicts, text1, text2, text3).build();
			default:
				throw new IllegalArgumentException(policy.name());
		}
	}

	static function convertIntoMergeWordFragments(conflicts:List<MergeRange>):List<MergeWordFragment> {
		// noinspection SSBasedInspection - Can't use ContainerUtil
		return conflicts.stream().map(ch -> new MergeWordFragmentImpl(ch)).collect(Collectors.toList());
	}

	static function convertIntoDiffFragments(changes:DiffIterable):List<DiffFragment> {
		var fragments:List<DiffFragment> = new ArrayList();
		for (ch in changes.iterateChanges()) {
			fragments.add(new DiffFragmentImpl(ch.start1, ch.end1, ch.start2, ch.end2));
		}
		return fragments;
	}

	/*
	 * Compare one char sequence with two others (as if they were single sequence)
	 *
	 * Return two DiffIterable: (0, len1) - (0, len21) and (0, len1) - (0, len22)
	 */
	private static function comparePunctuation2Side(text1:String, text21:String, text22:String):Couple<FairDiffIterable> {
		var text2:String = new MergingCharSequence(text21, text22);
		var changes:FairDiffIterable = ByCharRt.comparePunctuation(text1, text2);

		var ranges:Couple<List<Range>> = splitIterable2Side(changes, text21.length());

		var iterable1:FairDiffIterable = fair(createUnchanged(ranges.first, text1.length(), text21.length()));
		var iterable2:FairDiffIterable = fair(createUnchanged(ranges.second, text1.length(), text22.length()));

		return Couple.of(iterable1, iterable2);
	}

	private static function splitIterable2Side(changes:FairDiffIterable, offset:Int):Couple<List<Range>> {
		var ranges1:List<Range>;
		ranges1 = new ArrayList();
		var ranges2:List<Range>;
		ranges2 = new ArrayList();

		for (ch in changes.iterateUnchanged()) {
			if (ch.end2 <= offset) {
				ranges1.add(new Range(ch.start1, ch.end1, ch.start2, ch.end2));
			} else if (ch.start2 >= offset) {
				ranges2.add(new Range(ch.start1, ch.end1, ch.start2 - offset, ch.end2 - offset));
			} else {
				var len2:Int = offset - ch.start2;
				ranges1.add(new Range(ch.start1, ch.start1 + len2, ch.start2, offset));
				ranges2.add(new Range(ch.start1 + len2, ch.end1, 0, ch.end2 - offset));
			}
		}
		return Couple.of(ranges1, ranges2);
	}

	static function isWordChunk(chunk:InlineChunk):Boolean {
		return Std.downcast(chunk, WordChunk);
	}

	//
	// Whitespaces matching
	//
	private static function isLeadingTrailingSpace(text:String, start:Int):Boolean {
		return isLeadingSpace(text, start) || isTrailingSpace(text, start);
	}

	private static function isLeadingSpace(text:String, start:Int):Boolean {
		if (start < 0)
			return false;
		if (start == text.length())
			return false;
		if (!isWhiteSpace(text.charAt(start)))
			return false;
		start--;
		while (start >= 0) {
			var c:String = text.charAt(start);
			if (c == '\n')
				return true;
			if (!isWhiteSpace(c))
				return false;
			start--;
		}
		return true;
	}

	private static function isTrailingSpace(text:String, end:Int):Boolean {
		if (end < 0)
			return false;
		if (end == text.length())
			return false;
		if (!isWhiteSpace(text.charAt(end)))
			return false;
		while (end < text.length()) {
			var c = text.charAt(end);

			if (c == '\n')
				return true;
			if (!isWhiteSpace(c))
				return false;
			end++;
		}
		return true;
	}

	//
	// Misc
	//
	private static function countNewlines(words:List<InlineChunk>):Int {
		var count = 0;
		for (word in words) {
			if (Std.downcast(word, NewlineChunk)) {
				count++;
			}
		}
		return count;
	}

	static function getInlineChunks(text:String):List<InlineChunk> {
		var chunks:List<InlineChunk> = new ArrayList();

		var len:Int = text.length();
		var offset:Int = 0;

		var wordStart:Int = -1;
		var wordHash:Int = 0;

		while (offset < len) {
			var ch:Int = Character.codePointAt(text, offset);
			var charCount:Int = Character.charCount(ch);

			var isAlpha:Boolean = isAlpha(ch);
			var isWordPart:Boolean = isAlpha && !isContinuousScript(ch);

			if (isWordPart) {
				if (wordStart == -1) {
					wordStart = offset;
					wordHash = 0;
				}
				wordHash = wordHash * 31 + ch;
			} else {
				if (wordStart != -1) {
					chunks.add(new WordChunk(text, wordStart, offset, wordHash));
					wordStart = -1;
				}

				if (isAlpha) { // continuous script
					chunks.add(new WordChunk(text, offset, offset + charCount, ch));
				} else if (ch == '\n') {
					chunks.add(new NewlineChunk(offset));
				}
			}

			offset += charCount;
		}

		if (wordStart != -1) {
			chunks.add(new WordChunk(text, wordStart, len, wordHash));
		}

		return chunks;
	}
}

//
// Helpers
//
class WordChunk implements InlineChunk {
	private var myText:String;
	private var myOffset1:Int;
	private var myOffset2:Int;
	private var myHash:Int;

	public function WordChunk(text:String, offset1:Int, offset2:Int, hash:Int) {
		myText = text;
		myOffset1 = offset1;
		myOffset2 = offset2;
		myHash = hash;
	}

	public function getContent():String {
		return myText.subSequence(myOffset1, myOffset2);
	}

	public function getOffset1():Int {
		return myOffset1;
	}

	public function getOffset2():Int {
		return myOffset2;
	}

	public function equals(o:Object):Boolean {
		if (this == o)
			return true;
		if (o == null || getClass() != o.getClass())
			return false;

		var word:WordChunk = cast(o, WordChunk);

		if (myHash != word.myHash)
			return false;

		return ComparisonUtil.isEquals(getContent(), word.getContent(), ComparisonPolicy.DEFAULT);
	}

	public function hashCode():Int {
		return myHash;
	}
}

class NewlineChunk implements InlineChunk {
	private var myOffset:Int;

	public function new(offset:Int) {
		myOffset = offset;
	}

	public function getOffset1():Int {
		return myOffset;
	}

	public function getOffset2():Int {
		return myOffset + 1;
	}

	public function equals(o:Object):Boolean {
		if (this == o)
			return true;
		if (o == null || getClass() != o.getClass())
			return false;

		return true;
	}

	public function hashCode():Int {
		return getClass().hashCode();
	}
}

class LineBlock {
	public static var fragments:List<DiffFragment>;

	public static var offsets:Range;

	public static var newlines1:Int;
	public static var newlines2:Int;

	public function new(fragments:List<DiffFragment>, offsets:Range, newlines1:Int, newlines2:Int) {
		this.fragments = fragments;
		this.offsets = offsets;
		this.newlines1 = newlines1;
		this.newlines2 = newlines2;
	}
}

class DefaultCorrector {
	private var myIterable:DiffIterable;
	private var myText1:String;
	private var myText2:String;

	private var myChanges:List<Range>;

	public function new(iterable:DiffIterable, text1:String, text2:String) {
		myIterable = iterable;
		myText1 = text1;
		myText2 = text2;

		myChanges = new ArrayList();
	}

	public function build():DiffIterable {
		for (range in myIterable.iterateChanges()) {
			var endCut:Int = expandWhitespacesBackward(myText1, myText2, range.start1, range.start2, range.end1, range.end2);
			var startCut:Int = expandWhitespacesForward(myText1, myText2, range.start1, range.start2, range.end1 - endCut, range.end2 - endCut);

			var expand:Range = new Range(range.start1 + startCut, range.end1 - endCut, range.start2 + startCut, range.end2 - endCut);

			if (!expand.isEmpty()) {
				myChanges.add(expand);
			}
		}

		return create(myChanges, myText1.length(), myText2.length());
	}
}

class MergeDefaultCorrector {
	private var myIterable:List<MergeRange>;
	private var myText1:String;
	private var myText2:String;
	private var myText3:String;

	private var myChanges:List<MergeRange>;

	public function new(iterable:List<MergeRange>, text1:String, text2:String, text3:String) {
		myIterable = iterable;
		myText1 = text1;
		myText2 = text2;
		myText3 = text3;

		myChanges = new ArrayList();
	}

	public function build():List<MergeRange> {
		for (range in myIterable) {
			var endCut:Int = expandWhitespacesBackward(myText1, myText2, myText3, range.start1, range.start2, range.start3, range.end1, range.end2,
				range.end3);
			var startCut:Int = expandWhitespacesForward(myText1, myText2, myText3, range.start1, range.start2, range.start3, range.end1
				- endCut,
				range.end2
				- endCut, range.end3
				- endCut);

			var expand:MergeRange = new MergeRange(range.start1
				+ startCut, range.end1
				- endCut, range.start2
				+ startCut, range.end2
				- endCut,
				range.start3
				+ startCut, range.end3
				- endCut);

			if (!expand.isEmpty()) {
				myChanges.add(expand);
			}
		}

		return myChanges;
	}
}

class IgnoreSpacesCorrector {
	private var myIterable:DiffIterable;
	private var myText1:String;
	private var myText2:String;

	private var myChanges:List<Range>;

	public function new(iterable:DiffIterable, text1:String, text2:String) {
		myIterable = iterable;
		myText1 = text1;
		myText2 = text2;

		myChanges = new ArrayList();
	}

	public function build():DiffIterable {
		for (range in myIterable.iterateChanges()) {
			// match spaces if we can, ignore them if we can't
			var expanded:Range = expandWhitespaces(myText1, myText2, range);
			var trimmed:Range = trim(myText1, myText2, expanded);

			if (!trimmed.isEmpty() && !isEqualsIgnoreWhitespaces(myText1, myText2, trimmed)) {
				myChanges.add(trimmed);
			}
		}

		return create(myChanges, myText1.length(), myText2.length());
	}
}

class MergeIgnoreSpacesCorrector {
	private var myIterable:List<MergeRange>;
	private var myText1:String;
	private var myText2:String;
	private var myText3:String;

	private var myChanges:List<MergeRange>;

	public function new(iterable:List<MergeRange>, text1:String, text2:String, text3:String) {
		myIterable = iterable;
		myText1 = text1;
		myText2 = text2;
		myText3 = text3;

		myChanges = new ArrayList();
	}

	public function build():List<MergeRange> {
		for (range in myIterable) {
			var expanded:MergeRange = expandWhitespaces(myText1, myText2, myText3, range);
			var trimmed:MergeRange = trim(myText1, myText2, myText3, expanded);

			if (!trimmed.isEmpty() && !isEqualsIgnoreWhitespaces(myText1, myText2, myText3, trimmed)) {
				myChanges.add(trimmed);
			}
		}

		return myChanges;
	}
}

class TrimSpacesCorrector {
	private var myIterable:DiffIterable;
	private var myText1:String;
	private var myText2:String;

  // TODO: is dynamic?
	private var myChanges:List<Range<Dynamic>>;

	public function new(iterable:DiffIterable, text1:String, text2:String) {
		myIterable = iterable;
		myText1 = text1;
		myText2 = text2;

		myChanges = new ArrayList();
	}

	public function build():DiffIterable {
		for (range in myIterable.iterateChanges()) {
			var start1:Int = range.start1;
			var start2:Int = range.start2;
			var end1:Int = range.end1;
			var end2:Int = range.end2;

			if (isLeadingTrailingSpace(myText1, start1)) {
				start1 = trimStart(myText1, start1, end1);
			}
			if (isLeadingTrailingSpace(myText1, end1 - 1)) {
				end1 = trimEnd(myText1, start1, end1);
			}
			if (isLeadingTrailingSpace(myText2, start2)) {
				start2 = trimStart(myText2, start2, end2);
			}
			if (isLeadingTrailingSpace(myText2, end2 - 1)) {
				end2 = trimEnd(myText2, start2, end2);
			}

			var trimmed:Range = new Range(start1, end1, start2, end2);

			if (!trimmed.isEmpty() && !isEquals(myText1, myText2, trimmed)) {
				myChanges.add(trimmed);
			}
		}

		return create(myChanges, myText1.length(), myText2.length());
	}
}

class MergeTrimSpacesCorrector {
	private var myIterable:List<MergeRange>;
	private var myText1:String;
	private var myText2:String;
	private var myText3:String;

	private var myChanges:List<MergeRange>;

	public function new(iterable:List<MergeRange>, text1:String, text2:String, text3:String) {
		myIterable = iterable;
		myText1 = text1;
		myText2 = text2;
		myText3 = text3;

		myChanges = new ArrayList();
	}

	public function build():List<MergeRange> {
		for (range in myIterable) {
			var start1:Int = range.start1;
			var start2:Int = range.start2;
			var start3:Int = range.start3;
			var end1:Int = range.end1;
			var end2:Int = range.end2;
			var end3:Int = range.end3;

			if (isLeadingTrailingSpace(myText1, start1)) {
				start1 = trimStart(myText1, start1, end1);
			}
			if (isLeadingTrailingSpace(myText1, end1 - 1)) {
				end1 = trimEnd(myText1, start1, end1);
			}
			if (isLeadingTrailingSpace(myText2, start2)) {
				start2 = trimStart(myText2, start2, end2);
			}
			if (isLeadingTrailingSpace(myText2, end2 - 1)) {
				end2 = trimEnd(myText2, start2, end2);
			}
			if (isLeadingTrailingSpace(myText3, start3)) {
				start3 = trimStart(myText3, start3, end3);
			}
			if (isLeadingTrailingSpace(myText3, end3 - 1)) {
				end3 = trimEnd(myText3, start3, end3);
			}

			var trimmed:MergeRange = new MergeRange(start1, end1, start2, end2, start3, end3);

			if (!trimmed.isEmpty() && !isEquals(myText1, myText2, myText3, trimmed)) {
				myChanges.add(trimmed);
			}
		}

		return myChanges;
	}
}

interface InlineChunk {
	public function getOffset1():Int;

	public function getOffset2():Int;
}

//
// Punctuation matching
//

/*
 * sample: "[ X { A ! B } Y ]" "( X ... Y )" will lead to comparison of 3 groups of separators
 *      "["  vs "(",
 *      "{" + "}" vs "..."
 *      "]"  vs ")"
 */
class AdjustmentPunctuationMatcher {
	private var myText1:String;
	private var myText2:String;
	private var myWords1:List<InlineChunk>;
	private var myWords2:List<InlineChunk>;
	private var myChanges:FairDiffIterable;
	private var myStartShift1:Int;
	private var myStartShift2:Int;
	private var myLen1:Int;
	private var myLen2:Int;
	private var myBuilder:ChangeBuilder;

	public function new(text1:String, text2:String, words1:List<InlineChunk>, words2:List<InlineChunk>, startShift1:Int, startShift2:Int,
			changes:FairDiffIterable) {
		myText1 = text1;
		myText2 = text2;
		myWords1 = words1;
		myWords2 = words2;
		myStartShift1 = startShift1;
		myStartShift2 = startShift2;

		myChanges = changes;

		myLen1 = text1.length();
		myLen2 = text2.length();

		myBuilder = new ChangeBuilder(myLen1, myLen2);
	}

	public function build():FairDiffIterable {
		execute();
		return fair(myBuilder.finish());
	}

	var lastStart1:Int;
	var lastStart2:Int;
	var lastEnd1:Int;
	var lastEnd2:Int;

	private function execute():Void {
		clearLastRange();

		matchForward(-1, -1);

		for (ch in myChanges.iterateUnchanged()) {
			var count = ch.end1 - ch.start1;
			for (i in 0..count - 1) {
				var index1:Int = ch.start1 + i;
				var index2:Int = ch.start2 + i;

				var start1:Int = getStartOffset1(index1);
				var start2:Int = getStartOffset2(index2);
				var end1:Int = getEndOffset1(index1);
				var end2:Int = getEndOffset2(index2);

				matchBackward(index1, index2);

				myBuilder.markEqual(start1, start2, end1, end2);

				matchForward(index1, index2);
			}
		}

		matchBackward(myWords1.size(), myWords2.size());
	}

	private function clearLastRange():Void {
		lastStart1 = -1;
		lastStart2 = -1;
		lastEnd1 = -1;
		lastEnd2 = -1;
	}

	private function matchBackwardA(index1:Int, index2:Int):Void {
		var start1:Int = index1 == 0 ? 0 : getEndOffset1(index1 - 1);
		var start2:Int = index2 == 0 ? 0 : getEndOffset2(index2 - 1);
		var end1:Int = index1 == myWords1.size() ? myLen1 : getStartOffset1(index1);
		var end2:Int = index2 == myWords2.size() ? myLen2 : getStartOffset2(index2);

		matchBackward(start1, start2, end1, end2);
		clearLastRange();
	}

	private function matchForwardA(index1:Int, index2:Int):Void {
		var start1:Int = index1 == -1 ? 0 : getEndOffset1(index1);
		var start2:Int = index2 == -1 ? 0 : getEndOffset2(index2);
		var end1:Int = index1 + 1 == myWords1.size() ? myLen1 : getStartOffset1(index1 + 1);
		var end2:Int = index2 + 1 == myWords2.size() ? myLen2 : getStartOffset2(index2 + 1);

		matchForward(start1, start2, end1, end2);
	}

	private function matchForwardB(start1:Int, start2:Int, end1:Int, end2:Int):Void {
		// assert lastStart1 == -1 && lastStart2 == -1 && lastEnd1 == -1 && lastEnd2 == -1;

		lastStart1 = start1;
		lastStart2 = start2;
		lastEnd1 = end1;
		lastEnd2 = end2;
	}

	private function matchBackwardB(start1:Int, start2:Int, end1:Int, end2:Int):Void {
		// assert lastStart1 != -1 && lastStart2 != -1 && lastEnd1 != -1 && lastEnd2 != -1;

		if (lastStart1 == start1 && lastStart2 == start2) { // pair of adjustment matched words, match gap between ("A B" - "A B")
			// assert lastEnd1 == end1 && lastEnd2 == end2;

			matchRange(start1, start2, end1, end2);
			return;
		}
		if (lastStart1 < start1 && lastStart2 < start2) { // pair of matched words, with few unmatched ones between ("A X B" - "A Y B")
			// assert lastEnd1 <= start1 && lastEnd2 <= start2;

			matchRange(lastStart1, lastStart2, lastEnd1, lastEnd2);
			matchRange(start1, start2, end1, end2);
			return;
		}

		// one side adjustment, and other has non-matched words between ("A B" - "A Y B")
		matchComplexRange(lastStart1, lastStart2, lastEnd1, lastEnd2, start1, start2, end1, end2);
	}

	private function matchRange(start1:Int, start2:Int, end1:Int, end2:Int):Void {
		if (start1 == end1 && start2 == end2)
			return;

		var sequence1:String = myText1.subSequence(start1, end1);
		var sequence2:String = myText2.subSequence(start2, end2);

		var changes:DiffIterable = ByCharRt.comparePunctuation(sequence1, sequence2);

		for (ch in changes.iterateUnchanged()) {
			myBuilder.markEqual(start1 + ch.start1, start2 + ch.start2, start1 + ch.end1, start2 + ch.end2);
		}
	}

	private function matchComplexRange(start11:Int, start12:Int, end11:Int, end12:Int, start21:Int, start22:Int, end21:Int, end22:Int):Void {
		if (start11 == start21 && end11 == end21) {
			matchComplexRangeLeft(start11, end11, start12, end12, start22, end22);
		} else if (start12 == start22 && end12 == end22) {
			matchComplexRangeRight(start12, end12, start11, end11, start21, end21);
		} else {
			throw new IllegalStateException();
		}
	}

	private function matchComplexRangeLeft(start1:Int, end1:Int, start12:Int, end12:Int, start22:Int, end22:Int):Void {
		var sequence1:String = myText1.subSequence(start1, end1);
		var sequence21:String = myText2.subSequence(start12, end12);
		var sequence22:String = myText2.subSequence(start22, end22);

		var changes:Couple<FairDiffIterable> = comparePunctuation2Side(sequence1, sequence21, sequence22);

		for (ch in changes.first.iterateUnchanged()) {
			myBuilder.markEqual(start1 + ch.start1, start12 + ch.start2, start1 + ch.end1, start12 + ch.end2);
		}
		for (ch in changes.second.iterateUnchanged()) {
			myBuilder.markEqual(start1 + ch.start1, start22 + ch.start2, start1 + ch.end1, start22 + ch.end2);
		}
	}

	private function matchComplexRangeRight(start2:Int, end2:Int, start11:Int, end11:Int, start21:Int, end21:Int):Void {
		var sequence11:String = myText1.subSequence(start11, end11);
		var sequence12:String = myText1.subSequence(start21, end21);
		var sequence2:String = myText2.subSequence(start2, end2);

		var changes:Couple<FairDiffIterable> = comparePunctuation2Side(sequence2, sequence11, sequence12);

		// Mirrored ch.*1 and ch.*2 as we use "compare2Side" that works with 2 right side, while we have 2 left here
		for (ch in changes.first.iterateUnchanged()) {
			myBuilder.markEqual(start11 + ch.start2, start2 + ch.start1, start11 + ch.end2, start2 + ch.end1);
		}
		for (ch in changes.second.iterateUnchanged()) {
			myBuilder.markEqual(start21 + ch.start2, start2 + ch.start1, start21 + ch.end2, start2 + ch.end1);
		}
	}

	private function getStartOffset1(index:Int):Int {
		return myWords1.get(index).getOffset1() - myStartShift1;
	}

	private function getStartOffset2(index:Int):Int {
		return myWords2.get(index).getOffset1() - myStartShift2;
	}

	private function getEndOffset1(index:Int):Int {
		return myWords1.get(index).getOffset2() - myStartShift1;
	}

	private function getEndOffset2(index:Int):Int {
		return myWords2.get(index).getOffset2() - myStartShift2;
	}
}
