// Copyright 2000-2024 JetBrains s.r.o. and contributors. Use of this source code is governed by the Apache 2.0 license.
package diff.merge;

import exceptions.ProcessCanceledException;
import diff.comparison.DiffTooBigException;
import diff.util.MergeRangeUtil;
import diff.tools.util.text.LineOffsetsUtil;
import diff.tools.util.text.LineOffsets;
import diff.tools.util.base.HighlightPolicy.HighlightPolicyEnum;
import util.Runnable;
import diff.tools.util.text.LineRange;
import diff.util.MergeConflictType;
import diff.comparison.ComparisonManager;
import tokenizers.LineTokenizer;
import diff.comparison.ComparisonMergeUtil;
import diff.fragments.MergeLineFragment;
import diff.util.Side;
import diff.util.Side.SideEnum;
import diff.util.ThreeSide;
import diff.util.DiffUtil;
import config.IgnorePolicy;
import diff.fragments.TextMergeChange;
import diff.tools.util.text.TextDiffProviderBase;

class MergeThreesideViewer extends ThreesideTextDiffViewerEx {
	public final myModel:MergeModelBase<TextMergeChangeState>;

	private final myMergeRequest:Array<String>;
	private final myTextDiffProvider:TextDiffProviderBase;

	private var myAllMergeChanges:Array<TextMergeChange> = []; // all changes - both applied and unapplied ones
	private var myCurrentIgnorePolicy:IgnorePolicy;

	public function new(request:Array<String>, resultDocument:String) {
		myMergeRequest = request;

		myModel = new MyMergeModel(resultDocument, myAllMergeChanges, this.onChangeResolved, this.markChangeResolvedA);
		myTextDiffProvider = new TextDiffProviderBase([
			IgnorePolicyEnum.DEFAULT,
			IgnorePolicyEnum.TRIM_WHITESPACES,
			IgnorePolicyEnum.IGNORE_WHITESPACES
		], [HighlightPolicyEnum.BY_LINE, HighlightPolicyEnum.BY_WORD]);
	}

	private function doFinishMerge(result:MergeResult):Void {
		destroyChangedBlocks();
	}

	private override function destroyChangedBlocks():Void {
		myAllMergeChanges = [];
		myModel.setChanges([]);
	}

	//
	// Diff
	//

	public function rediff(trySync:Bool):Void {
		doRediff();
	}

	private function doRediff():Void {
		return doPerformRediff()();
	}

	private function doPerformRediff():Runnable {
		try {
			var sequences:Array<String> = [];
			var ignorePolicy:IgnorePolicy = myTextDiffProvider.getIgnorePolicy();
			var contents:Array<String> = myMergeRequest;

			for (seq in contents) {
				sequences.push(seq);
			}

			var lineFragments:MergeLineFragmentsWithImportMetadata = getLineFragments(sequences, ignorePolicy);
			var lineOffsets:Array<LineOffsets> = sequences.map((seq) -> LineOffsetsUtil.createB(seq));
			var conflictTypes:Array<MergeConflictType> = lineFragments.map((fragment) -> MergeRangeUtil.getLineMergeType(fragment, sequences, lineOffsets,
				IgnorePolicy.getComparisonPolicyB(IgnorePolicyEnum.DEFAULT)));

			return () -> apply(ThreeSide.fromEnum(ThreeSideEnum.BASE).selectC(sequences), lineFragments, conflictTypes, ignorePolicy);
		} catch (e:DiffTooBigException) {
			return () -> trace("Diff too big");
		} catch (e:ProcessCanceledException) {
			throw e;
		} catch (e:Dynamic) {
			throw e;
		}
	}

	public function getContentString(side:ThreeSide):String {
		return side.selectC(getContents());
	}

	public function getContents():Array<String> {
		return myMergeRequest;
	}

	private static function getLineFragments(sequences:Array<String>, ignorePolicy:IgnorePolicy):MergeLineFragmentsWithImportMetadata {
		var manager:ComparisonManager = ComparisonManager.getInstance();

		var fragments:Array<MergeLineFragment> = manager.mergeLines(sequences[0], sequences[1], sequences[2], ignorePolicy.getComparisonPolicyA());
		return new MergeLineFragmentsWithImportMetadata(fragments);
	}

