// Copyright 2000-2021 JetBrains s.r.o. and contributors. Use of this source code is governed by the Apache 2.0 license.
package diff.comparison;

import util.diff.Diff.ChangeBuilder;
import diff.comparison.iterables.FairDiffIterable;
import diff.fragments.MergeLineFragment;
import diff.util.MergeRange;
import diff.util.Range;
import diff.comparison.ComparisonPolicy.DEFAULT;
import diff.comparison.ComparisonPolicy.IGNORE_WHITESPACES;
import diff.comparison.iterables.DiffIterableUtil.*;

class ByLineRt {
	static public function compareA(lines1:Array<String>, lines2:Array<String>, policy:ComparisonPolicy):FairDiffIterable {
		return doCompare(getLines(lines1, policy), getLines(lines2, policy), policy);
	}

	static public function compareB(lines1:Array<String>, lines2:Array<String>, lines3:Array<String>, policy:ComparisonPolicy,):Array<MergeRange> {
		return doCompare(getLines(lines1, policy), getLines(lines2, policy), getLines(lines3, policy), policy, false);
	}

	static public function merge(lines1:Array<String>, lines2:Array<String>, lines3:Array<String>, policy:ComparisonPolicy):Array<MergeRange> {
		return doCompare(getLines(lines1, policy), getLines(lines2, policy), getLines(lines3, policy), policy, true);
	}

	//
	// Impl
	//

	static private function doCompareA(lines1:Array<Line>, lines2:Array<Line>, policy:ComparisonPolicy):FairDiffIterable {
		if (policy == IGNORE_WHITESPACES) {
			var changes:FairDiffIterable = compareSmart(lines1, lines2, indicator);
			changes = optimizeLineChunks(lines1, lines2, changes, indicator);
			return expandRanges(lines1, lines2, changes);
		} else {
			var iwLines1:Array<Line> = convertMode(lines1, IGNORE_WHITESPACES);
			var iwLines2:Array<Line> = convertMode(lines2, IGNORE_WHITESPACES);

			var iwChanges:FairDiffIterable = compareSmart(iwLines1, iwLines2, indicator);
			iwChanges = optimizeLineChunks(lines1, lines2, iwChanges, indicator);
			return correctChangesSecondStep(lines1, lines2, iwChanges);
		}
	}

	/**
	 * @param keepIgnoredChanges if true, blocks of "ignored" changes will not be actually ignored (but will not be included into "conflict" blocks)
	 */
	static private function doCompareB(lines1:Array<Line>, lines2:Array<Line>, lines3:Array<Line>, policy:ComparisonPolicy,
			keepIgnoredChanges:Bool):Array<MergeRange> {
		var iwLines1:Array<Line> = convertMode(lines1, IGNORE_WHITESPACES);
		var iwLines2:Array<Line> = convertMode(lines2, IGNORE_WHITESPACES);
		var iwLines3:Array<Line> = convertMode(lines3, IGNORE_WHITESPACES);

		var iwChanges1:FairDiffIterable = compareSmart(iwLines2, iwLines1, indicator);
		iwChanges1 = optimizeLineChunks(lines2, lines1, iwChanges1, indicator);
		var iterable1:FairDiffIterable = correctChangesSecondStep(lines2, lines1, iwChanges1);

		var iwChanges2:FairDiffIterable = compareSmart(iwLines2, iwLines3, indicator);
		iwChanges2 = optimizeLineChunks(lines2, lines3, iwChanges2, indicator);
		var iterable2:FairDiffIterable = correctChangesSecondStep(lines2, lines3, iwChanges2);

		if (keepIgnoredChanges && policy != DEFAULT) {
			return ComparisonMergeUtil.buildMerge(iterable1, iterable2,
				(index1, index2, index3) -> equalsDefaultPolicy(lines1, lines2, lines3, index1, index2, index3));
		} else {
			return ComparisonMergeUtil.buildSimple(iterable1, iterable2, indicator);
		}
	}

	static private function equalsDefaultPolicy(lines1:Array<Line>, lines2:Array<Line>, lines3:Array<Line>, index1:Int, index2:Int, index3:Int):Bool {
		var content1:String = lines1.get(index1).getContent();
		var content2:String = lines2.get(index2).getContent();
		var content3:String = lines3.get(index3).getContent();
		return ComparisonUtil.isEquals(content2, content1, DEFAULT) && ComparisonUtil.isEquals(content2, content3, DEFAULT);
	}

