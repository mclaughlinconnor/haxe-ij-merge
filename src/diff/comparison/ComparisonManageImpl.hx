// Copyright 2000-2020 JetBrains s.r.o. Use of this source code is governed by the Apache 2.0 license that can be found in the LICENSE file.
package diff.comparison;

import ds.Pair;
import diff.comparison.iterables.DiffIterable;
import diff.comparison.iterables.FairDiffIterable;
import diff.util.MergeRange;
import diff.fragments.MergeLineFragment;
import diff.util.Range;
import diff.fragments.LineFragment;
import diff.tools.util.text.LineOffsets;
import diff.tools.util.text.LineOffsetsUtil;

class ComparisonManagerImpl extends ComparisonManager {
	public function compareLinesA(text1:String, text2:String, policy:ComparisonPolicy):Array<LineFragment> {
		var lineOffsets1:LineOffsets = LineOffsetsUtil.createB(text1);
		var lineOffsets2:LineOffsets = LineOffsetsUtil.createB(text2);

		return compareLinesC(text1, text2, lineOffsets1, lineOffsets2, policy);
	}

	public function compareLinesB(text1:String, text2:String, text3:String, policy:ComparisonPolicy,):Array<MergeLineFragment> {
		var lineTexts1:Array<String> = getLineContentsA(text1);
		var lineTexts2:Array<String> = getLineContentsA(text2);
		var lineTexts3:Array<String> = getLineContentsA(text3);

		var ranges:Array<MergeRange> = ByLineRt.compareB(lineTexts1, lineTexts2, lineTexts3, policy);
		return ByLineRt.convertIntoMergeLineFragments(ranges);
	}

	public function compareLinesC(text1:String, text2:String, lineOffsets1:LineOffsets, lineOffsets2:LineOffsets, policy:ComparisonPolicy):Array<LineFragment> {
		var range:Range = new Range(0, lineOffsets1.getLineCount(), 0, lineOffsets2.getLineCount());

		return compareLinesD(range, text1, text2, lineOffsets1, lineOffsets2, policy);
	}

	public function compareLinesD(range:Range, text1:String, text2:String, lineOffsets1:LineOffsets, lineOffsets2:LineOffsets,
			policy:ComparisonPolicy):Array<LineFragment> {
		var lineTexts1:Array<String> = getLineContentsB(range.start1, range.end1, text1, lineOffsets1);
		var lineTexts2:Array<String> = getLineContentsB(range.start2, range.end2, text2, lineOffsets2);

		var iterable:FairDiffIterable = ByLineRt.compareA(lineTexts1, lineTexts2, policy);
		return convertIntoLineFragments(range, lineOffsets1, lineOffsets2, iterable);
	}

	public function mergeLines(text1:String, text2:String, text3:String, policy:ComparisonPolicy,):Array<MergeLineFragment> {
		var lineTexts1:Array<String> = getLineContentsA(text1);
		var lineTexts2:Array<String> = getLineContentsA(text2);
		var lineTexts3:Array<String> = getLineContentsA(text3);

		var ranges:Array<MergeRange> = ByLineRt.merge(lineTexts1, lineTexts2, lineTexts3, policy);
		return ByLineRt.convertIntoMergeLineFragments(ranges);
	}

