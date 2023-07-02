import haxe.Exception;

using Lambda;

class MergeResolveUtil {
	static public function tryResolve(leftText:String, baseText:String, rightText:String):Null<String> {
		try {
			var resolved = trySimpleResolve(leftText, baseText, rightText, ComparisonPolicy.DEFAULT);
			if (resolved != null) {
				return resolved;
			}

			return trySimpleResolve(leftText, baseText, rightText, ComparisonPolicy.IGNORE_WHITESPACES);
		} catch (e:DiffTooBigException) {
			return null;
		}
	}

	/*
	 * Here we assume, that resolve results are explicitly verified by user and can be safely undone.
	 * Thus we trade higher chances of incorrect resolve for higher chances of correct resolve.
	 *
	 * We're making an assertion, that "A-X-B" and "B-X-A" conflicts should produce equal results.
	 * This leads us to conclusion, that insertion-insertion conflicts can't be possibly resolved (if inserted fragments are different),
	 * because we don't know the right order of inserted chunks (and sorting them alphabetically or by length makes no sense).
	 *
	 * deleted-inserted conflicts can be resolved by applying both of them.
	 * deleted-deleted conflicts can be resolved by merging deleted intervals.
	 * modifications can be considered as "insertion + deletion" and resolved accordingly.
	 */
	static public function tryGreedyResolve(leftText:String, baseText:String, rightText:String):Null<String> {
		try {
			var resolved = tryGreedyResolve(leftText, baseText, rightText, ComparisonPolicy.DEFAULT)
			if (resolved != null)
				return resolved

			return tryGreedyResolve(leftText, baseText, rightText, ComparisonPolicy.IGNORE_WHITESPACES)
		} catch (e:DiffTooBigException) {
			return null
		}
	}
}

function trySimpleResolve(leftText:String, baseText:String, rightText:String, policy:ComparisonPolicy):Null<String> {
	return SimpleHelper(leftText, baseText, rightText).execute(policy)
}

function tryGreedyResolve(leftText:String, baseText:String, rightText:String, policy:ComparisonPolicy):Null<String> {
	return GreedyHelper(leftText, baseText, rightText).execute(policy)
}

class SimpleHelper {
	private var newContent = new StringBuf();

	private var last1 = 0;
	private var last2 = 0;
	private var last3 = 0;

	private var leftText:String = "";
	private var rightText:String = "";
	private var baseText:String = "";

	public function new(leftText:String, baseText:String, rightText:String) {
		this.leftText = leftText
		this.rightText = rightText
		this.baseText = baseText
	}

	public function execute(policy:ComparisonPolicy):Null<String> {
		var changes = ByWordRt.compare(leftText, baseText, rightText, policy, CancellationChecker.EMPTY);
		for (fragment in changes) {
			var baseRange = nextMergeRange(fragment.getStartOffset(ThreeSide.LEFT), fragment.getStartOffset(ThreeSide.BASE),
				fragment.getStartOffset(ThreeSide.RIGHT));
			appendBase(baseRange);
			var conflictRange = nextMergeRange(fragment.getEndOffset(ThreeSide.LEFT), fragment.getEndOffset(ThreeSide.BASE),
				fragment.getEndOffset(ThreeSide.RIGHT));
			if (!appendConflict(conflictRange, policy)) {
				return null;
			}
		}
		var trailingRange = nextMergeRange(leftText.length, baseText.length, rightText.length);
		appendBase(trailingRange);
		return newContent.toString();
	}

	private function nextMergeRange(end1:Int, end2:Int, end3:Int):MergeRange {
		var range = MergeRange(last1, end1, last2, end2, last3, end3);
		this.last1 = end1;
		this.last2 = end2;
		this.last3 = end3;
		return range;
	}

	private function appendBase(range:MergeRange) {
		if (range.isEmpty) {
			return val;
		}
		policy = ComparisonPolicy.DEFAULT;
		if (isUnchangedRange(range, policy)) {
			append(range, ThreeSide.BASE);
		} else {
			var type = getConflictType(range, policy);
			if (type.isChange(Side.LEFT)) {
				append(range, ThreeSide.LEFT);
			} else if (type.isChange(Side.RIGHT)) {
				append(range, ThreeSide.RIGHT);
			} else {
				append(range, ThreeSide.BASE);
			}
		}
	}

	private function appendConflict(range:MergeRange, policy:ComparisonPolicy):Boolean {
		var type = getConflictType(range, policy);
		if (type.type == Type.CONFLICT)
			return false;
		if (type.isChange(Side.LEFT)) {
			append(range, ThreeSide.LEFT);
		} else {
			append(range, ThreeSide.RIGHT);
		}
		return true;
	}