	static private function correctChangesSecondStep(@NotNull lines1:Array<Line>, @NotNull lines2:Array<Line>,
		@NotNull changes:FairDiffIterable):FairDiffIterable {
		/*
		 * We want to fix invalid matching here:
		 *
		 * .{        ..{
		 * ..{   vs  ...{
		 * ...{
		 *
		 * first step will return matching (0,2)-(0,2). And we should adjust it to (1,3)-(0,2)
		 *
		 *
		 * From the other hand, we don't want to reduce number of IW-matched lines.
		 *
		 * .{         ...{
		 * ..{    vs  ..{
		 * ...{       .{
		 *
		 * first step will return (0,3)-(0,3) and 'correcting' it to (0,1)-(2,3) is wrong (and it will break ByWord highlighting).
		 *
		 *
		 * Idea:
		 * 1. lines are matched at first step and equal -> match them
		 * 2. lines are not matched at first step -> do not match them
		 * 3. lines are matched at first step and not equal ->
		 *   a. find all IW-equal lines in the same unmatched block
		 *   b. find a maximum matching between them, maximising amount of equal pairs in it
		 *   c. match equal lines using result of the previous step
		 */
		final builder:ExpandChangeBuilder = new ExpandChangeBuilder(lines1, lines2);

		new BuilderRunner(builder).run();
		return fair(builder.finish());
	}

	static private function getBestMatchingAlignment(subLines1:Array<Int>, subLines2:Array<Int>, lines1:Array<Line>, lines2:Array<Line>):Array<Int> {
		// assert subLines1.size() < subLines2.size();
		final size:Int = subLines1.size();

		final comb:Array<Int> = new Array();
		final best:Array<Int> = new Array();

		for (i in 0...size) {
			best[i] = i;
		}
		// find a combination with maximum weight (maximum number of equal lines)
		// TODO: something funky going on here
		// the value isn't being passed in and isn't being returned anywhere
		new AlignmentRunner().run();
		return best;
	}

	static private function optimizeLineChunks(lines1:Array<Line>, lines2:Array<Line>, iterable:FairDiffIterable):FairDiffIterable {
		return new ChunkOptimizer.LineChunkOptimizer(lines1, lines2, iterable).build();
	}

	/*
	 * Compare lines in two steps:
	 *  - compare ignoring "unimportant" lines
	 *  - correct changes (compare all lines gaps between matched chunks)
	 */
	static private function compareSmart(lines1:Array<Line>, lines2:Array<Line>):FairDiffIterable {
		var threshold:Int = ComparisonUtil.getUnimportantLineCharCount();
		if (threshold == 0) {
			return diff(lines1, lines2, indicator);
		}

		var bigLines1:Pair<Array<Line>, Array<Int>> = getBigLines(lines1, threshold);
		var bigLines2:Pair<Array<Line>, Array<Int>> = getBigLines(lines2, threshold);

		var changes:FairDiffIterable = diff(bigLines1.first, bigLines2.first, indicator);
		return new ChangeCorrector.SmartLineChangeCorrector(bigLines1.second, bigLines2.second, lines1, lines2, changes, indicator).build();
	}

	static private function getBigLines(lines:Array<Line>, threshold:Int):Pair<Array<Line>, Array<Int>> {
		var bigLines:Array<Line> = new Array();
		var indexes:Array<Int> = new Array();

		for (i in 0...lines.size()) {
			var line:Line = lines.get(i);

			if (line.getNonSpaceChars() > threshold) {
				bigLines.add(line);
				indexes.add(i);
			}
		}
		return Pair.create(bigLines, indexes);
	}

	static private function expandRanges(lines1:Array<Line>, lines2:Array<Line>, iterable:FairDiffIterable):FairDiffIterable {
		var changes:Array<Range> = new Array();

		for (ch in iterable.iterateChanges()) {
			var expanded:Range = TrimUtil.expand(lines1, lines2, ch.start1, ch.start2, ch.end1, ch.end2);
			if (!expanded.isEmpty()) {
				changes.add(expanded);
			}
		}

		return fair(create(changes, lines1.size(), lines2.size()));
	}

	//
	// Lines
	//
	static private function getLines(text:Array<String>, policy:ComparisonPolicy):Array<Line> {
		// noinspection SSBasedInspection - Can't use ContainerUtil
		return text.stream().map(line -> new Line(line, policy)).collect(Collectors.toList());
	}

	static private function convertMode(original:Array<Line>, policy:ComparisonPolicy):Array<Line> {
		var result:Array<Line> = new Array();
		for (line in original) {
			var newLine:Line = line.myPolicy != policy ? new Line(line.getContent(), policy) : line;
			result.add(newLine);
		}
		return result;
	}

	static public function convertIntoMergeLineFragments(conflicts:Array<MergeRange>):Array<MergeLineFragment> {
		// noinspection SSBasedInspection - Can't use ContainerUtil
		return conflicts.map(ch -> new MergeLineFragment(ch)).collect(Collectors.toList());
	}
}

class Line {
	private final myText:String;
	private final myPolicy:ComparisonPolicy;
	private final myHash:Int;
	private final myNonSpaceChars:Int;

	public function new(text:String, policy:ComparisonPolicy) {
		myText = text;
		myPolicy = policy;
		myHash = ComparisonUtil.hashCode(text, policy);
		myNonSpaceChars = countNonSpaceChars(text);
	}

	public function getContent():String {
		return myText;
	}

	public function getNonSpaceChars():Int {
		return myNonSpaceChars;
	}