	// public function mergeLinesWithinRange( text1: String ,
	//     text2: String ,
	//     text3: String ,
	//     policy: ComparisonPolicy ,
	//     range: MergeRange ,
	//     ): Array<MergeLineFragment>   {
	//   var lineTexts1: Array<String>  = getLineContents(range.start1, range.end1, text1, LineOffsetsImpl.create(text1));
	//   var lineTexts2: Array<String>  = getLineContents(range.start2, range.end2, text2, LineOffsetsImpl.create(text2));
	//   var lineTexts3: Array<String>  = getLineContents(range.start3, range.end3, text3, LineOffsetsImpl.create(text3));
	//   var ranges: Array<MergeRange>  = ByLineRt.merge(lineTexts1, lineTexts2, lineTexts3, policy, indicator);
	//   return ByLineRt.convertIntoMergeLineFragments(ranges, range);
	// }
	// public function mergeLinesAdditions(
	//     text1: String ,
	//     text3: String ,
	//     policy: ComparisonPolicy ,
	//   ) :String  {
	//   Array<String> lineTexts1 = getLineContents(text1);
	//   Array<String> lineTexts3 = getLineContents(text3);
	//   FairDiffIterable diff = ByLineRt.compare(lineTexts1, lineTexts3, policy, indicator);
	//
	//   StringBuilder base = new StringBuilder();
	//   for (Range range : diff.iterateUnchanged()) {
	//     for (Int i = range.start1; i < range.end1; i++) {
	//       if (!base.isEmpty()) base.append("\n");
	//       base.append(lineTexts1.get(i));
	//     }
	//   }
	//
	//   return base.toString();
	// }
	//     public function compareLinesInner(
	//         text1: String ,
	//         text2: String ,
	//         policy: ComparisonPolicy ,
	// ): Array<LineFragment>   {
	//       var lineFragments: Array<LineFragment>  = compareLines(text1, text2, policy, indicator);
	//       return createInnerFragments(lineFragments, text1, text2, policy, InnerFragmentsPolicy.WORDS, indicator);
	//     }
	// public function  compareLinesInner(
	//     text1: String ,
	//     text2: String ,
	//     lineOffsets1: LineOffsets ,
	//     lineOffsets2: LineOffsets ,
	//     policy: ComparisonPolicy ,
	//     fragmentsPolicy: InnerFragmentsPolicy ,
	//     ): Array<LineFragment>  {
	//   Array<LineFragment> lineFragments = compareLines(text1, text2, lineOffsets1, lineOffsets2, policy, indicator);
	//   if (fragmentsPolicy != InnerFragmentsPolicy.NONE) {
	//     return createInnerFragments(lineFragments, text1, text2, policy, fragmentsPolicy, indicator);
	//   }
	//   else {
	//     return lineFragments;
	//   }
	// }
	// public function compareLinesInner(
	//     range: Range ,
	//     text1: String ,
	//     text2: String ,
	//     lineOffsets1: LineOffsets ,
	//     lineOffsets2: LineOffsets ,
	//     policy: ComparisonPolicy ,
	//     innerFragments: Bool ,
	// ):Array<LineFragment>
	// {
	//   var fragmentsPolicy: InnerFragmentsPolicy  = innerFragments ? InnerFragmentsPolicy.WORDS : InnerFragmentsPolicy.NONE;
	//   return compareLinesInner(range, text1, text2, lineOffsets1, lineOffsets2, policy, fragmentsPolicy, indicator);
	// }
	// public function compareLinesInner(
	//     range: Range ,
	//     text1: String ,
	//     text2: String ,
	//     lineOffsets1: LineOffsets ,
	//     lineOffsets2: LineOffsets ,
	//     policy: ComparisonPolicy ,
	//     fragmentsPolicy: InnerFragmentsPolicy ,
	// ): Array<LineFragment>
	// {
	//   var lineFragments: Array<LineFragment>  = compareLines(range, text1, text2, lineOffsets1, lineOffsets2, policy, indicator);
	//   if (fragmentsPolicy != InnerFragmentsPolicy.NONE) {
	//     return createInnerFragments(lineFragments, text1, text2, policy, fragmentsPolicy, indicator);
	//   }
	//   else {
	//     return lineFragments;
	//   }
	// }
	// private static function createInnerFragments(
	//     lineFragments: Array<LineFragment> ,
	//     text1: String ,
	//     text2: String ,
	//     policy: ComparisonPolicy ,
	//     fragmentsPolicy: InnerFragmentsPolicy ,
	//     ): Array<LineFragment> {
	//   var result: Array<LineFragment>  = new ArrayArray<>(lineFragments.size());
	//
	//   var tooBigChunksCount: Int  = 0;
	//   for (LineFragment fragment : lineFragments) {
	//     assert fragment.getInnerFragments() == null;
	//
	//     try {
	//       // Do not try to build fine blocks after few fails
	//       var tryComputeDifferences: Bool  = tooBigChunksCount < DiffConfig.MAX_BAD_LINES;
	//       result.addAll(createInnerFragments(fragment, text1, text2, policy, fragmentsPolicy, indicator, tryComputeDifferences));
	//     }
	//     catch (DiffTooBigException e) {
	//       result.add(fragment);
	//       tooBigChunksCount++;
	//     }
	//   }
	//
	//   return result;
	// }
	// private static function createInnerFragments( fragment: LineFragment ,
	//     text1: String ,
	//     text2: String ,
	//     policy: ComparisonPolicy ,
	//     fragmentsPolicy: InnerFragmentsPolicy ,
	//     tryComputeDifferences: Bool ): Array<LineFragment>   {
	//   if (fragmentsPolicy == InnerFragmentsPolicy.NONE) {
	//     return singletonArray(fragment);
	//   }
	//
	//   var subSequence1: String  = text1.subSequence(fragment.getStartOffset1(), fragment.getEndOffset1());
	//   var subSequence2: String  = text2.subSequence(fragment.getStartOffset2(), fragment.getEndOffset2());
	//
	//   if (fragment.getStartLine1() == fragment.getEndLine1() ||
	//       fragment.getStartLine2() == fragment.getEndLine2()) { // Insertion / Deletion
	//     if (ComparisonUtil.isEqualTexts(subSequence1, subSequence2, policy)) {
	//       return singletonArray(new LineFragmentImpl(fragment, Collections.emptyArray()));
	//     }
	//     else {
	//       return singletonArray(fragment);
	//     }
	//   }
	//
	//   if (!tryComputeDifferences) {
	//     return singletonArray(fragment);
	//   }
	//
	//   if (fragmentsPolicy == InnerFragmentsPolicy.WORDS) {
	//     return createInnerWordFragments(fragment, subSequence1, subSequence2, policy, indicator);
	//   } else if (fragmentsPolicy == InnerFragmentsPolicy.CHARS) {
	//     return createInnerCharFragments(fragment, subSequence1, subSequence2, policy, indicator);
	//   } else {
	//     throw new IllegalArgumentException(fragmentsPolicy.name());
	//   }
	// }
	// private static function createInnerWordFragments( fragment: LineFragment ,
	//     subSequence1: String ,
	//     var subSequence2: String ,
	//     var policy: ComparisonPolicy ,
	//     ) :Array<LineFragment>   {
	//   var lineBlocks: Array<LineBlock>  = ByWord.compareAndSplit(subSequence1, subSequence2, policy, indicator);
	//   assert lineBlocks.size() != 0;
	//
	//   var startOffset1: Int  = fragment.getStartOffset1();
	//   var startOffset2: Int  = fragment.getStartOffset2();
	//
	//   var currentStartLine1: Int  = fragment.getStartLine1();
	//   var currentStartLine2: Int  = fragment.getStartLine2();
	//
	//   var chunks: Array<LineFragment>  = new ArrayArray<>();
	//   for (Int i = 0; i < lineBlocks.size(); i++) {
	//     var block: LineBlock  = lineBlocks.get(i);
	//     var offsets: Range  = block.offsets;
	//
	//     // special case for last line to void problem with empty last line
	//     var currentEndLine1: Int  = i != lineBlocks.size() - 1 ? currentStartLine1 + block.newlines1 : fragment.getEndLine1();
	//     var currentEndLine2: Int  = i != lineBlocks.size() - 1 ? currentStartLine2 + block.newlines2 : fragment.getEndLine2();
	//
	//     chunks.push(new LineFragmentImpl(currentStartLine1, currentEndLine1, currentStartLine2, currentEndLine2,
	//           offsets.start1 + startOffset1, offsets.end1 + startOffset1,
	//           offsets.start2 + startOffset2, offsets.end2 + startOffset2,
	//           block.fragments));
	//
	//     currentStartLine1 = currentEndLine1;
	//     currentStartLine2 = currentEndLine2;
	//   }
	//   return chunks;
	// }
	// private static function createInnerCharFragments(
	//     fragment: LineFragment ,
	//     subSequence1: String ,
	//     subSequence2: String ,
	//     policy: ComparisonPolicy ,
	//     ): Array<LineFragment>   {
	//   var innerChanges: Array<DiffFragment>  = doCompareChars(subSequence1, subSequence2, policy, indicator);
	//   return singletonArray(new LineFragmentImpl(fragment, innerChanges));
	// }
	// private static function doCompareChars(
	//     text1: String ,
	//     text2: String ,
	//     policy: ComparisonPolicy ,
	//     ): Array<DiffFragment>  {
	//   var iterable: DiffIterable ;
	//   if (policy == ComparisonPolicy.DEFAULT) {
	//     iterable = ByCharRt.compareTwoStep(text1, text2, new IndicatorCancellationChecker(indicator));
	//   }
	//   else if (policy == ComparisonPolicy.TRIM_WHITESPACES) {
	//     iterable = ByCharRt.compareTrimWhitespaces(text1, text2, new IndicatorCancellationChecker(indicator));
	//   }
	//   else {
	//     iterable = ByCharRt.compareIgnoreWhitespaces(text1, text2, new IndicatorCancellationChecker(indicator));
	//   }
	//
	//   return ByWordRt.convertIntoDiffFragments(iterable);
	// }
	// public override function compareWords(
	//     text1: String ,
	//     text2: String ,
	//     policy: ComparisonPolicy ,
	//     ): Array<DiffFragment>   {
	//   return ByWordRt.compare(text1, text2, policy, indicator);
	// }
	// public function compareChars(
	//     var text1: String ,
	//     text2: String ,
	//     policy: ComparisonPolicy ,
	//     ):Array<DiffFragment>   {
	//   return doCompareChars(text1, text2, policy, indicator);
	// }
	// public function isEquals(
	//     text1: String ,
	//     text2: String ,  policy: ComparisonPolicy
	//     ): Bool  {
	//   return ComparisonUtil.isEqualTexts(text1, text2, policy);
	// }
	//
	// Fragments
	//
	// public static function convertIntoLineFragments(
	//     lineOffsets1: LineOffsets ,
	//     lineOffsets2: LineOffsets ,
	//     changes: DiffIterable
	//     ): Array<LineFragment>  {
	//   var range: Range  = new Range(0, lineOffsets1.getLineCount(),
	//       0, lineOffsets2.getLineCount());
	//   return convertIntoLineFragments(range, lineOffsets1, lineOffsets2, changes);
	// }