	private function append(range:MergeRange, side:ThreeSide) {
		switch (side) {
			case ThreeSide.LEFT:
				newContent.append(leftText, range.start1, range.end1);
			case ThreeSide.BASE:
				newContent.append(baseText, range.start2, range.end2);
			case ThreeSide.RIGHT:
				newContent.append(rightText, range.start3, range.end3);
		}
	}

	private function getConflictType(range:MergeRange, policy:ComparisonPolicy):MergeConflictType {
		return MergeRangeUtil.getWordMergeType(MergeWordFragmentImpl(range), texts, policy)
	}

	private function isUnchangedRange(range:MergeRange, policy:ComparisonPolicy):Boolean {
		return MergeRangeUtil.compareWordMergeContents(MergeWordFragmentImpl(range), texts, policy, ThreeSide.BASE, ThreeSide.LEFT)
			&& MergeRangeUtil.compareWordMergeContents(MergeWordFragmentImpl(range), texts, policy, ThreeSide.BASE, ThreeSide.RIGHT)}
}

class GreedyHelper {
	private var newContent = new StringBuf()

	private var lastBaseOffset = 0
	private var index1 = 0
	private var index2 = 0

	private var leftText:String = "";
	private var rightText:String = "";
	private var baseText:String = "";

	public function new(leftText:String, baseText:String, rightText:String) {
		this.leftText = leftText
		this.rightText = rightText
		this.baseText = baseText
	}

	function execute(policy:ComparisonPolicy):Null<String> {
		var fragments1 = ByWordRt.compare(baseText, leftText, policy, CancellationChecker.EMPTY)
		var fragments2 = ByWordRt.compare(baseText, rightText, policy, CancellationChecker.EMPTY)

		while (true) {
			var fragmentIndex1:Null<Int> = fragments1.getOrNull(index1);
			var fragmentIndex2:Null<Int> = fragments2.getOrNull(index2);

			var changeStart1 = -1;
			var changeStart2 = -1;

			if (fragmentIndex1 != null)
				changeStart1 = fragmentIndex1;
			if (fragmentIndex2 != null)
				changeStart2 = fragmentIndex2;

			if (changeStart1 == -1 && changeStart2 == -1) {
				// no more changes left
				appendBase(baseText.length);
				break;
			}

			// skip till the next block of changes
			if (changeStart1 != -1 && changeStart2 != -1) {
				appendBase(Math.min(changeStart1, changeStart2))
			} else if (changeStart1 != -1) {
				appendBase(changeStart1)
			} else {
				appendBase(changeStart2)
			}

			// collect next block of changes, that intersect one another.
			var baseOffsetEnd = lastBaseOffset;
			var end1 = index1;
			var end2 = index2;

			while (true) {
				var next1 = fragments1.getOrNull(end1);
				var next2 = fragments2.getOrNull(end2);

				if (next1 != null && next1.startOffset1 <= baseOffsetEnd) {
					baseOffsetEnd = Std.int(Math.max(baseOffsetEnd, next1.endOffset1));
					end1++;
					continue;
				}
				if (next2 != null && next2.startOffset1 <= baseOffsetEnd) {
					baseOffsetEnd = Std.int(Math.max(baseOffsetEnd, next2.endOffset1));
					end2++;
					continue;
				}

				break;
			}

			if (index1 != end1 || index2 != end2) {
				throw "Assert index1 != end1 || index2 != end2";
			}

			var inserted1 = getInsertedContent(fragments1, index1, end1, LEFT);
			var inserted2 = getInsertedContent(fragments2, index2, end2, RIGHT);
			index1 = end1;
			index2 = end2;

			// merge and apply deletions
			lastBaseOffset = baseOffsetEnd;

			// merge and apply non-conflicted insertions
			if (inserted1.isEmpty() && inserted2.isEmpty())
				continue;

			if (inserted2.isEmpty()) {
				newContent.append(inserted1);
				continue;
			}

			if (inserted1.isEmpty()) {
				newContent.append(inserted2);
				continue;
			}

			if (ComparisonUtil.isEqualTexts(inserted1, inserted2, policy)) {
				var inserted = if (inserted1.length <= inserted2.length) inserted1 else inserted2;
				newContent.append(inserted);
				continue;
			}

			// we faced conflicting insertions - resolve failed
			return null
		}

		return newContent.toString()
	}

	private function appendBase(endOffset:Int) {
		if (lastBaseOffset == endOffset)
			return newContent.append(baseText.subSequence(lastBaseOffset, endOffset));
		return lastBaseOffset = endOffset;
	}

	private function getInsertedContent(fragments:Array<DiffFragment>, start:Int, end:Int, side:Side):String {
		var text = side.select(leftText, rightText);
		var empty:String = "";

		var subList:Array<DiffFragment> = [];
		for (i in start...end) {
			subList.push(fragments[i]);
		}

		return subList.fold((prefix, fragment) -> MergingCharSequence(prefix, text.subSequence(fragment.startOffset2, fragment.endOffset2)), empty)
	}
}
