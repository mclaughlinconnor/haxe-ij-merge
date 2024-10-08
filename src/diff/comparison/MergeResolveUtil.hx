package diff.comparison;

import ds.MergingCharSequence;
import diff.fragments.DiffFragment;
import diff.fragments.MergeWordFragment;
import diff.util.MergeConflictType;
import diff.util.MergeRange;
import diff.util.MergeRangeUtil;
import diff.util.Side;
import diff.util.ThreeSide.ThreeSideEnum;
import diff.util.ThreeSide;

using Lambda;

import haxe.Exception;

class MergeResolveUtil {
	static public function tryResolve(leftText:String, baseText:String, rightText:String):Null<String> {
		try {
			var resolved = trySimpleResolveHelper(leftText, baseText, rightText, ComparisonPolicy.DEFAULT);
			if (resolved != null) {
				return resolved;
			}

			return trySimpleResolveHelper(leftText, baseText, rightText, ComparisonPolicy.IGNORE_WHITESPACES);
		} catch (e:DiffTooBigException) {
			return null;
		}

		// Why is an extra return needed? Weird type inference?
		return null;
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
			var resolved = tryGreedyResolveHelper(leftText, baseText, rightText, ComparisonPolicy.DEFAULT);
			if (resolved != null) {
				return resolved;
			}

			return tryGreedyResolveHelper(leftText, baseText, rightText, ComparisonPolicy.IGNORE_WHITESPACES);
		} catch (e:DiffTooBigException) {
			return null;
		}

		return null;
	}
}

function trySimpleResolveHelper(leftText:String, baseText:String, rightText:String, policy:ComparisonPolicy):Null<String> {
	return new SimpleHelper(leftText, baseText, rightText).execute(policy);
}

function tryGreedyResolveHelper(leftText:String, baseText:String, rightText:String, policy:ComparisonPolicy):Null<String> {
	return new GreedyHelper(leftText, baseText, rightText).execute(policy);
}

class SimpleHelper {
	private var newContent = new StringBuf();

	private var last1 = 0;
	private var last2 = 0;
	private var last3 = 0;

	private var leftText:String = "";
	private var rightText:String = "";
	private var baseText:String = "";

	private var texts:Array<String>;

	public function new(leftText:String, baseText:String, rightText:String) {
		this.leftText = leftText;
		this.rightText = rightText;
		this.baseText = baseText;

		this.texts = [leftText, baseText, rightText];
	}

	public function execute(policy:ComparisonPolicy):Null<String> {
		var changes:Array<MergeWordFragment> = ByWordRt.compareX(leftText, baseText, rightText, policy);
		// TODO: fairdiffiterator isn't implemented which makes this bad
		for (fragment in changes) {
			var baseRange = nextMergeRange(fragment.getStartOffset(ThreeSide.fromEnum(ThreeSideEnum.LEFT)),
				fragment.getStartOffset(ThreeSide.fromEnum(ThreeSideEnum.BASE)), fragment.getStartOffset(ThreeSide.fromEnum(ThreeSideEnum.RIGHT)));
			appendBase(baseRange);
			var conflictRange = nextMergeRange(fragment.getEndOffset(ThreeSide.fromEnum(ThreeSideEnum.LEFT)),
				fragment.getEndOffset(ThreeSide.fromEnum(ThreeSideEnum.BASE)), fragment.getEndOffset(ThreeSide.fromEnum(ThreeSideEnum.RIGHT)));
			if (!appendConflict(conflictRange, policy)) {
				return null;
			}
		}
		var trailingRange = nextMergeRange(leftText.length, baseText.length, rightText.length);
		appendBase(trailingRange);
		return newContent.toString();
	}

	private function nextMergeRange(end1:Int, end2:Int, end3:Int):MergeRange {
		var range = new MergeRange(last1, end1, last2, end2, last3, end3);
		this.last1 = end1;
		this.last2 = end2;
		this.last3 = end3;
		return range;
	}

	private function appendBase(range:MergeRange) {
		if (range.isEmpty()) {
			return;
		}

		var policy = ComparisonPolicy.DEFAULT;
		if (isUnchangedRange(range, policy)) {
			append(range, ThreeSideEnum.BASE);
		} else {
			var type = getConflictType(range, policy);
			if (type.isChangeA(Side.fromEnum(SideEnum.LEFT))) {
				append(range, ThreeSideEnum.LEFT);
			} else if (type.isChangeA(Side.fromEnum(SideEnum.RIGHT))) {
				append(range, ThreeSideEnum.RIGHT);
			} else {
				append(range, ThreeSideEnum.BASE);
			}
		}
	}

	private function appendConflict(range:MergeRange, policy:ComparisonPolicy):Bool {
		var type = getConflictType(range, policy);
		if (type.getType() == MergeConflictTypeEnum.CONFLICT)
			return false;
		if (type.isChangeA(Side.fromEnum(SideEnum.LEFT))) {
			append(range, ThreeSideEnum.LEFT);
		} else {
			append(range, ThreeSideEnum.RIGHT);
		}
		return true;
	}

