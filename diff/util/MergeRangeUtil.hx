// Copyright 2000-2022 JetBrains s.r.o. and contributors. Use of this source code is governed by the Apache 2.0 license.
package diff.util;

import ds.LineOffsets;
import diff.comparison.ComparisonMergeUtil;
import diff.comparison.ComparisonPolicy;
import diff.comparison.ComparisonUtil;
import diff.fragments.MergeLineFragment;
import diff.fragments.MergeWordFragment;
import ds.BiPredicate;
import ds.BooleanSupplier;
import ds.Predicate;
// import diff.tools.util.text.LineOffsets;
// import diff.util.DiffRangeUtil.getLinesContent;

class MergeRangeUtil {
	static public function getMergeType(emptiness:Predicate<ThreeSide>, equality:BiPredicate<ThreeSide, ThreeSide>,
			trueEquality:Null<BiPredicate<ThreeSide, ThreeSide>>, conflictResolver:BooleanSupplier) {
		var isLeftEmpty:Bool = emptiness.test(ThreeSide.LEFT);
		var isBaseEmpty:Bool = emptiness.test(ThreeSide.BASE);
		var isRightEmpty:Bool = emptiness.test(ThreeSide.RIGHT);
		// assert !isLeftEmpty || !isBaseEmpty || !isRightEmpty;

		if (isBaseEmpty) {
			if (isLeftEmpty) { // --=
				return new MergeConflictType(MergeConflictType.Type.INSERTED, false, true);
			} else if (isRightEmpty) { // =--
				return new MergeConflictType(MergeConflictType.Type.INSERTED, true, false);
			} else { // =-=
				var equalModifications:Bool = equality.test(ThreeSide.LEFT, ThreeSide.RIGHT);
				if (equalModifications) {
					return new MergeConflictType(MergeConflictType.Type.INSERTED, true, true);
				} else {
					return new MergeConflictType(MergeConflictType.Type.CONFLICT, true, true, false);
				}
			}
		} else {
			if (isLeftEmpty && isRightEmpty) { // -=-
				return new MergeConflictType(MergeConflictType.Type.DELETED, true, true);
			} else { // -==, ==-, ===
				var unchangedLeft:Bool = equality.test(ThreeSide.BASE, ThreeSide.LEFT);
				var unchangedRight:Bool = equality.test(ThreeSide.BASE, ThreeSide.RIGHT);

				if (unchangedLeft && unchangedRight) {
					// assert trueEquality != null;
					var trueUnchangedLeft:Bool = trueEquality.test(ThreeSide.BASE, ThreeSide.LEFT);
					var trueUnchangedRight:Bool = trueEquality.test(ThreeSide.BASE, ThreeSide.RIGHT);
					// assert !trueUnchangedLeft || !trueUnchangedRight;
					return new MergeConflictType(MergeConflictType.Type.MODIFIED, !trueUnchangedLeft, !trueUnchangedRight);
				}

				if (unchangedLeft) {
					return new MergeConflictType(isRightEmpty ? MergeConflictType.Type.DELETED : MergeConflictType.Type.MODIFIED, false, true);
				}
				if (unchangedRight) {
					return new MergeConflictType(isLeftEmpty ? MergeConflictType.Type.DELETED : MergeConflictType.Type.MODIFIED, true, false);
				}

				var equalModifications:Bool = equality.test(ThreeSide.LEFT, ThreeSide.RIGHT);
				if (equalModifications) {
					return new MergeConflictType(MergeConflictType.Type.MODIFIED, true, true);
				} else {
					var canBeResolved:Bool = !isLeftEmpty && !isRightEmpty && conflictResolver.getAsBool();
					return new MergeConflictType(MergeConflictType.Type.CONFLICT, true, true, canBeResolved);
				}
			}
		}
	}

	static public function getLineThreeWayDiffType(fragment:MergeLineFragment, sequences:List<String>, lineOffsets:List<LineOffsets>,
			policy:ComparisonPolicy):MergeConflictType {
		return getMergeType((side) -> isLineMergeIntervalEmpty(fragment, side),
			(side1, side2) -> compareLineMergeContents(fragment, sequences, lineOffsets, policy, side1, side2), null,
			() -> canResolveLineConflict(fragment, sequences, lineOffsets));
	}

	static public function getLineMergeType(fragment:MergeLineFragment, sequences:List<String>, lineOffsets:List<LineOffsets>,
			policy:ComparisonPolicy):MergeConflictType {
		return getMergeType((side) -> isLineMergeIntervalEmpty(fragment, side),
			(side1, side2) -> compareLineMergeContents(fragment, sequences, lineOffsets, policy, side1, side2),
			(side1, side2) -> compareLineMergeContents(fragment, sequences, lineOffsets, ComparisonPolicy.DEFAULT, side1, side2),
			() -> canResolveLineConflict(fragment, sequences, lineOffsets));
	}

	static private function canResolveLineConflict(fragment:MergeLineFragment, sequences:List<String>, lineOffsets:List<LineOffsets>):Bool {
		var contents:List<String> = ThreeSide.map(side -> getLinesContent(side.select(sequences), side.select(lineOffsets), fragment.getStartLine(side),
			fragment.getEndLine(side)));
		return ComparisonMergeUtil.tryResolveConflict(contents.get(0), contents.get(1), contents.get(2)) != null;
	}