	private function apply(baseContent:String, fragmentsWithMetadata:MergeLineFragmentsWithImportMetadata, conflictTypes:Array<MergeConflictType>,
			ignorePolicy:IgnorePolicy):Void {
		resetChangeCounters();

		var fragments:Array<MergeLineFragment> = fragmentsWithMetadata.getFragments();

		myModel.setChanges(fragments.map((f) -> new LineRange(f.getStartLine(ThreeSide.fromEnum(ThreeSideEnum.BASE)),
			f.getEndLine(ThreeSide.fromEnum(ThreeSideEnum.BASE)))));

		for (index in 0...fragments.length) {
			var fragment:MergeLineFragment = fragments[index];
			var conflictType:MergeConflictType = conflictTypes[index];

			var isInImportRange:Bool = fragmentsWithMetadata.isIndexInImportRange(index);
			var change:TextMergeChange = new TextMergeChange(index, isInImportRange, fragment, conflictType, myModel);

			myAllMergeChanges.push(change);
			onChangeAdded(change);
		}

		myCurrentIgnorePolicy = ignorePolicy;

		if (DiffConfig.AUTO_APPLY_NON_CONFLICTED_CHANGES) {
			if (hasNonConflictedChanges(ThreeSide.fromEnum(ThreeSideEnum.BASE))) {
				applyNonConflictedChanges(ThreeSide.fromEnum(ThreeSideEnum.BASE));
			}
		}
	}

	private function onChangeResolved(change:TextMergeChange):Void {
		if (change.isResolvedA()) {
			onChangeRemoved(change);
		} else {
			onChangeAdded(change);
		}

		if (getChangesCount() == 0 && getConflictsCount() == 0) {
			doFinishMerge(MergeResult.RESOLVED);
		}
	}

	//
	// Getters
	//

	public function getChanges():Array<TextMergeChange> {
		return myAllMergeChanges.filter((mergeChange) -> !mergeChange.isResolvedA());
	}

	/*
	 * affected changes should be sorted
	 */
	public function executeMergeCommandA(commandName:String, underBulkUpdate:Bool, affected:Null<Array<TextMergeChange>>, task:Runnable):Bool {
		var affectedIndexes:Array<Int> = null;
		if (affected != null) {
			affectedIndexes = [];
			for (change in affected) {
				affectedIndexes.push(change.getIndex());
			}
		}

		return myModel.executeMergeCommand(commandName, null, underBulkUpdate, affectedIndexes, task);
	}

	public function executeMergeCommandB(commandName:String, affected:Null<Array<TextMergeChange>>, task:Runnable):Bool {
		return executeMergeCommandA(commandName, false, affected, task);
	}

	public function markChangeResolvedA(change:TextMergeChange):Void {
		if (change.isResolvedA())
			return;
		change.setResolved(Side.fromEnum(SideEnum.LEFT), true);
		change.setResolved(Side.fromEnum(SideEnum.RIGHT), true);

		onChangeResolved(change);
	}

	public function markChangeResolvedB(change:TextMergeChange, side:Side):Void {
		if (change.isResolvedB(side))
			return;
		change.setResolved(side, true);

		if (change.isResolvedA())
			onChangeResolved(change);
	}

	public function ignoreChange(change:TextMergeChange, side:Side, resolveChange:Bool):Void {
		if (!change.isConflict() || resolveChange) {
			markChangeResolvedA(change);
		} else {
			markChangeResolvedB(change, side);
		}
	}

	public function replaceChange(change:TextMergeChange, side:Side, resolveChange:Bool):LineRange {
		if (change.isResolvedB(side))
			return null;
		if (!change.isChangeA(side)) {
			markChangeResolvedA(change);
			return null;
		}

		var sourceSide:ThreeSide = side.selectA(ThreeSide.fromEnum(ThreeSideEnum.LEFT), ThreeSide.fromEnum(ThreeSideEnum.RIGHT));
		var oppositeSide:ThreeSide = side.selectA(ThreeSide.fromEnum(ThreeSideEnum.RIGHT), ThreeSide.fromEnum(ThreeSideEnum.LEFT));

		// var sourceDocument:String = getContent(sourceSide).getDocument();
		var sourceDocument:String = getContentString(sourceSide);
		var sourceStartLine:Int = change.getStartLineB(ThreeSide.fromIndex(sourceSide.getIndex()));
		var sourceEndLine:Int = change.getEndLineB(sourceSide);
		var newContent:Array<String> = DiffUtil.getLinesB(sourceDocument, sourceStartLine, sourceEndLine);

		var newLineStart:Int;
		if (change.isConflict()) {
			var append:Bool = change.isOnesideAppliedConflict();
			if (append) {
				newLineStart = myModel.getLineEnd(change.getIndex());
				myModel.appendChange(change.getIndex(), newContent);
			} else {
				myModel.replaceChange(change.getIndex(), newContent);
				newLineStart = myModel.getLineStart(change.getIndex());
			}

			if (resolveChange || change.getStartLineB(ThreeSide.fromIndex(oppositeSide.getIndex())) == change.getEndLineB(oppositeSide)) {
				markChangeResolvedA(change);
			} else {
				change.markOnesideAppliedConflict();
				markChangeResolvedB(change, side);
			}
		} else {
			myModel.replaceChange(change.getIndex(), newContent);
			newLineStart = myModel.getLineStart(change.getIndex());
			markChangeResolvedA(change);
		}
		var newLineEnd:Int = myModel.getLineEnd(change.getIndex());
		return new LineRange(newLineStart, newLineEnd);
	}