	private function append(range:MergeRange, side:ThreeSideEnum) {
		switch (side) {
			case ThreeSideEnum.LEFT:
				newContent.add(leftText.substring(range.start1, range.end1));
			case ThreeSideEnum.BASE:
				newContent.add(baseText.substring(range.start2, range.end2));
			case ThreeSideEnum.RIGHT:
				newContent.add(rightText.substring(range.start3, range.end3));
		}
	}

	private function getConflictType(range:MergeRange, policy:ComparisonPolicy):MergeConflictType {
		return MergeRangeUtil.getWordMergeType(MergeWordFragment.newFromRange(range), this.texts, policy);
	}

	private function isUnchangedRange(range:MergeRange, policy:ComparisonPolicy):Bool {
		return MergeRangeUtil.compareWordMergeContents(MergeWordFragment.newFromRange(range), texts, policy, ThreeSide.fromEnum(ThreeSideEnum.BASE),
			ThreeSide.fromEnum(ThreeSideEnum.LEFT))
			&& MergeRangeUtil.compareWordMergeContents(MergeWordFragment.newFromRange(range), texts, policy, ThreeSide.fromEnum(ThreeSideEnum.BASE),
				ThreeSide.fromEnum(ThreeSideEnum.RIGHT));
	}
}

class GreedyHelper {
	private var newContent = new StringBuf();

	private var lastBaseOffset = 0;
	private var index1 = 0;
	private var index2 = 0;

	private var leftText:String = "";
	private var rightText:String = "";
	private var baseText:String = "";

	public function new(leftText:String, baseText:String, rightText:String) {
		this.leftText = leftText;
		this.rightText = rightText;
		this.baseText = baseText;
	}

	public function execute(policy:ComparisonPolicy):Null<String> {
		var fragments1 = ByWordRt.compareY(baseText, leftText, policy);
		var fragments2 = ByWordRt.compareY(baseText, rightText, policy);

		while (true) {
			var fragIdx1:Null<Int> = fragments1[index1]?.getStartOffset1();
			if (fragIdx1 == null) {
				fragIdx1 = -1;
			}
			var fragmentIndex1:Null<Int> = fragIdx1;

			var fragIdx2:Null<Int> = fragments2[index2]?.getStartOffset1();
			if (fragIdx2 == null) {
				fragIdx2 = -1;
			}
			var fragmentIndex2:Null<Int> = fragIdx2;

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
				appendBase(Std.int(Math.min(changeStart1, changeStart2)));
			} else if (changeStart1 != -1) {
				appendBase(changeStart1);
			} else {
				appendBase(changeStart2);
			}

			// collect next block of changes, that intersect one another.
			var baseOffsetEnd = lastBaseOffset;
			var end1 = index1;
			var end2 = index2;

			while (true) {
				var next1 = fragments1[end1];
				var next2 = fragments2[end2];

				if (next1 != null && next1.getStartOffset1() <= baseOffsetEnd) {
					baseOffsetEnd = Std.int(Math.max(baseOffsetEnd, next1.getEndOffset1()));
					end1++;
					continue;
				}
				if (next2 != null && next2.getStartOffset1() <= baseOffsetEnd) {
					baseOffsetEnd = Std.int(Math.max(baseOffsetEnd, next2.getEndOffset1()));
					end2++;
					continue;
				}

				break;
			}

			// Trying out assert
			// if (!(index1 != end1 || index2 != end2)) {
			// 	throw "Assert index1 != end1 || index2 != end2";
			// }

			var inserted1 = getInsertedContent(fragments1, index1, end1, Side.fromEnum(SideEnum.LEFT));
			var inserted2 = getInsertedContent(fragments2, index2, end2, Side.fromEnum(SideEnum.RIGHT));
			index1 = end1;
			index2 = end2;

			// merge and apply deletions
			lastBaseOffset = baseOffsetEnd;

			// merge and apply non-conflicted insertions
			if (inserted1 == '' && inserted2 == '')
				continue;

			if (inserted2 == '') {
				newContent.add(inserted1);
				continue;
			}

			if (inserted1 == '') {
				newContent.add(inserted2);
				continue;
			}

			if (ComparisonUtil.isEqualTexts(inserted1, inserted2, policy)) {
				var inserted = if (inserted1.length <= inserted2.length) inserted1 else inserted2;
				newContent.add(inserted);
				continue;
			}

			// we faced conflicting insertions - resolve failed
			return null;
		}

		return newContent.toString();
	}

	private function appendBase(endOffset:Int) {
		if (lastBaseOffset == endOffset) {
			return;
		}

		newContent.add(baseText.substring(lastBaseOffset, endOffset));
		lastBaseOffset = endOffset;
	}

	private function getInsertedContent(fragments:Array<DiffFragment>, start:Int, end:Int, side:Side):String {
		var text = side.selectA(leftText, rightText);
		var empty:String = "";

		var subArray:Array<DiffFragment> = [];
		for (i in start...end) {
			subArray.push(fragments[i]);
		}

		return subArray.fold((fragment, prefix) -> new MergingCharSequence(prefix, text.substring(fragment.getStartOffset2(), fragment.getEndOffset2())),
			empty);
	}
}