	static private function compareLineMergeContents(fragment:MergeLineFragment, sequences:List<String>, lineOffsets:List<LineOffsets>,
			policy:ComparisonPolicy, side1:ThreeSide, side2:ThreeSide):Bool {
		var start1:Int = fragment.getStartLine(side1);
		var end1:Int = fragment.getEndLine(side1);
		var start2:Int = fragment.getStartLine(side2);
		var end2:Int = fragment.getEndLine(side2);

		if (end2 - start2 != end1 - start1) {
			return false;
		}

		var sequence1:String = side1.select(sequences);
		var sequence2:String = side2.select(sequences);
		var offsets1:LineOffsets = side1.select(lineOffsets);
		var offsets2:LineOffsets = side2.select(lineOffsets);

		for (i in 0...end1 - start1) {
			var line1:Int = start1 + i;
			var line2:Int = start2 + i;

			var content1:String = getLinesContent(sequence1, offsets1, line1, line1 + 1);
			var content2:String = getLinesContent(sequence2, offsets2, line2, line2 + 1);
			if (!ComparisonUtil.isEqualTexts(content1, content2, policy)) {
				return false;
			}
		}

		return true;
	}

	static private function isLineMergeIntervalEmpty(fragment:MergeLineFragment, side:ThreeSide):Bool {
		return fragment.getStartLine(side) == fragment.getEndLine(side);
	}

	static public function getWordMergeType(fragment:MergeWordFragment, texts:List<String>, policy:ComparisonPolicy):MergeConflictType {
		return getMergeType((side) -> isWordMergeIntervalEmpty(fragment, side),
			(side1, side2) -> compareWordMergeContents(fragment, texts, policy, side1, side2), null, () -> false);
	}

	static public function compareWordMergeContents(fragment:MergeWordFragment, texts:List<String>, policy:ComparisonPolicy, side1:ThreeSide,
			side2:ThreeSide):Bool {
		var start1:Int = fragment.getStartOffset(side1);
		var end1:Int = fragment.getEndOffset(side1);
		var start2:Int = fragment.getStartOffset(side2);
		var end2:Int = fragment.getEndOffset(side2);

		var document1:String = side1.select(texts);
		var document2:String = side2.select(texts);

		var content1:String = document1.subSequence(start1, end1);
		var content2:String = document2.subSequence(start2, end2);
		return ComparisonUtil.isEqualTexts(content1, content2, policy);
	}

	static private function isWordMergeIntervalEmpty(fragment:MergeWordFragment, side:ThreeSide):Bool {
		return fragment.getStartOffset(side) == fragment.getEndOffset(side);
	}

	static public function getLineLeftToRightThreeSideDiffType(fragment:MergeLineFragment, sequences:List<String>, lineOffsets:List<LineOffsets>,
			policy:ComparisonPolicy):MergeConflictType {
		return getLeftToRightDiffType((side) -> isLineMergeIntervalEmpty(fragment, side),
			(side1, side2) -> compareLineMergeContents(fragment, sequences, lineOffsets, policy, side1, side2));
	}

	static private function getLeftToRightDiffType(emptiness:Predicate<ThreeSide>, equality:BiPredicate<ThreeSide, ThreeSide>):MergeConflictType {
		var isLeftEmpty:Bool = emptiness.test(ThreeSide.LEFT);
		var isBaseEmpty:Bool = emptiness.test(ThreeSide.BASE);
		var isRightEmpty:Bool = emptiness.test(ThreeSide.RIGHT);

		// assert! isLeftEmpty || !isBaseEmpty || !isRightEmpty;

		if (isBaseEmpty) {
			if (isLeftEmpty) { // --=
				return new MergeConflictType(MergeConflictType.Type.INSERTED, false, true);
			} else if (isRightEmpty) { // =--
				return new MergeConflictType(MergeConflictType.Type.DELETED, true, false);
			} else { // =-=
				return new MergeConflictType(MergeConflictType.Type.MODIFIED, true, true);
			}
		} else {
			if (isLeftEmpty && isRightEmpty) { // -=-
				return new MergeConflictType(MergeConflictType.Type.MODIFIED, true, true);
			} else { // -==, ==-, ===
				var unchangedLeft:Bool = equality.test(ThreeSide.BASE, ThreeSide.LEFT);
				var unchangedRight:Bool = equality.test(ThreeSide.BASE, ThreeSide.RIGHT);
				// assert! unchangedLeft || !unchangedRight;

				if (unchangedLeft) {
					return new MergeConflictType(isRightEmpty ? MergeConflictType.Type.DELETED : MergeConflictType.Type.MODIFIED, false, true);
				}
				if (unchangedRight) {
					return new MergeConflictType(isLeftEmpty ? MergeConflictType.Type.INSERTED : MergeConflictType.Type.MODIFIED, true, false);
				}

				return new MergeConflictType(MergeConflictType.Type.MODIFIED, true, true);
			}
		}
	}
}