	private function resetResolvedChange(change:TextMergeChange):Void {
		if (!change.isResolvedA())
			return;
		var changeFragment:MergeLineFragment = change.getFragment();
		var startLine:Int = changeFragment.getStartLine(ThreeSide.fromEnum(ThreeSideEnum.BASE));
		var endLine:Int = changeFragment.getEndLine(ThreeSide.fromEnum(ThreeSideEnum.BASE));

		// var content:Document = ThreeSide.fromEnum(ThreeSideEnum.BASE).selectC(myMergeRequest.getContents()).getDocument();
		var content:String = ThreeSide.fromEnum(ThreeSideEnum.BASE).selectC(myMergeRequest);
		var baseContent:Array<String> = DiffUtil.getLinesB(content, startLine, endLine);

		myModel.replaceChange(change.getIndex(), baseContent);

		change.resetState();
		onChangeResolved(change);
	}

	//
	// Actions
	//

	private function hasNonConflictedChanges(side:ThreeSide):Bool {
		return getAllChanges().filter(function(change) {
			return !change.isConflict() && canResolveChangeAutomatically(change, side);
		}).length != 0;
	}

	private function applyNonConflictedChanges(side:ThreeSide):Void {
		executeMergeCommandA("merge.dialog.apply.non.conflicted.changes.command", true, null,
			() -> resolveChangesAutomatically(getAllChanges().filter((change) -> !change.isConflict()), side));

		var firstUnresolved:TextMergeChange;
		for (change in getAllChanges()) {
			if (!change.isResolvedA()) {
				firstUnresolved = change;
				break;
			}
		}
	}

	private function hasResolvableConflictedChanges():Bool {
		for (change in getAllChanges()) {
			if (canResolveChangeAutomatically(change, ThreeSide.fromEnum(ThreeSideEnum.BASE))) {
				return true;
			}
		}

		return false;
	}

	public function applyResolvableConflictedChanges():Void {
		var changes:Array<TextMergeChange> = getAllChanges();
		executeMergeCommandA("message.resolve.simple.conflicts.command", true, null,
			() -> resolveChangesAutomatically(changes, ThreeSide.fromEnum(ThreeSideEnum.BASE)));

		var firstUnresolved:TextMergeChange;
		for (change in getAllChanges()) {
			if (!change.isResolvedA()) {
				firstUnresolved = change;
				break;
			}
		}
	}

	public function canResolveChangeAutomatically(change:TextMergeChange, side:ThreeSide):Bool {
		if (change.isConflict()) {
			return ThreeSide.fromIndex(side.getIndex()) == ThreeSideEnum.BASE
				&& change.getConflictType().canBeResolved()
				&& !change.isResolvedB(Side.fromEnum(SideEnum.LEFT))
				&& !change.isResolvedB(Side.fromEnum(SideEnum.RIGHT))
				&& !isChangeRangeModified(change);
		} else {
			return !change.isResolvedA() && change.isChangeB(ThreeSide.fromIndex(side.getIndex())) && !isChangeRangeModified(change);
		}
	}

	public function isChangeRangeModified(change:TextMergeChange):Bool {
		var changeFragment:MergeLineFragment = change.getFragment();
		var baseStartLine:Int = changeFragment.getStartLine(ThreeSide.fromEnum(ThreeSideEnum.BASE));
		var baseEndLine:Int = changeFragment.getEndLine(ThreeSide.fromEnum(ThreeSideEnum.BASE));
		var baseDiffContent:String = ThreeSide.fromEnum(ThreeSideEnum.BASE).selectC(myMergeRequest);
		// var baseDocument:Document = baseDiffContent.getDocument();

		var resultStartLine:Int = change.getStartLineA();
		var resultEndLine:Int = change.getEndLineA();
		// var resultDocument:String = getEditor().getDocument();

		var baseContent:String = DiffUtil.getLinesContentA(/*baseDocument*/ baseDiffContent, baseStartLine, baseEndLine);
		var resultContent:String = DiffUtil.getLinesContentA(myModel.getDocument(), resultStartLine, resultEndLine);
		return baseContent != resultContent;
	}