	public static function convertIntoLineFragments(range:Range, lineOffsets1:LineOffsets, lineOffsets2:LineOffsets, changes:DiffIterable):Array<LineFragment> {
		var fragments:Array<LineFragment> = [];
		for (ch in changes.iterateChanges()) {
			var startLine1:Int = ch.start1 + range.start1;
			var startLine2:Int = ch.start2 + range.start2;
			var endLine1:Int = ch.end1 + range.start1;
			var endLine2:Int = ch.end2 + range.start2;
			fragments.push(createLineFragment(startLine1, endLine1, startLine2, endLine2, lineOffsets1, lineOffsets2));
		}
		return fragments;
	}

	public static function createLineFragment(startLine1:Int, endLine1:Int, startLine2:Int, endLine2:Int, lineOffsets1:LineOffsets,
			lineOffsets2:LineOffsets):LineFragment {
		var offsets1:Pair<Int, Int> = getOffsets(lineOffsets1, startLine1, endLine1);
		var offsets2:Pair<Int, Int> = getOffsets(lineOffsets2, startLine2, endLine2);
		return LineFragment.newFromExpanded(startLine1, endLine1, startLine2, endLine2, offsets1.first, offsets1.second, offsets2.first, offsets2.second);
	}

	private static function getOffsets(lineOffsets:LineOffsets, startIndex:Int, endIndex:Int):Pair<Int, Int> {
		if (startIndex == endIndex) {
			var offset:Int;
			if (startIndex < lineOffsets.getLineCount()) {
				offset = lineOffsets.getLineStart(startIndex);
			} else {
				offset = lineOffsets.getLineEndB(lineOffsets.getLineCount() - 1, true);
			}
			return new Pair<Int, Int>(offset, offset);
		} else {
			var offset1:Int = lineOffsets.getLineStart(startIndex);
			var offset2:Int = lineOffsets.getLineEndB(endIndex - 1, true);
			return new Pair<Int, Int>(offset1, offset2);
		}
	}

