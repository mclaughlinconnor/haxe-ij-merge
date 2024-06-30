package diff.tools.util.text;

import diff.util.Side;
import diff.util.Side.SideEnum;
import diff.util.DiffRangeUtil;
import diff.util.DiffUtil;
import diff.util.ThreeSide;
import diff.util.MergeRangeUtil;
import diff.tools.util.base.HighlightPolicy;
import config.IgnorePolicy;
import diff.util.MergeConflictType;
import diff.fragments.MergeLineFragment;
import diff.comparison.ComparisonManager;
import diff.comparison.ComparisonPolicy;
import diff.util.MergeConflictType.MergeConflictTypeEnum;
import diff.util.DiffUserDataKeys.ThreeSideDiffColors;
import diff.tools.util.base.HighlightPolicy.HighlightPolicyEnum;
import config.IgnorePolicy.IgnorePolicyEnum;

class SimpleThreesideTextDiffProvider extends TextDiffProviderBase {
	private static final IGNORE_POLICIES:Array<IgnorePolicyEnum> = [DEFAULT, TRIM_WHITESPACES, IGNORE_WHITESPACES];
	private static final HIGHLIGHT_POLICIES:Array<HighlightPolicyEnum> = [BY_LINE, BY_WORD];

	private final myColorsMode:ThreeSideDiffColors;

	public function new(/*settings:TextDiffSettings,*/ colorsMode:ThreeSideDiffColors /*, rediff:Runnable, disposable:Disposable*/) {
		super(/*settings, rediff, disposable, */ IGNORE_POLICIES, HIGHLIGHT_POLICIES);
		myColorsMode = colorsMode;
	}

	public function compare(text1:String, text2:String, text3:String /*, indicator:ProgressIndicator*/):Array<FineMergeLineFragment> {
		var ignorePolicy:IgnorePolicy = getIgnorePolicy();
		var highlightPolicy:HighlightPolicy = getHighlightPolicy();
		var comparisonPolicy:ComparisonPolicy = ignorePolicy.getComparisonPolicy();

		var sequences:Array<String> = [text1, text2, text3];
		var lineOffsets:Array<LineOffsets> = sequences.map(LineOffsetsUtil.createB);

		// indicator.checkCanceled();
		var lineFragments:Array<MergeLineFragment> = ComparisonManager.getInstance().compareLinesB(text1, text2, text3, comparisonPolicy /*, indicator*/);

		// indicator.checkCanceled();
		var result:Array<FineMergeLineFragment> = [];
		for (fragment in lineFragments) {
			var conflictType:MergeConflictType = getConflictType(comparisonPolicy, sequences, lineOffsets, fragment);

			var innerDifferences:MergeInnerDifferences;
			if (highlightPolicy.isFineFragments()) {
				var chunks:Array<String> = getChunks(fragment, sequences, lineOffsets, conflictType);

				innerDifferences = DiffUtil.compareThreesideInner(chunks, comparisonPolicy /*, indicator*/);
			} else {
				innerDifferences = null;
			}
			result.push(new FineMergeLineFragment(fragment, conflictType, innerDifferences));
		}
		return result;
	}

	private function getConflictType(comparisonPolicy:ComparisonPolicy, sequences:Array<String>, lineOffsets:Array<LineOffsets>,
			fragment:MergeLineFragment):MergeConflictType {
		switch myColorsMode {
			case MERGE_CONFLICT:
				return MergeRangeUtil.getLineThreeWayDiffType(fragment, sequences, lineOffsets, comparisonPolicy);
			case MERGE_RESULT:
				var conflictType:MergeConflictType = MergeRangeUtil.getLineThreeWayDiffType(fragment, sequences, lineOffsets, comparisonPolicy);
				return invertConflictType(conflictType);
			case LEFT_TO_RIGHT:
				return MergeRangeUtil.getLineLeftToRightThreeSideDiffType(fragment, sequences, lineOffsets, comparisonPolicy);
		};
	}

	private static function getChunks(fragment:MergeLineFragment, sequences:Array<String>, lineOffsets:Array<LineOffsets>,
			conflictType:MergeConflictType):Array<String> {
		function f(side:ThreeSide) {
			if (!conflictType.isChangeB(ThreeSide.fromIndex(side.getIndex()))) {
				return null;
			}

			var startLine:Int = fragment.getStartLine(side);
			var endLine:Int = fragment.getEndLine(side);
			if (startLine == endLine)
				return null;

			return DiffRangeUtil.getLinesContent(side.selectC(sequences), side.selectC(lineOffsets), startLine, endLine);
		}
		return ThreeSide.map(f);
	}

	private static function invertConflictType(oldConflictType:MergeConflictType):MergeConflictType {
		var oldDiffType:MergeConflictTypeEnum = oldConflictType.getType();

		if (oldDiffType != MergeConflictTypeEnum.INSERTED && oldDiffType != MergeConflictTypeEnum.DELETED) {
			return oldConflictType;
		}

		return new MergeConflictType(oldDiffType == MergeConflictTypeEnum.DELETED ? MergeConflictTypeEnum.INSERTED : MergeConflictTypeEnum.DELETED,
			oldConflictType.isChangeA(Side.fromEnum(SideEnum.LEFT)), oldConflictType.isChangeA(Side.fromEnum(SideEnum.RIGHT)), oldConflictType.canBeResolved());
	}
}
