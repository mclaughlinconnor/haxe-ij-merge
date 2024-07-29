// Copyright 2000-2024 JetBrains s.r.o. and contributors. Use of this source code is governed by the Apache 2.0 license.
package diff.merge;

import exceptions.ProcessCanceledException;
import diff.comparison.DiffTooBigException;
import diff.util.MergeRangeUtil;
import diff.tools.util.text.LineOffsetsUtil;
import diff.tools.util.text.LineOffsets;
import diff.util.MergeRange;
import diff.tools.util.base.HighlightPolicy.HighlightPolicyEnum;
import util.Runnable;
import diff.tools.util.text.LineRange;
import diff.fragments.ThreesideDiffChangeBase;
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
	private final myModel:MergeModelBase<TextMergeChangeState>;

	private final myResultDocument:String;

	// private final myDocuments:Array<String>;
	// private final myModifierProvider:ModifierProvider;
	// private final myInnerDiffWorker:MyInnerDiffWorker;
	// private final myLineStatusTracker: SimpleLineStatusTracker ;
	private final myTextDiffProvider:TextDiffProviderBase;

	// all changes - both applied and unapplied ones
	private final myAllMergeChanges:Array<TextMergeChange> = [];
	private var myCurrentIgnorePolicy:IgnorePolicy;

	// private var myInitialRediffStarted:Bool;
	// private var myInitialRediffFinished:Bool;
	// private var myContentModified:Bool;
	// private var myResolveImportConflicts:Bool;
	// private var myPsiFiles:List<PsiFile> = new ArrayList<>();
	// private final myCancelResolveAction:Action;
	// private final myLeftResolveAction:Action;
	// private final myRightResolveAction:Action;
	// private final myAcceptResolveAction:Action;
	// private var myAggregator:MergeStatisticsAggregator;
	// private final myMergeContext:MergeContext;
	// private final myMergeRequest:TextMergeRequest;
	private final myMergeRequest:Array<String>;

	// private final myTextMergeViewer:TextMergeViewer;

	public function new(/*context:DiffContext, */ request:Array<String>, /*, mergeContext:MergeContext, mergeRequest:TextMergeRequest*/ /*,
		mergeViewer:TextMergeViewer */ resultDocument:String /*, documents:Array<String>*/) {
		super(/*context,*/ request);
		myResultDocument = resultDocument;
		// myDocuments = documents;
		// myMergeContext = mergeContext;
		myMergeRequest = request;
		// myTextMergeViewer = mergeViewer;

		myModel = new MyMergeModel(/*getProject(), */ myResultDocument, myAllMergeChanges, this.onChangeResolved, this.markChangeResolvedA);

		// myModifierProvider = new ModifierProvider();
		// myInnerDiffWorker = new MyInnerDiffWorker();

		// myLineStatusTracker = new SimpleLineStatusTracker(getProject(), getEditor().getDocument(), MyLineStatusMarkerRenderer::new);

		myTextDiffProvider = new TextDiffProviderBase(/*getTextSettings(), function() {
			restartMergeResolveIfNeeded();
			myInnerDiffWorker.onSettingsChanged();
		}, this,*/ [
			IgnorePolicyEnum.DEFAULT,
			IgnorePolicyEnum.TRIM_WHITESPACES,
			IgnorePolicyEnum.IGNORE_WHITESPACES
		], [HighlightPolicyEnum.BY_LINE, HighlightPolicyEnum.BY_WORD]);

		// getTextSettings().addListener(new TextDiffSettingsHolder.TextDiffSettings.Listener() {
		//   @Override
		//   public Void resolveConflictsInImportsChanged() {
		//     restartMergeResolveIfNeeded();
		//   }
		// }, this);
		// myCurrentIgnorePolicy = myTextDiffProvider.getIgnorePolicy();
		// myResolveImportConflicts = getTextSettings().isAutoResolveImportConflicts();
		// myCancelResolveAction = getResolveAction(MergeResult.CANCEL);
		// myLeftResolveAction = getResolveAction(MergeResult.LEFT);
		// myRightResolveAction = getResolveAction(MergeResult.RIGHT);
		// myAcceptResolveAction = getResolveAction(MergeResult.RESOLVED);

		// DiffUtil.registerAction(new NavigateToChangeMarkerAction(false), myPanel);
		// DiffUtil.registerAction(new NavigateToChangeMarkerAction(true), myPanel);

		// ProxyUndoRedoAction.register(getProject(), getEditor(), myContentPanel);
	}

	// @Override
	// private function StatusPanel createStatusPanel() {
	//   return new MyMergeStatusPanel();
	// }
	//
	// @Override
	// private function Void onInit() {
	//   super.onInit();
	//   myModifierProvider.init();
	// }
	//
	// @Override
	// private function Void onDispose() {
	//   Disposer.dispose(myModel);
	//   myLineStatusTracker.release();
	//   myInnerDiffWorker.disable();
	//   super.onDispose();
	// }
	//
	// @Override
	// private function List<TextEditorHolder> createEditorHolders(EditorHolderFactory<TextEditorHolder> factory) {
	//   List<TextEditorHolder> holders = super.createEditorHolders(factory);
	//   ThreeSide.BASE.select(holders).getEditor().putUserData(DiffUserDataKeys.MERGE_EDITOR_FLAG, true);
	//   return holders;
	// }
	//
	//
	// @NotNull
	// @Override
	// private function List<AnAction> createToolbarActions() {
	//   List<AnAction> group = new ArrayList<>();
	//
	//   DefaultActionGroup diffGroup = DefaultActionGroup.createPopupGroup(() -> ActionsBundle.message("group.compare.contents.text"));
	//   diffGroup.getTemplatePresentation().setIcon(AllIcons.Actions.Diff);
	//   diffGroup.add(Separator.create(ActionsBundle.message("group.compare.contents.text")));
	//   diffGroup.add(new TextShowPartialDiffAction(PartialDiffMode.LEFT_MIDDLE, true));
	//   diffGroup.add(new TextShowPartialDiffAction(PartialDiffMode.RIGHT_MIDDLE, true));
	//   diffGroup.add(new TextShowPartialDiffAction(PartialDiffMode.LEFT_RIGHT, true));
	//   diffGroup.add(new ShowDiffWithBaseAction(ThreeSide.LEFT));
	//   diffGroup.add(new ShowDiffWithBaseAction(ThreeSide.BASE));
	//   diffGroup.add(new ShowDiffWithBaseAction(ThreeSide.RIGHT));
	//   group.add(diffGroup);
	//
	//   group.add(new Separator(DiffBundle.messagePointer("action.Anonymous.text.apply.non.conflicting.changes")));
	//   group.add(new ApplyNonConflictsAction(ThreeSide.LEFT, DiffBundle.message("action.merge.apply.non.conflicts.left.text")));
	//   group.add(new ApplyNonConflictsAction(ThreeSide.BASE, DiffBundle.message("action.merge.apply.non.conflicts.all.text")));
	//   group.add(new ApplyNonConflictsAction(ThreeSide.RIGHT, DiffBundle.message("action.merge.apply.non.conflicts.right.text")));
	//   group.add(new MagicResolvedConflictsAction());
	//
	//   group.add(Separator.getInstance());
	//   group.addAll(myTextDiffProvider.getToolbarActions());
	//   group.add(new MyToggleExpandByDefaultAction());
	//   group.add(new MyToggleAutoScrollAction());
	//   group.add(myEditorSettingsAction);
	//
	//   AnAction additionalActions = ActionManager.getInstance().getAction("Diff.Conflicts.Additional.Actions");
	//   if (additionalActions instanceof ActionGroup) {
	//     group.add(additionalActions);
	//   }
	//
	//   return group;
	// }
	//
	// @NotNull
	// @Override
	// private function List<AnAction> createEditorPopupActions() {
	//   List<AnAction> group = new ArrayList<>();
	//
	//   group.add(new ApplySelectedChangesAction(Side.LEFT));
	//   group.add(new ApplySelectedChangesAction(Side.RIGHT));
	//   group.add(new ResolveSelectedChangesAction(Side.LEFT));
	//   group.add(new ResolveSelectedChangesAction(Side.RIGHT));
	//   group.add(new IgnoreSelectedChangesSideAction(Side.LEFT));
	//   group.add(new IgnoreSelectedChangesSideAction(Side.RIGHT));
	//   group.add(new ResolveSelectedConflictsAction());
	//   group.add(new IgnoreSelectedChangesAction());
	//   group.add(new ResetResolvedChangeAction());
	//
	//   group.add(Separator.getInstance());
	//   group.add(ActionManager.getInstance().getAction("Diff.Conflicts.Additional.Actions"));
	//   group.add(Separator.getInstance());
	//   group.addAll(TextDiffViewerUtil.createEditorPopupActions());
	//
	//   return group;
	// }
	//
	// @Nullable
	// @Override
	// private function List<AnAction> createPopupActions() {
	//   List<AnAction> group = new ArrayList<>(myTextDiffProvider.getPopupActions());
	//   group.add(Separator.getInstance());
	//   group.add(new MyToggleAutoScrollAction());
	//
	//   return group;
	// }
	// public function getResolveAction(result:MergeResult):Action {
	// 	var caption:String = MergeUtil.getResolveActionTitle(result, myMergeRequest, myMergeContext);
	// 	var a = new AbstractAction(caption);
	// 	a.actionPerformed = function(e:ActionEvent) {
	// 		if ((result == MergeResult.LEFT || result == MergeResult.RIGHT)
	// 			&& !MergeUtil.showConfirmDiscardChangesDialog(myPanel.getRootPane(),
	// 				result == MergeResult.LEFT ? DiffBundle.message("button.merge.resolve.accept.left") : DiffBundle.message("button.merge.resolve.accept.right"),
	// 				myContentModified)) {
	// 			return;
	// 		}
	// 		if (result == MergeResult.RESOLVED
	// 			&& (getChangesCount() > 0 || getConflictsCount() > 0)
	// 			&& !MessageDialogBuilder.yesNo(DiffBundle.message("apply.partially.resolved.merge.dialog.title"),
	// 				DiffBundle.message("merge.dialog.apply.partially.resolved.changes.confirmation.message", getChangesCount(), getConflictsCount()))
	// 				.yesText(DiffBundle.message("apply.changes.and.mark.resolved"))
	// 				.noText(DiffBundle.message("continue.merge"))
	// 				.ask(myPanel.getRootPane())) {
	// 			return;
	// 		}
	// 		if (result == MergeResult.CANCEL
	// 			&& !MergeUtil.showExitWithoutApplyingChangesDialog(myTextMergeViewer, myMergeRequest, myMergeContext, myContentModified)) {
	// 			return;
	// 		}
	// 		doFinishMerge(result, MergeResultSource.DIALOG_BUTTON);
	// 	}
	//
	// 	return a;
	// }

	private function doFinishMerge(result:MergeResult /*, source:MergeResultSource*/):Void {
		// logMergeResult(result, source);
		destroyChangedBlocks();
		// myMergeContext.finishMerge(result);
	}

	//
	// Diff
	//
	// private function restartMergeResolveIfNeeded():Void {
	// 	if (isDisposed())
	// 		return;
	// 	if (myTextDiffProvider.getIgnorePolicy().equals(myCurrentIgnorePolicy)
	// 		&& getTextSettings().isAutoResolveImportConflicts() == myResolveImportConflicts) {
	// 		return;
	// 	}
	//
	// 	if (!myInitialRediffFinished) {
	// 		ApplicationManager.getApplication().invokeLater(() -> restartMergeResolveIfNeeded());
	// 		return;
	// 	}
	//
	// 	if (myContentModified) {
	// 		if (Messages.showYesNoDialog(myProject, DiffBundle.message("changing.highlighting.requires.the.file.merge.restart"),
	// 			DiffBundle.message("update.highlighting.settings"), DiffBundle.message("discard.changes.and.restart.merge"),
	// 			DiffBundle.message("continue.merge"), Messages.getQuestionIcon()) != Messages.YES) {
	// 			getTextSettings().setIgnorePolicy(myCurrentIgnorePolicy);
	// 			getTextSettings().setAutoResolveImportConflicts(myResolveImportConflicts);
	// 			return;
	// 		}
	// 	}
	//
	// 	myInitialRediffFinished = false;
	// 	doRediff();
	// }
	// private function setInitialOutputContent(CharSequence baseContent): Bool {
	//   final outputDocument: Document  = myMergeRequest.getOutputContent().getDocument();
	//
	//   return DiffUtil.executeWriteCommand(outputDocument, getProject(), DiffBundle.message("message.init.merge.content.command"), function() {
	//     outputDocument.setText(baseContent);
	//
	//     DiffUtil.putNonundoableOperation(getProject(), outputDocument);
	//
	//     if (getTextSettings().isEnableLstGutterMarkersInMerge()) {
	//       myLineStatusTracker.setBaseRevision(baseContent);
	//       getEditor().getGutterComponentEx().setRightFreePaintersAreaState(EditorGutterFreePainterAreaState.SHOW);
	//     }
	//   });
	// }
	//
	// @Override
	// @RequiresEdt
	public function rediff(trySync:Bool):Void {
		// if (myInitialRediffStarted) return;
		// myInitialRediffStarted = true;
		// assert myAllMergeChanges.isEmpty();
		doRediff();
	}

	//
	// @NotNull
	// @Override
	// private function Runnable performRediff(ProgressIndicator indicator) {
	//   throw new UnsupportedOperationException();
	// }
	//
	// @RequiresEdt
	private function doRediff():Void {
		// myStatusPanel.setBusy(true);
		// myInnerDiffWorker.disable();

		// This is made to reduce unwanted modifications before rediff is finished.
		// It could happen between this init() EDT chunk and invokeLater().
		// getEditor().setViewer(true);
		// myLoadingPanel.startLoading();
		// myAcceptResolveAction.setEnabled(false);

		// BackgroundTaskUtil.executeAndTryWait(indicator -> BackgroundTaskUtil.runUnderDisposeAwareIndicator(this, () -> {
		// try {
		return doPerformRediff(/*indicator*/)();
		// }
		// catch (ProcessCanceledException e) {
		// return () -> myMergeContext.finishMerge(MergeResult.CANCEL);
		// }
		// catch (Throwable e) {
		// LOG.error(e);
		// return () -> myMergeContext.finishMerge(MergeResult.CANCEL);
		// }
		// }), null, ProgressIndicatorWithDelayedPresentation.DEFAULT_PROGRESS_DIALOG_POSTPONE_TIME_MILLIS,
		// ApplicationManager.getApplication().isUnitTestMode());
	}

	//
	// @NotNull
	private function doPerformRediff(/*indicator: ProgressIndicator */):Runnable {
		try {
			var sequences:Array<String> = [];

			// indicator.checkCanceled();
			var ignorePolicy:IgnorePolicy = myTextDiffProvider.getIgnorePolicy();

			var contents:Array<String> = myMergeRequest;

			for (seq in contents) {
				sequences.push(seq);
			}
			// var importRange: MergeRange  = ReadAction.compute(() -> {
			// sequences.addAll(ContainerUtil.map(contents, content -> content.getDocument().getImmutableCharSequence()));
			// if (getTextSettings().isAutoResolveImportConflicts()) {
			//   initPsiFiles();
			//   return MergeImportUtil.getImportMergeRange(myProject, myPsiFiles);
			// }
			//   return null;
			// });
			// var importRange = new MergeRange(0,0,0,0,0, 0);
			var lineFragments:MergeLineFragmentsWithImportMetadata = getLineFragments(/*indicator, */ sequences, /*importRange,*/ ignorePolicy);

			var lineOffsets:Array<LineOffsets> = sequences.map(function(seq) {
				return LineOffsetsUtil.createB(seq);
			});
			var conflictTypes:Array<MergeConflictType> = lineFragments.map(function(fragment) {
				// var conflictTypes: List<MergeConflictType>  = fragments.getFragments().map(function(fragment) {
				return MergeRangeUtil.getLineMergeType(fragment, sequences, lineOffsets, IgnorePolicy.getComparisonPolicyB(IgnorePolicyEnum.DEFAULT));
			});

			// FoldingModelSupport.Data foldingState =
			//   myFoldingModel.createState(lineFragments.getFragments(), lineOffsets, getFoldingModelSettings());

			return () -> apply(ThreeSide.fromEnum(ThreeSideEnum.BASE).selectC(sequences), lineFragments, conflictTypes /*, foldingState*/, ignorePolicy);
		} catch (e:DiffTooBigException) {
			return () -> trace("Diff too big");
			// return applyNotification(DiffNotifications.createDiffTooBig());
		} catch (e:ProcessCanceledException) {
			throw e;
		} catch (e:Dynamic) {
			trace(e);
			throw e;
			// LOG.error(e);
			return () -> {
				// clearDiffPresentation();
				// myPanel.setErrorContent();
			};
		}
	}

	//
	// @NotNull
	// @ApiStatus.Internal
	// public TextMergeRequest getMergeRequest() {
	//   return myMergeRequest;
	// }
	//
	private static function getLineFragments(/*indicator:ProgressIndicator, */ sequences:Array<String> /*, importRange:Null<MergeRange>*/,
			ignorePolicy:IgnorePolicy):MergeLineFragmentsWithImportMetadata {
		// if (importRange != null) {
		// 	return MergeImportUtil.getDividedFromImportsFragments(sequences, ignorePolicy.getComparisonPolicy(), importRange, indicator);
		// }
		var manager:ComparisonManager = ComparisonManager.getInstance();

		var fragments:Array<MergeLineFragment> = manager.mergeLines(sequences[0], sequences[1], sequences[2], ignorePolicy.getComparisonPolicyA() /*,
			indicator */);
		return new MergeLineFragmentsWithImportMetadata(fragments);
	}

	// private Void initPsiFiles() {
	//   if (myProject == null) return;
	//   ArrayList<PsiFile> files = new ArrayList<>();
	//   for (value in ThreeSide.values()) {
	//     files.add(getPsiFile(value, myProject, myMergeRequest));
	//   }
	//   myPsiFiles = files;
	// }
	//
	private function apply(baseContent:String, fragmentsWithMetadata:MergeLineFragmentsWithImportMetadata, conflictTypes:Array<MergeConflictType> /*,
		foldingState:Null<FoldingModelSupport.Data> */, ignorePolicy:IgnorePolicy):Void {
		// if (isDisposed())
		// 	return;
		// myFoldingModel.updateContext(myRequest, getFoldingModelSettings());
		// clearDiffPresentation();
		resetChangeCounters();

		// var success:Bool = setInitialOutputContent(baseContent);
		var fragments:Array<MergeLineFragment> = fragmentsWithMetadata.getFragments();

		// if (!success) {
		// 	fragments = [];
		// 	conflictTypes = [];
		// 	// myPanel.addNotification(DiffNotifications.createNotification(DiffBundle.message("error.cant.resolve.conflicts.in.a.read.only.file")));
		// }

		myModel.setChanges(fragments.map(function(f) {
			return new LineRange(f.getStartLine(ThreeSide.fromEnum(ThreeSideEnum.BASE)), f.getEndLine(ThreeSide.fromEnum(ThreeSideEnum.BASE)));
		}));

		for (index in 0...fragments.length) {
			var fragment:MergeLineFragment = fragments[index];
			var conflictType:MergeConflictType = conflictTypes[index];

			var isInImportRange:Bool = fragmentsWithMetadata.isIndexInImportRange(index);
			var change:TextMergeChange = new TextMergeChange(index, isInImportRange, fragment, conflictType /*, myTextMergeViewer*/, myModel);

			myAllMergeChanges.push(change);
			onChangeAdded(change);
		}

		// myFoldingModel.install(foldingState, myRequest, getFoldingModelSettings());
		//
		// myInitialScrollHelper.onRediff();
		//
		// myContentPanel.repaintDividers();
		// myStatusPanel.update();

		// getEditor().setViewer(false);
		// myLoadingPanel.stopLoading();
		// myAcceptResolveAction.setEnabled(true);
		//
		// myInnerDiffWorker.onEverythingChanged();
		// myInitialRediffFinished = true;
		// myContentModified = false;
		myCurrentIgnorePolicy = ignorePolicy;
		// myResolveImportConflicts = getTextSettings().isAutoResolveImportConflicts();

		// build initial statistics
		var autoResolvableChanges:Int = getAllChanges().filter(function(c) {
			return canResolveChangeAutomaticallyB(c, ThreeSide.fromEnum(ThreeSideEnum.BASE));
		}).length;

		// myAggregator = new MergeStatisticsAggregator(getAllChanges().size(), autoResolvableChanges, getConflictsCount());

		// if (myResolveImportConflicts) {
		// 	var importChanges:List<TextMergeChange> = ContainerUtil.filter(getChanges(), change -> change.isImportChange());
		// 	if (importChanges.size() != fragmentsWithMetadata.getFragments().size()) {
		// 		for (importChange in importChanges) {
		// 			markChangeResolved(importChange);
		// 		}
		// 	}
		// }
		if (true /*getTextSettings().isAutoApplyNonConflictedChanges()*/) {
			if (hasNonConflictedChanges(ThreeSide.fromEnum(ThreeSideEnum.BASE))) {
				applyNonConflictedChanges(ThreeSide.fromEnum(ThreeSideEnum.BASE));
			}
		}
	}

	// private function destroyChangedBlocks(): Void {
	//   super.destroyChangedBlocks();
	//   myInnerDiffWorker.stop();
	//
	//   for (change in myAllMergeChanges) {
	//     change.destroy();
	//   }
	//   myAllMergeChanges.clear();
	//
	//   myModel.setChanges(Collections.emptyList());
	// }
	// public function getLoadedResolveAction(result:MergeResult):Action {
	// 	return switch (result) {
	// 		case CANCEL: myCancelResolveAction;
	// 		case LEFT: myLeftResolveAction;
	// 		case RIGHT: myRightResolveAction;
	// 		case RESOLVED: myAcceptResolveAction;
	// 	};
	// }
	// public Bool isContentModified() {
	//   return myContentModified;
	// }
	//
	// By-word diff
	//
	//
	// Impl
	//
	// private function onBeforeDocumentChange(e:DocumentEvent):Void {
	// 	super.onBeforeDocumentChange(e);
	// 	if (myInitialRediffFinished)
	// 		myContentModified = true;
	// }
	// public Void repaintDividers() {
	//   myContentPanel.repaintDividers();
	// }

	private function onChangeResolved(change:TextMergeChange):Void {
		if (change.isResolvedA()) {
			onChangeRemoved(change);
		} else {
			onChangeAdded(change);
		}
		if (getChangesCount() == 0 && getConflictsCount() == 0) {
			// LOG.assertTrue(ContainerUtil.and(getAllChanges(), TextMergeChange::isResolved));
			// ApplicationManager.getApplication().invokeLater(function() {
			// 	if (isDisposed())
			// 		return;
			//
			// 	var component:JComponent = getEditor().getComponent();
			// 	var point:RelativePoint = new RelativePoint(component, new Point(component.getWidth() / 2, JBUIScale.scale(5)));
			//
			// 	var title:String = DiffBundle.message("merge.all.changes.processed.title.text");
			// 	var message:String = XmlStringUtil.wrapInHtmlTag(DiffBundle.message("merge.all.changes.processed.message.text"), "a");
			// 	DiffBalloons.showSuccessPopup(title, message, point, this, function() {
			// 		if (isDisposed() || myLoadingPanel.isLoading())
			// 			return;
			doFinishMerge(MergeResult.RESOLVED /*, MergeResultSource.NOTIFICATION*/);
			// 	});
			// });
		}
	}

	//
	// Getters
	//
	// @NotNull
	// public MergeModelBase getModel() {
	//   return myModel;
	// }
	//
	// @NotNull
	// @Override
	// public List<TextMergeChange> getAllChanges() {
	//   return myAllMergeChanges;
	// }

	public function getChanges():Array<TextMergeChange> {
		return myAllMergeChanges.filter(function(mergeChange) {
			return !mergeChange.isResolvedA();
		});
	}

	// private function DiffDividerDrawUtil.DividerPaintable getDividerPaintable(Side side) {
	//   return new MyDividerPaintable(side);
	// }
	// @NotNull
	// public KeyboardModifierListener getModifierProvider() {
	//   return myModifierProvider;
	// }
	// @NotNull
	// public EditorEx getEditor() {
	//   return getEditor(ThreeSide.BASE);
	// }
	//
	// Modification operations
	//

	/*
	 * affected changes should be sorted
	 */
	public function executeMergeCommandA(commandName:String, underBulkUpdate:Bool, affected:Null<Array<TextMergeChange>>, task:Runnable):Bool {
		// myContentModified = true;

		var affectedIndexes:Array<Int> = null;
		if (affected != null) {
			affectedIndexes = [];
			for (change in affected) {
				affectedIndexes.push(change.getIndex());
			}
		}

		return myModel.executeMergeCommand(commandName, null, /*UndoConfirmationPolicy.DEFAULT,*/ underBulkUpdate, affectedIndexes, task);
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
		// myModel.invalidateHighlighters(change.getIndex());
	}

	public function markChangeResolvedB(change:TextMergeChange, side:Side):Void {
		if (change.isResolvedB(side))
			return;
		change.setResolved(side, true);

		if (change.isResolvedA())
			onChangeResolved(change);
		// myModel.invalidateHighlighters(change.getIndex());
	}

	// @ApiStatus.Internal
	// @RequiresEdt
	// public Void markChangeResolvedWithAI(TextMergeChange change) {
	//   myAggregator.wasResolvedByAi(change.getIndex());
	//   change.markChangeResolvedWithAI();
	//   markChangeResolved(change);
	// }

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
		// if (change.isResolvedWithAI()) {
		// 	myAggregator.wasRolledBackAfterAI(change.getIndex());
		// }
		onChangeResolved(change);
		// myModel.invalidateHighlighters(change.getIndex());
	}

	// private function transferReferences(side: ThreeSide ,
	//                                     changes: List<TextMergeChange> ,
	//                                     newRanges: List<RangeMarker> ): Void {
	//   try {
	//     var files: List<PsiFile>  = myPsiFiles;
	//     if (myProject == null ||
	//         !getTextSettings().isAutoResolveImportConflicts() ||
	//         files.size() != 3 ||
	//         ContainerUtil.exists(files, file -> !file.isValid())) {
	//       return;
	//     }
	//     for (i in 0...changes.size()) {
	//       var change: TextMergeChange  = changes.get(i);
	//       var sourceSide: Side  = side.select(Side.LEFT, change.isChange(Side.LEFT) ? Side.LEFT : Side.RIGHT, Side.RIGHT);
	//       var sourceThreeSide: ThreeSide  = sourceSide.select(ThreeSide.LEFT, ThreeSide.RIGHT);
	//       var sourceDocument: Document  = getContent(sourceThreeSide).getDocument();
	//       var psiFile: PsiFile  = sourceSide.select(files.get(0), files.get(2));
	//       var startOffset: Int  = sourceDocument.getLineStartOffset(change.getStartLine(sourceThreeSide));
	//       var endOffset: Int  = sourceDocument.getLineEndOffset(change.getEndLine(sourceThreeSide) - 1);
	//       var data: List<ProcessorData<?>>  = createReferenceData(sourceThreeSide, psiFile, startOffset, endOffset);
	//       var marker: RangeMarker  = newRanges.get(i);
	//       data.forEach(processorData -> processorData.process(myProject, getEditor(ThreeSide.BASE), marker, 0, new Ref<>(false)));
	//     }
	//   }
	//   catch (ProcessCanceledException e) {
	//     throw e;
	//   }
	//   catch (Exception e) {
	//     LOG.error(e);
	//   }
	// }
	// private function  createReferenceData(
	//     side: ThreeSide , psiFile: PsiFile , startOffset: Int , endOffset: Int ): List<ProcessorData<Any>> {
	//   return ContainerUtil.mapNotNull(
	//     CopyPastePostProcessor.EP_NAME.getExtensionList(),
	//     function(processor) { Std.isOfType(processor, ReferenceCopyPasteProcessor)
	//                  ? createProcessorData(processor, side, psiFile, startOffset, endOffset)
	//                  : null;});
	// }
	// private <T extends TextBlockTransferableData> ProcessorData<T> createProcessorData(CopyPastePostProcessor<T> processor,
	//                                                                                             ThreeSide sourceSide,
	//                                                                                             PsiFile psiFile,
	//                                                                                             Int startOffset,
	//                                                                                             Int endOffset) {
	//   List<T> processorData = processor.collectTransferableData(psiFile, getEditor(sourceSide), new Int[]{startOffset}, new Int[]{endOffset});
	//   return new ProcessorData<>(processor, processorData);
	// }
	//
	// Actions
	//

	private function hasNonConflictedChanges(side:ThreeSide):Bool {
		return getAllChanges().filter(function(change) {
			return !change.isConflict() && canResolveChangeAutomaticallyB(change, side);
		}).length != 0;
	}

	private function applyNonConflictedChanges(side:ThreeSide):Void {
		executeMergeCommandA(/*DiffBundle.message(*/ "merge.dialog.apply.non.conflicted.changes.command" /*)*/, true, null, function() {
			resolveChangesAutomatically(getAllChanges().filter(function(change) {
				return !change.isConflict();
			}), side);
		});

		var firstUnresolved:TextMergeChange;
		for (change in getAllChanges()) {
			if (!change.isResolvedA()) {
				firstUnresolved = change;
				break;
			}
		}

		// if (firstUnresolved != null)
		// 	doScrollToChange(firstUnresolved, true);
	}

	private function hasResolvableConflictedChanges():Bool {
		for (change in getAllChanges()) {
			if (canResolveChangeAutomaticallyB(change, ThreeSide.fromEnum(ThreeSideEnum.BASE))) {
				return true;
			}
		}

		return false;
	}

	public function applyResolvableConflictedChanges():Void {
		var changes:Array<TextMergeChange> = getAllChanges();
		executeMergeCommandA(/*DiffBundle.message(*/ "message.resolve.simple.conflicts.command" /*)*/, true, null, function() {
			resolveChangesAutomatically(changes, ThreeSide.fromEnum(ThreeSideEnum.BASE));
		});

		var firstUnresolved:TextMergeChange;
		for (change in getAllChanges()) {
			if (!change.isResolvedA()) {
				firstUnresolved = change;
				break;
			}
		}

		// if (firstUnresolved != null)
		// 	doScrollToChange(firstUnresolved, true);
	}

	public static function canResolveChangeAutomaticallyA(change:TextMergeChange, side:ThreeSide, myMergeRequest:Array<String>, myResultDocument:String):Bool {
		if (change.isConflict()) {
			return ThreeSide.fromIndex(side.getIndex()) == ThreeSideEnum.BASE
				&& change.getConflictType().canBeResolved()
				&& !change.isResolvedB(Side.fromEnum(SideEnum.LEFT))
				&& !change.isResolvedB(Side.fromEnum(SideEnum.RIGHT))
				&& !isChangeRangeModifiedA(change, myMergeRequest, myResultDocument);
		} else {
			return !change.isResolvedA()
				&& change.isChangeB(ThreeSide.fromIndex(side.getIndex()))
				&& !isChangeRangeModifiedA(change, myMergeRequest, myResultDocument);
		}
	}

	public function canResolveChangeAutomaticallyB(change:TextMergeChange, side:ThreeSide):Bool {
		return canResolveChangeAutomaticallyA(change, side, myMergeRequest, myResultDocument);
	}

	public static function isChangeRangeModifiedA(change:TextMergeChange, myMergeRequest:Array<String>, myResultDocument:String):Bool {
		var changeFragment:MergeLineFragment = change.getFragment();
		var baseStartLine:Int = changeFragment.getStartLine(ThreeSide.fromEnum(ThreeSideEnum.BASE));
		var baseEndLine:Int = changeFragment.getEndLine(ThreeSide.fromEnum(ThreeSideEnum.BASE));
		var baseDiffContent:String = ThreeSide.fromEnum(ThreeSideEnum.BASE).selectC(myMergeRequest);
		// var baseDocument:Document = baseDiffContent.getDocument();

		var resultStartLine:Int = change.getStartLineA();
		var resultEndLine:Int = change.getEndLineA();
		// var resultDocument:String = getEditor().getDocument();

		var baseContent:String = DiffUtil.getLinesContentA(/*baseDocument*/ baseDiffContent, baseStartLine, baseEndLine);
		var resultContent:String = DiffUtil.getLinesContentA(myResultDocument, resultStartLine, resultEndLine);
		return baseContent != resultContent;
	}

	public function isChangeRangeModifiedB(change:TextMergeChange):Bool {
		return isChangeRangeModifiedA(change, myMergeRequest, myResultDocument);
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
		// transferReferenceData(filteredChanges, side, newRanges);
	}

	// private function transferReferenceData(changes:List<TextMergeChange>, side:ThreeSide, newRanges:List<LineRange>):Void {
	// 	if (myResolveImportConflicts) {
	// 		var document:Document = getContent(ThreeSide.BASE).getDocument();
	// 		var markers:List<RangeMarker> = ContainerUtil.map(newRanges,
	// 			range -> document.createRangeMarker(document.getLineStartOffset(range.start), document.getLineEndOffset(range.end)));
	// 		transferReferences(side, changes, markers);
	// 	}
	// }

	public function resolveChangeAutomatically(change:TextMergeChange, side:ThreeSide):LineRange {
		if (!canResolveChangeAutomaticallyB(change, side))
			return null;

		if (change.isConflict()) {
			// var texts:Array<String> = ThreeSide.map(function(it) {
			// 	return DiffUtil.getLinesContentA(getEditor(it).getDocument(), change.getStartLineB(ThreeSide.fromIndex(it.getIndex())), change.getEndLineB(it));
			// });
			var texts = myRequest;

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

// private static final Key<Bool> EXTERNAL_OPERATION_IN_PROGRESS = Key.create("external.resolve.operation");

/**
 * Allows running external heavy operations and blocks the UI during execution.
 */
// public <T> Void runExternalResolver(CompletableFuture<T> operation,
//                                     Consumer<T> resultHandler,
//                                     Consumer<? super Throwable> errorHandler) {
//   runBeforeExternalOperation();
//
//   operation.whenComplete((result, throwable) -> {
//
//     Runnable runnable = () -> {
//       if (isDisposed()) return;
//       runAfterExternalOperation();
//
//       if (throwable != null) {
//         errorHandler.accept(throwable);
//         return;
//       }
//
//       if (result != null) {
//         resultHandler.accept(result);
//       }
//     };
//
//     ApplicationManager.getApplication().invokeLater(runnable, ModalityState.stateForComponent(getComponent()));
//   });
// }
//
// private function Bool isExternalOperationInProgress() {
//   return Bool.TRUE.equals(myMergeContext.getUserData(EXTERNAL_OPERATION_IN_PROGRESS));
// }
//
// @RequiresEdt
// private Void runBeforeExternalOperation() {
//   myMergeContext.putUserData(EXTERNAL_OPERATION_IN_PROGRESS, true);
//   enableResolveActions(false);
//   getEditor().setViewer(true);
//
//   for (change in getAllChanges()) {
//     change.reinstallHighlighters();
//   }
// }
//
// @RequiresEdt
// private Void runAfterExternalOperation() {
//   myMergeContext.putUserData(EXTERNAL_OPERATION_IN_PROGRESS, null);
//   enableResolveActions(true);
//   getEditor().setViewer(false);
//
//   for (change in getAllChanges()) {
//     change.reinstallHighlighters();
//   }
// }
//
// private Void enableResolveActions(Bool enable) {
//   myLeftResolveAction.setEnabled(enable);
//   myRightResolveAction.setEnabled(enable);
//   myAcceptResolveAction.setEnabled(enable);
// }
// @ApiStatus.Internal
// Void logMergeCancelled() {
//   logMergeResult(MergeResult.CANCEL, MergeResultSource.DIALOG_CLOSING);
// }
//
// private Void logMergeResult(MergeResult mergeResult, MergeResultSource source) {
//   MergeStatisticsCollector.MergeResult statsResult = switch (mergeResult) {
//     case CANCEL -> MergeStatisticsCollector.MergeResult.CANCELED;
//     case RESOLVED -> MergeStatisticsCollector.MergeResult.SUCCESS;
//     case LEFT, RIGHT -> null;
//   };
//   if (statsResult == null) return;
//   myAggregator.setUnresolved(getChanges().size());
//   MergeStatisticsCollector.INSTANCE.logMergeFinished(myProject, statsResult, source, myAggregator);
// }
// }
// class MyInnerDiffWorker {
//   private final Set<TextMergeChange> myScheduled = new HashSet<>();
//
//   private final Alarm myAlarm = new Alarm(MergeThreesideViewer.this);
//   Null<private> ProgressIndicator myProgress;
//
//   private Bool myEnabled = false;
//
//   @RequiresEdt
//   public Void scheduleRediff(TextMergeChange change) {
//     scheduleRediff(Collections.singletonList(change));
//   }
//
//   @RequiresEdt
//   public Void scheduleRediff(Collection<TextMergeChange> changes) {
//     if (!myEnabled) return;
//
//     putChanges(changes);
//     schedule();
//   }
//
//   @RequiresEdt
//   public Void onSettingsChanged() {
//     Bool enabled = myTextDiffProvider.getHighlightPolicy() == HighlightPolicy.BY_WORD;
//     if (myEnabled == enabled) return;
//     myEnabled = enabled;
//
//     rebuildEverything();
//   }
//
//   @RequiresEdt
//   public Void onEverythingChanged() {
//     myEnabled = myTextDiffProvider.getHighlightPolicy() == HighlightPolicy.BY_WORD;
//
//     rebuildEverything();
//   }
//
//   @RequiresEdt
//   public Void disable() {
//     myEnabled = false;
//     stop();
//   }
//
//   private Void rebuildEverything() {
//     if (myProgress != null) myProgress.cancel();
//     myProgress = null;
//
//     if (myEnabled) {
//       putChanges(myAllMergeChanges);
//       launchRediff(true);
//     }
//     else {
//       myStatusPanel.setBusy(false);
//       myScheduled.clear();
//       for (change in myAllMergeChanges) {
//         change.setInnerFragments(null);
//       }
//     }
//   }
//
//   @RequiresEdt
//   public Void stop() {
//     if (myProgress != null) myProgress.cancel();
//     myProgress = null;
//     myScheduled.clear();
//     myAlarm.cancelAllRequests();
//   }
//
//   @RequiresEdt
//   private Void putChanges(Collection<TextMergeChange> changes) {
//     for (change in changes) {
//       if (change.isResolved()) continue;
//       myScheduled.add(change);
//     }
//   }
//
//   @RequiresEdt
//   private Void schedule() {
//     if (myProgress != null) return;
//     if (myScheduled.isEmpty()) return;
//
//     myAlarm.cancelAllRequests();
//     myAlarm.addRequest(() -> launchRediff(false), ProgressIndicatorWithDelayedPresentation.DEFAULT_PROGRESS_DIALOG_POSTPONE_TIME_MILLIS);
//   }
//
//   @RequiresEdt
//   private Void launchRediff(Bool trySync) {
//     myStatusPanel.setBusy(true);
//
//     final List<TextMergeChange> scheduled = new ArrayList<>(myScheduled);
//     myScheduled.clear();
//
//     List<Document> documents = ThreeSide.map((side) -> getEditor(side).getDocument());
//     final List<InnerChunkData> data = ContainerUtil.map(scheduled, change -> new InnerChunkData(change, documents));
//
//     Int waitMillis = trySync ? ProgressIndicatorWithDelayedPresentation.DEFAULT_PROGRESS_DIALOG_POSTPONE_TIME_MILLIS : 0;
//     ProgressIndicator progress =
//       BackgroundTaskUtil.executeAndTryWait(indicator -> performRediff(scheduled, data, indicator), null, waitMillis, false);
//
//     if (progress.isRunning()) {
//       myProgress = progress;
//     }
//   }
//
//   @NotNull
//   @RequiresBackgroundThread
//   private Runnable performRediff(final List<TextMergeChange> scheduled,
//                                  final List<InnerChunkData> data,
//                                  final ProgressIndicator indicator) {
//     ComparisonPolicy comparisonPolicy = myTextDiffProvider.getIgnorePolicy().getComparisonPolicy();
//     final List<MergeInnerDifferences> result = new ArrayList<>(data.size());
//     for (chunkData in data) {
//       result.add(DiffUtil.compareThreesideInner(chunkData.text, comparisonPolicy, indicator));
//     }
//
//     return () -> {
//       if (!myEnabled || indicator.isCanceled()) return;
//       myProgress = null;
//
//       for (Int i = 0; i < scheduled.size(); i++) {
//         TextMergeChange change = scheduled.get(i);
//         if (myScheduled.contains(change)) continue;
//         change.setInnerFragments(result.get(i));
//       }
//
//       myStatusPanel.setBusy(false);
//       if (!myScheduled.isEmpty()) {
//         launchRediff(false);
//       }
//     };
//   }
// }
//
//
class MyMergeModel extends MergeModelBase<TextMergeChangeState> {
	private final myAllMergeChanges:Array<TextMergeChange> = [];
	private final onChangeResolved:TextMergeChange->Void;
	private final markChangeResolvedA:TextMergeChange->Void;

	public function new(/*project: Null<Project>, */ document:String, myAllMergeChanges:Array<TextMergeChange>, onChangeResolved:TextMergeChange->Void,
			markChangeResolvedA:TextMergeChange->Void) {
		super(/*project, */ document);
		this.onChangeResolved = onChangeResolved;
		this.markChangeResolvedA = markChangeResolvedA;
	}

	// private function Void reinstallHighlighters(index: Int ) {
	//   TextMergeChange change = myAllMergeChanges.get(index);
	//   change.reinstallHighlighters();
	//   myInnerDiffWorker.scheduleRediff(change);
	// }

	private function storeChangeState(index:Int):TextMergeChangeState {
		var change:TextMergeChange = myAllMergeChanges[index];
		return change.storeState();
	}

	private override function restoreChangeState(state:TextMergeChangeState):Void {
		super.restoreChangeState(state);
		var change:TextMergeChange = myAllMergeChanges[state.myIndex];

		var wasResolved:Bool = change.isResolvedA();
		// if (change.isResolvedWithAI()) {
		//   myAggregator.wasUndoneAfterAI(change.getIndex());
		// }
		change.restoreState(state);
		if (wasResolved != change.isResolvedA())
			onChangeResolved(change);
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

	// @Override
	// private function onRangeManuallyEdit(index: Int ): Void {
	//   var change: TextMergeChange  = myAllMergeChanges.get(index);
	//   if (change.isResolvedWithAI()) {
	//     myAggregator.wasEditedAfterAi(index);
	//   }
	// }
}

//
// private abstract class ApplySelectedChangesActionBase extends AnAction implements DumbAware {
//   @Override
//   public ActionUpdateThread getActionUpdateThread() {
//     return ActionUpdateThread.EDT;
//   }
//
//   @Override
//   public Void update(AnActionEvent e) {
//     if (DiffUtil.isFromShortcut(e)) {
//       // consume shortcut even if there are nothing to do - aVoid calling some other action
//       e.getPresentation().setEnabledAndVisible(true);
//       return;
//     }
//
//     Presentation presentation = e.getPresentation();
//     Editor editor = e.getData(CommonDataKeys.EDITOR);
//
//     ThreeSide side = getEditorSide(editor);
//     if (side == null) {
//       presentation.setEnabledAndVisible(false);
//       return;
//     }
//
//     if (!isVisible(side)) {
//       presentation.setEnabledAndVisible(false);
//       return;
//     }
//
//     presentation.setText(getText(side));
//
//     presentation.setEnabledAndVisible(isSomeChangeSelected(side) && !isExternalOperationInProgress());
//   }
//
//   @Override
//   public Void actionPerformed(final AnActionEvent e) {
//     Editor editor = e.getData(CommonDataKeys.EDITOR);
//     final ThreeSide side = getEditorSide(editor);
//     if (editor == null || side == null) return;
//
//     final List<TextMergeChange> selectedChanges = getSelectedChanges(side);
//     if (selectedChanges.isEmpty()) return;
//
//     String title = DiffBundle.message("message.do.in.merge.command", e.getPresentation().getText());
//     executeMergeCommand(title, selectedChanges.size() > 1, selectedChanges, () -> apply(side, selectedChanges));
//   }
//
//   @RequiresWriteLock
//   private function abstract Void apply(ThreeSide side, List<TextMergeChange> changes);
//
//   private Bool isSomeChangeSelected(ThreeSide side) {
//     EditorEx editor = getEditor(side);
//     return DiffUtil.isSomeRangeSelected(editor,
//                                         lines -> ContainerUtil.exists(getAllChanges(), change -> isChangeSelected(change, lines, side)));
//   }
//
//   @NotNull
//   @RequiresEdt
//   private function List<TextMergeChange> getSelectedChanges(ThreeSide side) {
//     EditorEx editor = getEditor(side);
//     BitSet lines = DiffUtil.getSelectedLines(editor);
//     return ContainerUtil.filter(getChanges(), change -> isChangeSelected(change, lines, side));
//   }
//
//   private function Bool isChangeSelected(TextMergeChange change, BitSet lines, ThreeSide side) {
//     if (!isEnabled(change)) return false;
//     Int line1 = change.getStartLine(side);
//     Int line2 = change.getEndLine(side);
//     return DiffUtil.isSelectedByLine(lines, line1, line2);
//   }
//
//   @Nls
//   private function abstract String getText(ThreeSide side);
//
//   private function abstract Bool isVisible(ThreeSide side);
//
//   private function abstract Bool isEnabled(TextMergeChange change);
// }
//
// private class IgnoreSelectedChangesSideAction extends ApplySelectedChangesActionBase {
//   private final Side mySide;
//
//   IgnoreSelectedChangesSideAction(Side side) {
//     mySide = side;
//     ActionUtil.copyFrom(this, mySide.select("Diff.IgnoreLeftSide", "Diff.IgnoreRightSide"));
//   }
//
//   @Override
//   private function Void apply(ThreeSide side, List<TextMergeChange> changes) {
//     for (change in changes) {
//       ignoreChange(change, mySide, false);
//     }
//   }
//
//   @Override
//   private function String getText(ThreeSide side) {
//     return DiffBundle.message("action.presentation.merge.ignore.text");
//   }
//
//   @Override
//   private function Bool isVisible(ThreeSide side) {
//     return side == mySide.select(ThreeSide.LEFT, ThreeSide.RIGHT);
//   }
//
//   @Override
//   private function Bool isEnabled(TextMergeChange change) {
//     return !change.isResolved(mySide);
//   }
// }
//
// private class IgnoreSelectedChangesAction extends ApplySelectedChangesActionBase {
//   IgnoreSelectedChangesAction() {
//     getTemplatePresentation().setIcon(AllIcons.Diff.Remove);
//   }
//
//   @Override
//   private function String getText(ThreeSide side) {
//     return DiffBundle.message("action.presentation.merge.ignore.text");
//   }
//
//   @Override
//   private function Bool isVisible(ThreeSide side) {
//     return side == ThreeSide.BASE;
//   }
//
//   @Override
//   private function Bool isEnabled(TextMergeChange change) {
//     return !change.isResolved();
//   }
//
//   @Override
//   private function Void apply(ThreeSide side, List<TextMergeChange> changes) {
//     for (change in changes) {
//       markChangeResolved(change);
//     }
//   }
// }
//
// private class ResetResolvedChangeAction extends ApplySelectedChangesActionBase {
//   ResetResolvedChangeAction() {
//     getTemplatePresentation().setIcon(AllIcons.Diff.Revert);
//   }
//
//   @Override
//   private function Void apply(ThreeSide side, List<TextMergeChange> changes) {
//     for (change in changes) {
//       resetResolvedChange(change);
//     }
//   }
//
//   @Override
//   private function List<TextMergeChange> getSelectedChanges(ThreeSide side) {
//     EditorEx editor = getEditor(side);
//     BitSet lines = DiffUtil.getSelectedLines(editor);
//     return ContainerUtil.filter(getAllChanges(), change -> isChangeSelected(change, lines, side));
//   }
//
//   @Nls
//   @Override
//   private function String getText(ThreeSide side) {
//     return DiffBundle.message("action.presentation.diff.revert.text");
//   }
//
//   @Override
//   private function Bool isVisible(ThreeSide side) {
//     return true;
//   }
//
//   @Override
//   private function Bool isEnabled(TextMergeChange change) {
//     return change.isResolvedWithAI();
//   }
// }
//
// private class ApplySelectedChangesAction extends ApplySelectedChangesActionBase {
//   private final Side mySide;
//
//   ApplySelectedChangesAction(Side side) {
//     mySide = side;
//     ActionUtil.copyFrom(this, mySide.select("Diff.ApplyLeftSide", "Diff.ApplyRightSide"));
//   }
//
//   @Override
//   private function Void apply(ThreeSide side, List<TextMergeChange> changes) {
//     replaceChanges(changes, mySide, false);
//   }
//
//   @Override
//   private function String getText(ThreeSide side) {
//     return side != ThreeSide.BASE ? DiffBundle.message("action.presentation.diff.accept.text") : getTemplatePresentation().getText();
//   }
//
//   @Override
//   private function Bool isVisible(ThreeSide side) {
//     if (side == ThreeSide.BASE) return true;
//     return side == mySide.select(ThreeSide.LEFT, ThreeSide.RIGHT);
//   }
//
//   @Override
//   private function Bool isEnabled(TextMergeChange change) {
//     return !change.isResolved(mySide);
//   }
// }
//
// private class ResolveSelectedChangesAction extends ApplySelectedChangesActionBase {
//   private final Side mySide;
//
//   ResolveSelectedChangesAction(Side side) {
//     mySide = side;
//   }
//
//   @Override
//   private function Void apply(ThreeSide side, List<TextMergeChange> changes) {
//     replaceChanges(changes, mySide, true);
//   }
//
//   @Override
//   private function String getText(ThreeSide side) {
//     return DiffBundle.message("action.presentation.merge.resolve.using.side.text", mySide.getIndex());
//   }
//
//   @Override
//   private function Bool isVisible(ThreeSide side) {
//     if (side == ThreeSide.BASE) return true;
//     return side == mySide.select(ThreeSide.LEFT, ThreeSide.RIGHT);
//   }
//
//   @Override
//   private function Bool isEnabled(TextMergeChange change) {
//     return !change.isResolved(mySide);
//   }
// }
//
// private class ResolveSelectedConflictsAction extends ApplySelectedChangesActionBase {
//   ResolveSelectedConflictsAction() {
//     ActionUtil.copyFrom(this, "Diff.ResolveConflict");
//   }
//
//   @Override
//   private function Void apply(ThreeSide side, List<TextMergeChange> changes) {
//     resolveChangesAutomatically(changes, ThreeSide.BASE);
//   }
//
//   @Override
//   private function String getText(ThreeSide side) {
//     return DiffBundle.message("action.presentation.merge.resolve.automatically.text");
//   }
//
//   @Override
//   private function Bool isVisible(ThreeSide side) {
//     return side == ThreeSide.BASE;
//   }
//
//   @Override
//   private function Bool isEnabled(TextMergeChange change) {
//     return canResolveChangeAutomatically(change, ThreeSide.BASE);
//   }
// }
//
// public class ApplyNonConflictsAction extends DumbAwareAction {
//   private final ThreeSide mySide;
//
//   public ApplyNonConflictsAction(ThreeSide side, @Nls String text) {
//     String id = side.select("Diff.ApplyNonConflicts.Left", "Diff.ApplyNonConflicts", "Diff.ApplyNonConflicts.Right");
//     ActionUtil.copyFrom(this, id);
//     mySide = side;
//     getTemplatePresentation().setText(text);
//   }
//
//   @Override
//   public ActionUpdateThread getActionUpdateThread() {
//     return ActionUpdateThread.EDT;
//   }
//
//   @Override
//   public Void update(AnActionEvent e) {
//     e.getPresentation().setEnabled(hasNonConflictedChanges(mySide) && !isExternalOperationInProgress());
//   }
//
//   @Override
//   public Void actionPerformed(AnActionEvent e) {
//     applyNonConflictedChanges(mySide);
//   }
//
//   @Override
//   public Bool displayTextInToolbar() {
//     return true;
//   }
//
//   @Override
//   public Bool useSmallerFontForTextInToolbar() {
//     return true;
//   }
// }
//
// public class MagicResolvedConflictsAction extends DumbAwareAction {
//   public MagicResolvedConflictsAction() {
//     ActionUtil.copyFrom(this, "Diff.MagicResolveConflicts");
//   }
//
//   @Override
//   public ActionUpdateThread getActionUpdateThread() {
//     return ActionUpdateThread.EDT;
//   }
//
//   @Override
//   public Void update(AnActionEvent e) {
//     e.getPresentation().setEnabled(hasResolvableConflictedChanges() && !isExternalOperationInProgress());
//   }
//
//   @Override
//   public Void actionPerformed(AnActionEvent e) {
//     applyResolvableConflictedChanges();
//   }
// }
//
// private class ShowDiffWithBaseAction extends DumbAwareAction {
//   private final ThreeSide mySide;
//
//   ShowDiffWithBaseAction(ThreeSide side) {
//     mySide = side;
//     String actionId = mySide.select("Diff.CompareWithBase.Left", "Diff.CompareWithBase.Result", "Diff.CompareWithBase.Right");
//     ActionUtil.copyFrom(this, actionId);
//   }
//
//   @Override
//   public ActionUpdateThread getActionUpdateThread() {
//     return ActionUpdateThread.EDT;
//   }
//
//   @Override
//   public Void update(AnActionEvent e) {
//     e.getPresentation().setEnabled(!isExternalOperationInProgress());
//   }
//
//   @Override
//   public Void actionPerformed(AnActionEvent e) {
//     DiffContent baseContent = ThreeSide.BASE.select(myMergeRequest.getContents());
//     String baseTitle = ThreeSide.BASE.select(myMergeRequest.getContentTitles());
//
//     DiffContent otherContent = mySide.select(myRequest.getContents());
//     String otherTitle = mySide.select(myRequest.getContentTitles());
//
//     SimpleDiffRequest request = new SimpleDiffRequest(myRequest.getTitle(), baseContent, otherContent, baseTitle, otherTitle);
//
//     ThreeSide currentSide = getCurrentSide();
//     LogicalPosition currentPosition = DiffUtil.getCaretPosition(getCurrentEditor());
//
//     LogicalPosition resultPosition = transferPosition(currentSide, mySide, currentPosition);
//     request.putUserData(DiffUserDataKeys.SCROLL_TO_LINE, Pair.create(Side.RIGHT, resultPosition.line));
//
//     DiffManager.getInstance().showDiff(myProject, request, new DiffDialogHints(null, myPanel));
//   }
// }
//
// //
// // Helpers
// //
//
// private class MyDividerPaintable implements DiffDividerDrawUtil.DividerPaintable {
//   private final Side mySide;
//
//   MyDividerPaintable(Side side) {
//     mySide = side;
//   }
//
//   @Override
//   public Void process(Handler handler) {
//     ThreeSide left = mySide.select(ThreeSide.LEFT, ThreeSide.BASE);
//     ThreeSide right = mySide.select(ThreeSide.BASE, ThreeSide.RIGHT);
//     for (mergeChange in myAllMergeChanges) {
//       if (!mergeChange.isChange(mySide)) continue;
//       Bool isResolved = mergeChange.isResolved(mySide);
//       if (!handler.processResolvable(mergeChange.getStartLine(left), mergeChange.getEndLine(left),
//                                      mergeChange.getStartLine(right), mergeChange.getEndLine(right),
//                                      mergeChange.getDiffType(), isResolved)) {
//         return;
//       }
//     }
//   }
// }
//
// public class ModifierProvider extends KeyboardModifierListener {
//   public Void init() {
//     init(myPanel, myTextMergeViewer);
//   }
//
//   @Override
//   public Void onModifiersChanged() {
//     for (change in myAllMergeChanges) {
//       change.updateGutterActions(false);
//     }
//   }
// }
//
// private class MyLineStatusMarkerRenderer extends LineStatusTrackerMarkerRenderer {
//   private final LineStatusTrackerBase<?> myTracker;
//
//   MyLineStatusMarkerRenderer(LineStatusTrackerBase<?> tracker) {
//     super(tracker, editor -> editor == getEditor());
//     myTracker = tracker;
//   }
//
//   @Override
//   public Void scrollAndShow(Editor editor, com.intellij.openapi.vcs.ex.Range range) {
//     if (!myTracker.isValid()) return;
//     final Document document = myTracker.getDocument();
//     Int line = Math.min(!range.hasLines() ? range.getLine2() : range.getLine2() - 1, getLineCount(document) - 1);
//
//     Int[] startLines = new Int[]{
//       transferPosition(ThreeSide.BASE, ThreeSide.LEFT, new LogicalPosition(line, 0)).line,
//       line,
//       transferPosition(ThreeSide.BASE, ThreeSide.RIGHT, new LogicalPosition(line, 0)).line
//     };
//
//     for (side in ThreeSide.values()) {
//       DiffUtil.moveCaret(getEditor(side), side.select(startLines));
//     }
//
//     getEditor().getScrollingModel().scrollToCaret(ScrollType.CENTER);
//     showAfterScroll(editor, range);
//   }
//
//   @NotNull
//   @Override
//   private function List<AnAction> createToolbarActions(Editor editor,
//                                                 com.intellij.openapi.vcs.ex.Range range,
//                                                 Null<Point> mousePosition) {
//     List<AnAction> actions = new ArrayList<>();
//     actions.add(new LineStatusMarkerPopupActions.ShowPrevChangeMarkerAction(editor, myTracker, range, this));
//     actions.add(new LineStatusMarkerPopupActions.ShowNextChangeMarkerAction(editor, myTracker, range, this));
//     actions.add(new MyRollbackLineStatusRangeAction(editor, range));
//     actions.add(new LineStatusMarkerPopupActions.ShowLineStatusRangeDiffAction(editor, myTracker, range));
//     actions.add(new LineStatusMarkerPopupActions.CopyLineStatusRangeAction(editor, myTracker, range));
//     actions.add(new LineStatusMarkerPopupActions.ToggleByWordDiffAction(editor, myTracker, range, mousePosition, this));
//     return actions;
//   }
//
//   private final class MyRollbackLineStatusRangeAction extends LineStatusMarkerPopupActions.RangeMarkerAction {
//     private MyRollbackLineStatusRangeAction(Editor editor, com.intellij.openapi.vcs.ex.Range range) {
//       super(editor, myTracker, range, IdeActions.SELECTED_CHANGES_ROLLBACK);
//     }
//
//     @Override
//     private function Bool isEnabled(Editor editor, com.intellij.openapi.vcs.ex.Range range) {
//       return true;
//     }
//
//     @Override
//     private function Void actionPerformed(Editor editor, com.intellij.openapi.vcs.ex.Range range) {
//       DiffUtil.moveCaretToLineRangeIfNeeded(editor, range.getLine1(), range.getLine2());
//       myTracker.rollbackChanges(range);
//     }
//   }
//
//   @Override
//   private function Void paintGutterMarkers(Editor editor, List<Range> ranges, Graphics g) {
//     Int framingBorder = JBUIScale.scale(2);
//     LineStatusMarkerDrawUtil.paintDefault(editor, g, ranges, DefaultFlagsProvider.DEFAULT, framingBorder);
//   }
//
//   @Override
//   public String toString() {
//     return "MergeThreesideViewer.MyLineStatusMarkerRenderer{" +
//            "myTracker=" + myTracker +
//            '}';
//   }
// }
//
// private class NavigateToChangeMarkerAction extends DumbAwareAction {
//   private final Bool myGoToNext;
//
//   private function NavigateToChangeMarkerAction(Bool goToNext) {
//     myGoToNext = goToNext;
//     // TODO: reuse ShowChangeMarkerAction
//     ActionUtil.copyFrom(this, myGoToNext ? "VcsShowNextChangeMarker" : "VcsShowPrevChangeMarker");
//   }
//
//   @Override
//   public ActionUpdateThread getActionUpdateThread() {
//     return ActionUpdateThread.EDT;
//   }
//
//   @Override
//   public Void update(AnActionEvent e) {
//     e.getPresentation().setEnabled(getTextSettings().isEnableLstGutterMarkersInMerge());
//   }
//
//   @Override
//   public Void actionPerformed(AnActionEvent e) {
//     if (!myLineStatusTracker.isValid()) return;
//
//     Int line = getEditor().getCaretModel().getLogicalPosition().line;
//     Range targetRange = myGoToNext ? myLineStatusTracker.getNextRange(line) : myLineStatusTracker.getPrevRange(line);
//     if (targetRange != null) new MyLineStatusMarkerRenderer(myLineStatusTracker).scrollAndShow(getEditor(), targetRange);
//   }
// }
//
// private static class InnerChunkData {
//   public final List<CharSequence> text;
//
//   InnerChunkData(TextMergeChange change, List<Document> documents) {
//     text = getChunks(change, documents);
//   }
//
//   @NotNull
//   private static List<CharSequence> getChunks(TextMergeChange change,
//                                               List<Document> documents) {
//     return ThreeSide.map(side -> {
//       if (!change.isChange(side) || change.isResolved(side)) return null;
//
//       Int startLine = change.getStartLine(side);
//       Int endLine = change.getEndLine(side);
//       if (startLine == endLine) return null;
//
//       return DiffUtil.getLinesContent(side.select(documents), startLine, endLine);
//     });
//   }
// }
//
// private class MyMergeStatusPanel extends MyStatusPanel {
//   /**
//    * For classic UI.
//    *
//    * @see community/platform/icons/src/general/greenCheckmark.svg
//    */
//   private static final JBColor GREEN_CHECKMARK_DEFAULT_COLOR = new JBColor(0x368746, 0x50A661);
//   private static final JBColor NO_CONFLICTS_FOREGROUND =
//     JBColor.namedColor("VersionControl.Merge.Status.NoConflicts.foreground", GREEN_CHECKMARK_DEFAULT_COLOR);
//
//   @Override
//   private function Null<Icon> getStatusIcon() {
//     if (getChangesCount() == 0 && getConflictsCount() == 0) {
//       return AllIcons.General.GreenCheckmark;
//     }
//     return null;
//   }
//
//   @Override
//   private function Color getStatusForeground() {
//     if (getChangesCount() == 0 && getConflictsCount() == 0) {
//       return NO_CONFLICTS_FOREGROUND;
//     }
//     return UIUtil.getLabelForeground();
//   }
// }
// }
// }