	//
	// Post process line fragments
	//
	// public override function squash(
	//     oldFragments: Array<LineFragment>
	//     ): Array<LineFragment>  {
	//   if (oldFragments.isEmpty()) {
	//     return oldFragments;
	//   }
	//
	//   var newFragments: Array<LineFragment>  = [];
	//   processAdjoining(oldFragments, fragments -> newFragments.add(doSquash(fragments)));
	//   return newFragments;
	// }
	// public function processBlocks(
	//     oldFragments: Array<LineFragment> ,
	//     text1: String ,  final String text2,
	//     policy: ComparisonPolicy ,
	//     squash: Bool , trim: Bool ): Array<LineFragment>  {
	//   if (!squash && !trim) {
	//     return oldFragments;
	//   }
	//   if (oldFragments.isEmpty()){
	//     return oldFragments;
	//   }
	//
	//   var newFragments: Array<LineFragment>  = new ArrayArray<>();
	//   processAdjoining(oldFragments, fragments -> newFragments.addAll(processAdjoining(fragments, text1, text2, policy, squash, trim)));
	//   return newFragments;
	// }
	// private static function processAdjoining(
	//     oldFragments: Array<LineFragment> ,
	//     consumer: Consumer<Array<LineFragment>> ): Void {
	//   var startIndex: Int  = 0;
	//   for (Int i = 1; i < oldFragments.size(); i++) {
	//     if (!isAdjoining(oldFragments.get(i - 1), oldFragments.get(i))) {
	//       consumer.consume(oldFragments.subArray(startIndex, i));
	//       startIndex = i;
	//     }
	//   }
	//   if (startIndex < oldFragments.size()) {
	//     consumer.consume(oldFragments.subArray(startIndex, oldFragments.size()));
	//   }
	// }
	// private static function processAdjoining(
	//     fragments: Array<LineFragment> ,
	//     text1: String ,
	//     text2: String ,
	//     policy: ComparisonPolicy ,
	//     squash: Bool ,
	//     trim: Bool ): Array<LineFragment>  {
	//   var start: Int  = 0;
	//   var end: Int  = fragments.size();
	//
	//   // TODO: trim empty leading/trailing lines
	//   if (trim && policy == ComparisonPolicy.IGNORE_WHITESPACES) {
	//     while (start < end) {
	//       var fragment: LineFragment  = fragments.get(start);
	//       var sequence1: StringSubSequence  = new StringSubSequence(text1, fragment.getStartOffset1(), fragment.getEndOffset1());
	//       var sequence2: StringSubSequence  = new StringSubSequence(text2, fragment.getStartOffset2(), fragment.getEndOffset2());
	//
	//       if ((fragment.getInnerFragments() == null || !fragment.getInnerFragments().isEmpty()) &&
	//           !ComparisonUtil.isEquals(sequence1, sequence2, ComparisonPolicy.IGNORE_WHITESPACES)) {
	//         break;
	//       }
	//       start++;
	//     }
	//     while (start < end) {
	//       var fragment: LineFragment  = fragments.get(end - 1);
	//       var sequence1: StringSubSequence  = new StringSubSequence(text1, fragment.getStartOffset1(), fragment.getEndOffset1());
	//       var sequence2: StringSubSequence  = new StringSubSequence(text2, fragment.getStartOffset2(), fragment.getEndOffset2());
	//
	//       if ((fragment.getInnerFragments() == null || !fragment.getInnerFragments().isEmpty()) &&
	//           !ComparisonUtil.isEquals(sequence1, sequence2, ComparisonPolicy.IGNORE_WHITESPACES)) {
	//         break;
	//       }
	//       end--;
	//     }
	//   }
	//
	//   if (start == end) {
	//     return Collections.emptyArray();
	//   }
	//   if (squash) {
	//     return singletonArray(doSquash(fragments.subArray(start, end)));
	//   }
	//   return fragments.subArray(start, end);
	// }
	// private static function doSquash(
	//     oldFragments: Array<LineFragment> ) :LineFragment  {
	//   assert !oldFragments.isEmpty();
	//   if (oldFragments.size() == 1) {
	//     return oldFragments.get(0);
	//   }
	//
	//   var firstFragment: LineFragment  = oldFragments.get(0);
	//   var lastFragment: LineFragment  = oldFragments.get(oldFragments.size() - 1);
	//
	//   var newInnerFragments: Array<DiffFragment>  = new ArrayArray<>();
	//   for (LineFragment fragment in oldFragments) {
	//     for (DiffFragment innerFragment in extractInnerFragments(fragment)) {
	//       var shift1: Int  = fragment.getStartOffset1() - firstFragment.getStartOffset1();
	//       var shift2: Int  = fragment.getStartOffset2() - firstFragment.getStartOffset2();
	//
	//       var previousFragment: DiffFragment  = ContainerUtil.getLastItem(newInnerFragments);
	//       if (previousFragment == null || !isAdjoiningInner(previousFragment, innerFragment, shift1, shift2)) {
	//         newInnerFragments.push(new DiffFragmentImpl(innerFragment.getStartOffset1() + shift1, innerFragment.getEndOffset1() + shift1,
	//               innerFragment.getStartOffset2() + shift2, innerFragment.getEndOffset2() + shift2));
	//       }
	//       else {
	//         newInnerFragments.remove(newInnerFragments.size() - 1);
	//         newInnerFragments.push(new DiffFragmentImpl(previousFragment.getStartOffset1(), innerFragment.getEndOffset1() + shift1,
	//               previousFragment.getStartOffset2(), innerFragment.getEndOffset2() + shift2));
	//       }
	//     }
	//   }
	//
	//   return new LineFragmentImpl(firstFragment.getStartLine1(), lastFragment.getEndLine1(),
	//       firstFragment.getStartLine2(), lastFragment.getEndLine2(),
	//       firstFragment.getStartOffset1(), lastFragment.getEndOffset1(),
	//       firstFragment.getStartOffset2(), lastFragment.getEndOffset2(),
	//       newInnerFragments);
	// }
	// private static function isAdjoining(
	//     beforeFragment: LineFragment ,
	//     afterFragment: LineFragment
	//     ):Bool {
	//   if (beforeFragment.getEndLine1() != afterFragment.getStartLine1() ||
	//       beforeFragment.getEndLine2() != afterFragment.getStartLine2() ||
	//       beforeFragment.getEndOffset1() != afterFragment.getStartOffset1() ||
	//       beforeFragment.getEndOffset2() != afterFragment.getStartOffset2()) {
	//     return false;
	//   }
	//
	//   return true;
	// }
	// private static function isAdjoiningInner(
	//     beforeFragment: DiffFragment ,
	//     afterFragment: DiffFragment ,
	//     shift1: Int ,
	//     shift2: Int ): Bool {
	//   if (beforeFragment.getEndOffset1() != afterFragment.getStartOffset1() + shift1 ||
	//       beforeFragment.getEndOffset2() != afterFragment.getStartOffset2() + shift2) {
	//     return false;
	//   }
	//
	//   return true;
	// }
	// private static function extractInnerFragments(
	//     lineFragment: LineFragment
	//     ): Array<DiffFragment> {
	//   if (lineFragment.getInnerFragments() != null){
	//     return lineFragment.getInnerFragments();
	//   }
	//
	//   var length1: Int  = lineFragment.getEndOffset1() - lineFragment.getStartOffset1();
	//   var length2: Int  = lineFragment.getEndOffset2() - lineFragment.getStartOffset2();
	//   return singletonArray(new DiffFragmentImpl(0, length1, 0, length2));
	// }