	public function resolveChangesAutomatically(changes:Array<TextMergeChange>, threeSide:ThreeSide):Void {
		processChangesAndTransferData(changes, threeSide, function(change) {
			return resolveChangeAutomatically(change, threeSide);
		});
	}

	public function resolveSingleChangeAutomatically(change:TextMergeChange, side:ThreeSide):Void {
		resolveChangesAutomatically([change], side);
	}

	public function replaceChanges(changes:Array<TextMergeChange>, side:Side, resolveChanges:Bool):Void {
		processChangesAndTransferData(changes, side.selectA(ThreeSide.fromEnum(ThreeSideEnum.LEFT), ThreeSide.fromEnum(ThreeSideEnum.RIGHT)),
			(change) -> replaceChange(change, side, resolveChanges));
	}

	public function replaceSingleChange(change:TextMergeChange, side:Side, resolveChange:Bool):Void {
		replaceChanges([change], side, resolveChange);
	}

	private function processChangesAndTransferData(changes:Array<TextMergeChange>, side:ThreeSide, processor:TextMergeChange->LineRange):Void {
		var newRanges:Array<LineRange> = [];
		var filteredChanges:Array<TextMergeChange> = [];

		for (change in changes) {
			if (change.isImportChange()) {
				continue;
			}
			var newRange:LineRange = processor(change);
			if (newRange != null) {
				newRanges.push(newRange);
				filteredChanges.push(change);
			}
		}
	}

	public function resolveChangeAutomatically(change:TextMergeChange, side:ThreeSide):LineRange {
		if (!canResolveChangeAutomatically(change, side))
			return null;

		if (change.isConflict()) {
			var texts:Array<String> = ThreeSide.map(function(it) {
				var d = it.selectC([myMergeRequest[0], myModel.getDocument(), myMergeRequest[2]]); // left, current middle, right
				var side = ThreeSide.fromIndex(it.getIndex());
				var startline = change.getStartLineB(side);
				var endline = change.getEndLineB(it);

				return DiffUtil.getLinesContentA(d, startline, endline);
			});

			var newContent:String = ComparisonMergeUtil.tryResolveConflict(texts[0], texts[1], texts[2]);
			if (newContent == null) {
				trace('Can\'t resolve conflicting change:\n"${texts[0]}"\n"${texts[1]}"\n"${texts[2]}"\n');
				return null;
			}

			var newContentLines:Array<String> = LineTokenizer.tokenizeA(newContent, false);
			myModel.replaceChange(change.getIndex(), newContentLines);
			markChangeResolvedA(change);
			return new LineRange(myModel.getLineStart(change.getIndex()), myModel.getLineEnd(change.getIndex()));
		} else {
			var masterSide = (side).selectA(SideEnum.LEFT, change.isChangeA(Side.fromEnum(SideEnum.LEFT)) ? SideEnum.LEFT : SideEnum.RIGHT, SideEnum.RIGHT);
			return replaceChange(change, Side.fromEnum(masterSide), false);
		}
	}
}

class MyMergeModel extends MergeModelBase<TextMergeChangeState> {
	private final myAllMergeChanges:Array<TextMergeChange>;
	private final onChangeResolved:TextMergeChange->Void;
	private final markChangeResolvedA:TextMergeChange->Void;

	public function new(document:String, myAllMergeChanges:Array<TextMergeChange>, onChangeResolved:TextMergeChange->Void,
			markChangeResolvedA:TextMergeChange->Void) {
		super(document);
		this.onChangeResolved = onChangeResolved;
		this.markChangeResolvedA = markChangeResolvedA;
		this.myAllMergeChanges = myAllMergeChanges;
	}

	private function storeChangeState(index:Int):TextMergeChangeState {
		var change:TextMergeChange = myAllMergeChanges[index];
		return change.storeState();
	}

	private override function processDocumentChange(index:Int, oldLine1:Int, oldLine2:Int, shift:Int):TextMergeChangeState {
		var state:TextMergeChangeState = super.processDocumentChange(index, oldLine1, oldLine2, shift);

		var mergeChange:TextMergeChange = myAllMergeChanges[index];
		if (mergeChange.getStartLineA() == mergeChange.getEndLineA()
			&& mergeChange.getConflictType().getType() == MergeConflictTypeEnum.DELETED
			&& !mergeChange.isResolvedA()) {
			markChangeResolvedA(mergeChange);
		}

		return state;
	}
}