	public function equals(l:Line):Bool {
		if (this == l) {
			return true;
		}
		// assert myPolicy == line.myPolicy;
		if (hashCode() != line.hashCode()) {
			return false;
		}
		return ComparisonUtil.isEquals(getContent(), line.getContent(), myPolicy);
	}

	public function hashCode():Int {
		return myHash;
	}

	static private function countNonSpaceChars(text:String):Int {
		var nonSpace:Int = 0;

		var len:Int = text.length();
		var offset:Int = 0;

		while (offset < len) {
			var c:String = text.charAt(offset);
			if (!isWhiteSpace(c)) {
				nonSpace++;
			}
			offset++;
		}

		return nonSpace;
	}
}

class BuilderRunner {
	private var sample:String = null;
	private var last1:Int = 0;
	private var last2:Int = 0;

	private var myBuilder:ChangeBuilder;

	public function new(builder:ChangeBuilder) {
		this.builder = builder;
	}

	public function run():Void {
		for (range in changes.iterateUnchanged()) {
			var count:Int = range.end1 - range.start1;
			for (i in 0...count) {
				var index1:Int = range.start1 + i;
				var index2:Int = range.start2 + i;
				var line1:Line = lines1.get(index1);
				var line2:Line = lines2.get(index2);

				if (!ComparisonUtil.isEquals(sample, line1.getContent(), IGNORE_WHITESPACES)) {
					if (line1.equals(line2)) {
						flush(index1, index2);
						builder.markEqual(index1, index2);
					} else {
						flush(index1, index2);
						sample = line1.getContent();
					}
				}
			}
		}
		flush(changes.getLength1(), changes.getLength2());
	}

	private function flush(line1:Int, line2:Int):Void {
		if (sample == null) {
			return;
		}

		var start1:Int = Math.max(last1, builder.getIndex1());
		var start2:Int = Math.max(last2, builder.getIndex2());

		var subLines1:Array<Int> = new Array();
		var subLines2:Array<Int> = new Array();
		for (i in start1...line1) {
			if (ComparisonUtil.isEquals(sample, lines1.get(i).getContent(), IGNORE_WHITESPACES)) {
				subLines1.add(i);
				last1 = i + 1;
			}
		}
		for (i in start2...line2) {
			if (ComparisonUtil.isEquals(sample, lines2.get(i).getContent(), IGNORE_WHITESPACES)) {
				subLines2.add(i);
				last2 = i + 1;
			}
		}

		// assert subLines1.size() > 0 && subLines2.size() > 0;
		alignExactMatching(subLines1, subLines2);

		sample = null;
	}

	private function alignExactMatching(subLines1:Array<Int>, subLines2:Array<Int>):Void {
		var n:Int = Math.max(subLines1.size(), subLines2.size());
		var skipAligning:Bool = n > 10 || // we use brute-force algorithm (C_n_k). This will limit search space by ~250 cases.
			subLines1.size() == subLines2.size(); // nothing to do

		if (skipAligning) {
			var count:Int = Math.min(subLines1.size(), subLines2.size());
			for (i in 0...count) {
				var index1:Int = subLines1.getInt(i);
				var index2:Int = subLines2.getInt(i);
				if (lines1.get(index1).equals(lines2.get(index2))) {
					builder.markEqual(index1, index2);
				}
			}
			return;
		}

		if (subLines1.size() < subLines2.size()) {
			var matching:Array<Int> = getBestMatchingAlignment(subLines1, subLines2, lines1, lines2);
			for (i in 0...subLines1.size()) {
				var index1:Int = subLines1.getInt(i);
				var index2:Int = subLines2.getInt(matching[i]);
				if (lines1.get(index1).equals(lines2.get(index2))) {
					builder.markEqual(index1, index2);
				}
			}
		} else {
			var matching:Array<Int> = getBestMatchingAlignment(subLines2, subLines1, lines2, lines1);
			for (i in 0...subLines2.size()) {
				var index1:Int = subLines1.getInt(matching[i]);
				var index2:Int = subLines2.getInt(i);
				if (lines1.get(index1).equals(lines2.get(index2))) {
					builder.markEqual(index1, index2);
				}
			}
		}
	}
}

class AlignmentRunner {
	private var bestWeight:Int = 0;

	public function run():Void {
		combinations(0, subLines2.size() - 1, 0);
	}

	private function combinations(start:Int, n:Int, k:Int):Void {
		if (k == size) {
			processCombination();
			return;
		}

		for (i in start...n + 1) {
			comb[k] = i;
			combinations(i + 1, n, k + 1);
		}
	}

	private function processCombination():Void {
		var weight:Int = 0;
		for (i in 0...size) {
			var index1:Int = subLines1.getInt(i);
			var index2:Int = subLines2.getInt(comb[i]);
			if (lines1.get(index1).equals(lines2.get(index2))) {
				weight++;
			}
		}

		if (weight > bestWeight) {
			bestWeight = weight;
			System.arraycopy(comb, 0, best, 0, comb.length);
		}
	}
}