	private static function getLineContentsA(text:String):Array<String> {
		var lineOffsets:LineOffsets = LineOffsetsUtil.createB(text);
		return getLineContentsB(0, lineOffsets.getLineCount(), text, lineOffsets);
	}

	private static function getLineContentsB(start:Int, end:Int, text:String, lineOffsets:LineOffsets):Array<String> {
		var lines:Array<String> = [];
		for (line in start...end) {
			lines.push(text.substring(lineOffsets.getLineStart(line), lineOffsets.getLineEndA(line)));
		}
		return lines;
	}

	// private static function getNotIgnoredLineContents(
	//     start: Int ,
	//     end: Int ,
	//     text: String ,
	//     lineOffsets: LineOffsets ,
	//     ignored: BitSet
	//     ): Array<String> {
	//   var sb: StringBuilder  = new StringBuilder();
	//   var lines: Array<String>  = new ArrayArray<>(end - start);
	//   for (Int line = start; line < end; line++) {
	//     for (Int offset = lineOffsets.getLineStart(line); offset < lineOffsets.getLineEnd(line); offset++) {
	//       if (ignored.get(offset)) {
	//         continue;
	//       }
	//       sb.append(text.charAt(offset));
	//     }
	//     lines.push(sb.toString());
	//     sb.setLength(0);
	//   }
	//   return lines;
	// }
	// public function compareLinesWithIgnoredRanges(
	//     text1: String ,
	//     text2: String ,
	//     lineOffsets1: LineOffsets ,
	//     lineOffsets2: LineOffsets ,
	//     ignored1: BitSet ,
	//     ignored2: BitSet ,
	//     fragmentsPolicy: InnerFragmentsPolicy ,
	//     ): Array<LineFragment>
	// {
	//   var range: Range  = new Range(0, lineOffsets1.getLineCount(),
	//       0, lineOffsets2.getLineCount());
	//   return compareLinesWithIgnoredRanges(range, text1, text2, lineOffsets1, lineOffsets2, ignored1, ignored2,
	//       fragmentsPolicy, indicator);
	// }
	/**
	 * Compare two texts by-line and then compare changed fragments by-word
	 */
	// public function compareLinesWithIgnoredRanges(
	//     range: Range ,
	//     text1: String ,
	//     text2: String ,
	//     lineOffsets1: LineOffsets ,
	//     lineOffsets2: LineOffsets ,
	//     ignored1: BitSet ,
	//     ignored2: BitSet ,
	//     fragmentsPolicy: InnerFragmentsPolicy ,
	//     indicator: ProgressIndicator ): Array<LineFragment>   {
	//   var lineTexts1: Array<String>  = getNotIgnoredLineContents(range.start1, range.end1, text1, lineOffsets1, ignored1);
	//   var lineTexts2: Array<String>  = getNotIgnoredLineContents(range.start2, range.end2, text2, lineOffsets2, ignored2);
	//
	//   var iterable: FairDiffIterable  = ByLineRt.compare(lineTexts1, lineTexts2, ComparisonPolicy.DEFAULT, indicator);
	//
	//   var correctedIterable: FairDiffIterable  = correctIgnoredRangesSecondStep(range, iterable, text1, text2, lineOffsets1, lineOffsets2,
	//       ignored1, ignored2);
	//
	//   var trimmedIterable: DiffIterable  = trimIgnoredLines(range, correctedIterable, text1, text2, lineOffsets1, lineOffsets2,
	//       ignored1, ignored2);
	//
	//   var lineFragments: Array<LineFragment>  = convertIntoLineFragments(range, lineOffsets1, lineOffsets2, trimmedIterable);
	//
	//   if (fragmentsPolicy != InnerFragmentsPolicy.NONE) {
	//     lineFragments = createInnerFragments(lineFragments, text1, text2, ComparisonPolicy.DEFAULT, fragmentsPolicy, indicator);
	//   }
	//
	//   return ContainerUtil.mapNotNull(lineFragments, fragment -> trimIgnoredInnerFragments(fragment, ignored1, ignored2));
	// }
	// public function static collectIgnoredRanges(
	//     ignoredRanges: Array<TextRange>
	//     ): BitSet {
	//   var set: BitSet  = new BitSet();
	//   for (TextRange range : ignoredRanges) {
	//     set.set(range.getStartOffset(), range.getEndOffset());
	//   }
	//   return set;
	// }
	// private static function correctIgnoredRangesSecondStep( range: Range ,
	//     iterable: FairDiffIterable ,
	//     text1: String ,
	//     text2: String ,
	//     lineOffsets1: LineOffsets ,
	//     lineOffsets2: LineOffsets ,
	//     ignored1: BitSet ,
	//     ignored2: BitSet ): FairDiffIterable  {
	//   var builder: DiffIterableUtil.ChangeBuilder  = new DiffIterableUtil.ChangeBuilder(iterable.getLength1(), iterable.getLength2());
	//   for (ch in iterable.iterateUnchanged()) {
	//     var count: Int  = ch.end1 - ch.start1;
	//     for (Int i = 0; i < count; i++) {
	//       var index1: Int  = ch.start1 + i;
	//       var index2: Int  = ch.start2 + i;
	//       if (areIgnoredEqualLines(range.start1 + index1, range.start2 + index2, text1, text2, lineOffsets1, lineOffsets2, ignored1,
	//             ignored2)) {
	//         builder.markEqual(index1, index2);
	//       }
	//     }
	//   }
	//   return fair(builder.finish());
	// }
	// private static trimIgnoredLines(
	//     range: Range ,
	//     iterable: FairDiffIterable ,
	//     text1: String ,
	//     text2: String ,
	//     lineOffsets1: LineOffsets ,
	//     lineOffsets2: LineOffsets ,
	//     ignored1: BitSet ,
	//     ignored2: BitSet ): DiffIterable  {
	//   var changedRanges: Array<Range>  = new ArrayArray<>();
	//
	//   for (Range ch in iterable.iterateChanges()) {
	//     var trimmedRange: Range  = TrimUtil.trimExpandRange(ch.start1, ch.start2,
	//         ch.end1, ch.end2,
	//         function(index1, index2) { areIgnoredEqualLines(range.start1 + index1, range.start2 + index2,
	//           text1, text2,
	//           lineOffsets1, lineOffsets2,
	//           ignored1, ignored2)},
	//         function(index) { isIgnoredLine(range.start1 + index, lineOffsets1, ignored1)},
	//         function(index) { isIgnoredLine(range.start2 + index, lineOffsets2, ignored2)});
	//
	//     if (!trimmedRange.isEmpty()) {
	//       changedRanges.add(trimmedRange);
	//     }
	//   }
	//
	//   return DiffIterableUtil.create(changedRanges, iterable.getLength1(), iterable.getLength2());
	// }
	// private static function trimIgnoredInnerFragments(
	//     fragment: LineFragment ,
	//     ignored1: BitSet ,
	//     ignored2: BitSet ): LineFragment {
	//   if (fragment.getInnerFragments() == null){
	//     return fragment;
	//   }
	//
	//   var startOffset1: Int  = fragment.getStartOffset1();
	//   var startOffset2: Int  = fragment.getStartOffset2();
	//
	//   var newInner: Array<DiffFragment>  = ContainerUtil.mapNotNull(fragment.getInnerFragments(), it -> {
	//     var range1: TextRange  = trimIgnoredRange(it.getStartOffset1(), it.getEndOffset1(), ignored1, startOffset1);
	//     var range2: TextRange  = trimIgnoredRange(it.getStartOffset2(), it.getEndOffset2(), ignored2, startOffset2);
	//
	//     if (range1.isEmpty() && range2.isEmpty()){
	//       return null;
	//     }
	//     return new DiffFragmentImpl(range1.getStartOffset(), range1.getEndOffset(),
	//         range2.getStartOffset(), range2.getEndOffset());
	//   });
	//
	//   if (newInner.isEmpty()) {
	//     return null;
	//   }
	//   return new LineFragmentImpl(fragment, newInner);
	// }
	// private static isIgnoredLine(
	//     index: Int ,
	//     lineOffsets: LineOffsets ,
	//     ignored: BitSet
	//     ): Bool  {
	//   return isIgnoredRange(ignored, lineOffsets.getLineStart(index), lineOffsets.getLineEnd(index, true));
	// }
	// private static function areIgnoredEqualLines(
	//     index1: Int ,
	//     index2: Int ,
	//     text1: String ,
	//     text2: String ,
	//     lineOffsets1: LineOffsets ,
	//     lineOffsets2: LineOffsets ,
	//     ignored1: BitSet ,
	//     ignored2: BitSet ): Bool  {
	//   var start1: Int  = lineOffsets1.getLineStart(index1);
	//   var end1: Int  = lineOffsets1.getLineEnd(index1, true);
	//   var start2: Int  = lineOffsets2.getLineStart(index2);
	//   var end2: Int  = lineOffsets2.getLineEnd(index2, true);
	//   var range: Range  = TrimUtil.trimExpandText(text1, text2,
	//       start1, start2, end1, end2,
	//       ignored1, ignored2);
	//   if (!range.isEmpty()) {
	//     return false;
	//   }
	//
	//   var words1: Array<InlineChunk>  = getNonIgnoredWords(index1, text1, lineOffsets1, ignored1);
	//   var words2: Array<InlineChunk>  = getNonIgnoredWords(index2, text2, lineOffsets2, ignored2);
	//   if (words1.size() != words2.size()) {
	//     return false;
	//   }
	//
	//   for (Int i = 0; i < words1.size(); i++) {
	//     var word1: String  = getWordContent(index1, text1, lineOffsets1, words1.get(i));
	//     var word2: String  = getWordContent(index2, text2, lineOffsets2, words2.get(i));
	//     if (!ComparisonUtil.isEquals(word1, word2, ComparisonPolicy.DEFAULT))
	//     {return false;
	//     }
	//   }
	//
	//   return true;
	// }
	// private static function getNonIgnoredWords(
	//     index: Int ,
	//     text: String ,
	//     lineOffsets: LineOffsets ,
	//     ignored: BitSet ) :Array<InlineChunk>  {
	//   var offset: Int  = lineOffsets.getLineStart(index);
	//   var innerChunks: Array<InlineChunk>  = ByWordRt.getInlineChunks(getLineContent(index, text, lineOffsets));
	//   return ContainerUtil.filter(innerChunks, it -> ByWordRt.isWordChunk(it) &&
	//       !isIgnoredRange(ignored, offset + it.getOffset1(), offset + it.getOffset2()));
	// }
	// private static function getWordContent(
	//     index: Int ,
	//     text: String ,
	//     lineOffsets: LineOffsets ,
	//     word: InlineChunk ):String   {
	//   return getLineContent(index, text, lineOffsets).subSequence(word.getOffset1(), word.getOffset2());
	// }
	// private static function trimIgnoredRange(
	//     start: Int ,
	//     end: Int ,
	//     ignored: BitSet ,
	//     offset: Int
	//     ): TextRange  {
	//   var intPair: IntPair  = TrimUtil.trim(offset + start, offset + end, ignored);
	//   return new TextRange(intPair.first - offset, intPair.second - offset);
	// }
	// private static function isIgnoredRange(
	//     ignored: BitSet ,
	//     start: Int ,
	//     end: Int
	//     ): Bool  {
	//   return ignored.nextClearBit(start) >= end;
	// }
	// private static getLineContent(
	//     index: Int ,  text: String ,  lineOffsets: LineOffsets
	//     ): String  {
	//   return text.subSequence(lineOffsets.getLineStart(index), lineOffsets.getLineEnd(index, true));
	// }
}
