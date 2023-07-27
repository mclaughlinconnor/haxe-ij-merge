// Copyright 2000-2022 JetBrains s.r.o. and contributors. Use of this source code is governed by the Apache 2.0 license.
package diff.util;

import diff.comparison.ComparisonMergeUtil;
import diff.comparison.ComparisonPolicy;
import diff.comparison.ComparisonUtil;
import diff.fragments.MergeLineFragment;
import diff.fragments.MergeWordFragment;
import diff.tools.util.text.LineOffsets;
import diff.util.DiffRangeUtil.getLinesContent;
import diff.util.MergeConflictType;
import diff.util.ThreeSide;
import ds.BiPredicate;
import ds.BooleanSupplier;
import ds.Predicate;

class MergeRangeUtil {
	static public function getMergeType(emptiness:Predicate<ThreeSide>, equality:BiPredicate<ThreeSide, ThreeSide>,
			trueEquality:Null<BiPredicate<ThreeSide, ThreeSide>>, conflictResolver:BooleanSupplier) {
		var isLeftEmpty:Bool = emptiness.test(ThreeSide.fromEnum(ThreeSideEnum.LEFT));
		var isBaseEmpty:Bool = emptiness.test(ThreeSide.fromEnum(ThreeSideEnum.BASE));
		var isRightEmpty:Bool = emptiness.test(ThreeSide.fromEnum(ThreeSideEnum.RIGHT));
		// assert !isLeftEmpty || !isBaseEmpty || !isRightEmpty;

		if (isBaseEmpty) {
			if (isLeftEmpty) { // --=
				return new MergeConflictType(MergeConflictTypeEnum.INSERTED, false, true);
			} else if (isRightEmpty) { // =--
				return new MergeConflictType(MergeConflictTypeEnum.INSERTED, true, false);
			} else { // =-=
				var equalModifications:Bool = equality.test(ThreeSide.fromEnum(ThreeSideEnum.LEFT), ThreeSide.fromEnum(ThreeSideEnum.RIGHT));
				if (equalModifications) {
					return new MergeConflictType(MergeConflictTypeEnum.INSERTED, true, true);
				} else {
					return new MergeConflictType(MergeConflictTypeEnum.CONFLICT, true, true, false);
				}
			}
		} else {
			if (isLeftEmpty && isRightEmpty) { // -=-
				return new MergeConflictType(MergeConflictTypeEnum.DELETED, true, true);
			} else { // -==, ==-, ===
				var unchangedLeft:Bool = equality.test(ThreeSide.fromEnum(ThreeSideEnum.BASE), ThreeSide.fromEnum(ThreeSideEnum.LEFT));
				var unchangedRight:Bool = equality.test(ThreeSide.fromEnum(ThreeSideEnum.BASE), ThreeSide.fromEnum(ThreeSideEnum.RIGHT));

				if (unchangedLeft && unchangedRight) {
					// assert trueEquality != null;
					var trueUnchangedLeft:Bool = trueEquality.test(ThreeSide.fromEnum(ThreeSideEnum.BASE), ThreeSide.fromEnum(ThreeSideEnum.LEFT));
					var trueUnchangedRight:Bool = trueEquality.test(ThreeSide.fromEnum(ThreeSideEnum.BASE), ThreeSide.fromEnum(ThreeSideEnum.RIGHT));
					// assert !trueUnchangedLeft || !trueUnchangedRight;
					return new MergeConflictType(MergeConflictTypeEnum.MODIFIED, !trueUnchangedLeft, !trueUnchangedRight);
				}

				if (unchangedLeft) {
					return new MergeConflictType(isRightEmpty ? MergeConflictTypeEnum.DELETED : MergeConflictTypeEnum.MODIFIED, false, true);
				}
				if (unchangedRight) {
					return new MergeConflictType(isLeftEmpty ? MergeConflictTypeEnum.DELETED : MergeConflictTypeEnum.MODIFIED, true, false);
				}

				var equalModifications:Bool = equality.test(ThreeSide.fromEnum(ThreeSideEnum.LEFT), ThreeSide.fromEnum(ThreeSideEnum.RIGHT));
				if (equalModifications) {
					return new MergeConflictType(MergeConflictTypeEnum.MODIFIED, true, true);
				} else {
					var canBeResolved:Bool = !isLeftEmpty && !isRightEmpty && conflictResolver.getAsBoolean();
					return new MergeConflictType(MergeConflictTypeEnum.CONFLICT, true, true, canBeResolved);
				}
			}
		}
	}

	static public function getLineThreeWayDiffType(fragment:MergeLineFragment, sequences:Array<String>, lineOffsets:Array<LineOffsets>,
			policy:ComparisonPolicy):MergeConflictType {
		return getMergeType(new Predicate((side) -> isLineMergeIntervalEmpty(fragment, side)),
			new BiPredicate((side1, side2) -> compareLineMergeContents(fragment, sequences, lineOffsets, policy, side1, side2)), null,
			new BooleanSupplier(() -> canResolveLineConflict(fragment, sequences, lineOffsets)));
	}

	static public function getLineMergeType(fragment:MergeLineFragment, sequences:Array<String>, lineOffsets:Array<LineOffsets>,
			policy:ComparisonPolicy):MergeConflictType {
		return getMergeType(new Predicate((side) -> isLineMergeIntervalEmpty(fragment, side)),
			new BiPredicate((side1, side2) -> compareLineMergeContents(fragment, sequences, lineOffsets, policy, side1, side2)),
			new BiPredicate((side1, side2) -> compareLineMergeContents(fragment, sequences, lineOffsets, ComparisonPolicy.DEFAULT, side1, side2)),
			new BooleanSupplier(() -> canResolveLineConflict(fragment, sequences, lineOffsets)));
	}

	static private function canResolveLineConflict(fragment:MergeLineFragment, sequences:Array<String>, lineOffsets:Array<LineOffsets>):Bool {
		var contents:Array<String> = [ThreeSideEnum.LEFT, ThreeSideEnum.BASE, ThreeSideEnum.RIGHT].map(side -> getLinesContent(ThreeSide.fromEnum(side)
			.selectC(sequences), ThreeSide.fromEnum(side).selectC(lineOffsets), fragment.getStartLine(ThreeSide.fromEnum(side)),
			fragment.getEndLine(ThreeSide.fromEnum(side))));
		return ComparisonMergeUtil.tryResolveConflict(contents[0], contents[1], contents[2]) != null;
	}

	static private function compareLineMergeContents(fragment:MergeLineFragment, sequences:Array<String>, lineOffsets:Array<LineOffsets>,
			policy:ComparisonPolicy, side1:ThreeSide, side2:ThreeSide):Bool {
		var start1:Int = fragment.getStartLine(side1);
		var end1:Int = fragment.getEndLine(side1);
		var start2:Int = fragment.getStartLine(side2);
		var end2:Int = fragment.getEndLine(side2);

		if (end2 - start2 != end1 - start1) {
			return false;
		}

		var sequence1:String = side1.selectC(sequences);
		var sequence2:String = side2.selectC(sequences);
		var offsets1:LineOffsets = side1.selectC(lineOffsets);
		var offsets2:LineOffsets = side2.selectC(lineOffsets);

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

	static public function getWordMergeType(fragment:MergeWordFragment, texts:Array<String>, policy:ComparisonPolicy):MergeConflictType {
		return getMergeType(new Predicate((side) -> isWordMergeIntervalEmpty(fragment, side)),
			new BiPredicate((side1, side2) -> compareWordMergeContents(fragment, texts, policy, side1, side2)), null, new BooleanSupplier(() -> false));
	}

	static public function compareWordMergeContents(fragment:MergeWordFragment, texts:Array<String>, policy:ComparisonPolicy, side1:ThreeSide,
			side2:ThreeSide):Bool {
		var start1:Int = fragment.getStartOffset(side1);
		var end1:Int = fragment.getEndOffset(side1);
		var start2:Int = fragment.getStartOffset(side2);
		var end2:Int = fragment.getEndOffset(side2);

		var document1:String = side1.selectC(texts);
		var document2:String = side2.selectC(texts);

		var content1:String = document1.substring(start1, end1);
		var content2:String = document2.substring(start2, end2);
		return ComparisonUtil.isEqualTexts(content1, content2, policy);
	}

	static private function isWordMergeIntervalEmpty(fragment:MergeWordFragment, side:ThreeSide):Bool {
		return fragment.getStartOffset(side) == fragment.getEndOffset(side);
	}

	static public function getLineLeftToRightThreeSideDiffType(fragment:MergeLineFragment, sequences:Array<String>, lineOffsets:Array<LineOffsets>,
			policy:ComparisonPolicy):MergeConflictType {
		return getLeftToRightDiffType(new Predicate((side) -> isLineMergeIntervalEmpty(fragment, ThreeSide.fromEnum(side))),
			new BiPredicate((side1,
					side2) -> compareLineMergeContents(fragment, sequences, lineOffsets, policy, ThreeSide.fromEnum(side1), ThreeSide.fromEnum(side2))));
	}

	static private function getLeftToRightDiffType(emptiness:Predicate<ThreeSideEnum>, equality:BiPredicate<ThreeSideEnum, ThreeSideEnum>):MergeConflictType {
		var isLeftEmpty:Bool = emptiness.test(ThreeSideEnum.LEFT);
		var isBaseEmpty:Bool = emptiness.test(ThreeSideEnum.BASE);
		var isRightEmpty:Bool = emptiness.test(ThreeSideEnum.RIGHT);

		// assert! isLeftEmpty || !isBaseEmpty || !isRightEmpty;

		if (isBaseEmpty) {
			if (isLeftEmpty) { // --=
				return new MergeConflictType(MergeConflictTypeEnum.INSERTED, false, true);
			} else if (isRightEmpty) { // =--
				return new MergeConflictType(MergeConflictTypeEnum.DELETED, true, false);
			} else { // =-=
				return new MergeConflictType(MergeConflictTypeEnum.MODIFIED, true, true);
			}
		} else {
			if (isLeftEmpty && isRightEmpty) { // -=-
				return new MergeConflictType(MergeConflictTypeEnum.MODIFIED, true, true);
			} else { // -==, ==-, ===
				var unchangedLeft:Bool = equality.test(ThreeSideEnum.BASE, ThreeSideEnum.LEFT);
				var unchangedRight:Bool = equality.test(ThreeSideEnum.BASE, ThreeSideEnum.RIGHT);
				// assert! unchangedLeft || !unchangedRight;

				if (unchangedLeft) {
					return new MergeConflictType(isRightEmpty ? MergeConflictTypeEnum.DELETED : MergeConflictTypeEnum.MODIFIED, false, true);
				}
				if (unchangedRight) {
					return new MergeConflictType(isLeftEmpty ? MergeConflictTypeEnum.INSERTED : MergeConflictTypeEnum.MODIFIED, true, false);
				}

				return new MergeConflictType(MergeConflictTypeEnum.MODIFIED, true, true);
			}
		}
	}
}
