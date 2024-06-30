// Copyright 2000-2024 JetBrains s.r.o. and contributors. Use of this source code is governed by the Apache 2.0 license.
package diff.merge;

class MergeThreesideViewer extends ThreesideTextDiffViewerEx {
	private final myModel:MergeModelBase<TextMergeChange.State>;

	private final myModifierProvider:ModifierProvider;
	private final myInnerDiffWorker:MyInnerDiffWorker;

	// private final myLineStatusTracker: SimpleLineStatusTracker ;
	private final myTextDiffProvider:TextDiffProviderBase;

	// all changes - both applied and unapplied ones
	private final myAllMergeChanges:List<TextMergeChange> = new ArrayList<>();
	private var myCurrentIgnorePolicy:IgnorePolicy;

	private var myInitialRediffStarted:Bool;
	private var myInitialRediffFinished:Bool;
	private var myContentModified:Bool;
	private var myResolveImportConflicts:Bool;

	private var myPsiFiles:List<PsiFile> = new ArrayList<>();

	private final myCancelResolveAction:Action;
	private final myLeftResolveAction:Action;
	private final myRightResolveAction:Action;
	private final myAcceptResolveAction:Action;
	private var myAggregator:MergeStatisticsAggregator;

	private final myMergeContext:MergeContext;
	private final myMergeRequest:TextMergeRequest;
	private final myTextMergeViewer:TextMergeViewer;

	public function new(context:DiffContext, request:ContentDiffRequest, mergeContext:MergeContext, mergeRequest:TextMergeRequest,
			mergeViewer:TextMergeViewer) {
		super(context, request);
		myMergeContext = mergeContext;
		myMergeRequest = mergeRequest;
		myTextMergeViewer = mergeViewer;

		myModel = new MyMergeModel(getProject(), getEditor().getDocument());

		myModifierProvider = new ModifierProvider();
		myInnerDiffWorker = new MyInnerDiffWorker();

		// myLineStatusTracker = new SimpleLineStatusTracker(getProject(), getEditor().getDocument(), MyLineStatusMarkerRenderer::new);

		myTextDiffProvider = new TextDiffProviderBase(getTextSettings(), function() {
			restartMergeResolveIfNeeded();
			myInnerDiffWorker.onSettingsChanged();
		}, this,
			ar(IgnorePolicy.DEFAULT, IgnorePolicy.TRIM_WHITESPACES, IgnorePolicy.IGNORE_WHITESPACES), ar(HighlightPolicy.BY_LINE, HighlightPolicy.BY_WORD));

		// getTextSettings().addListener(new TextDiffSettingsHolder.TextDiffSettings.Listener() {
		//   @Override
		//   public Void resolveConflictsInImportsChanged() {
		//     restartMergeResolveIfNeeded();
		//   }
		// }, this);
		myCurrentIgnorePolicy = myTextDiffProvider.getIgnorePolicy();
		myResolveImportConflicts = getTextSettings().isAutoResolveImportConflicts();
		myCancelResolveAction = getResolveAction(MergeResult.CANCEL);
		myLeftResolveAction = getResolveAction(MergeResult.LEFT);
		myRightResolveAction = getResolveAction(MergeResult.RIGHT);
		myAcceptResolveAction = getResolveAction(MergeResult.RESOLVED);

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

	public function getResolveAction(result:MergeResult):Action {
		var caption:String = MergeUtil.getResolveActionTitle(result, myMergeRequest, myMergeContext);
		var a = new AbstractAction(caption);
		a.actionPerformed = function(e:ActionEvent) {
			if ((result == MergeResult.LEFT || result == MergeResult.RIGHT)
				&& !MergeUtil.showConfirmDiscardChangesDialog(myPanel.getRootPane(),
					result == MergeResult.LEFT ? DiffBundle.message("button.merge.resolve.accept.left") : DiffBundle.message("button.merge.resolve.accept.right"),
					myContentModified)) {
				return;
			}
			if (result == MergeResult.RESOLVED
				&& (getChangesCount() > 0 || getConflictsCount() > 0)
				&& !MessageDialogBuilder.yesNo(DiffBundle.message("apply.partially.resolved.merge.dialog.title"),
					DiffBundle.message("merge.dialog.apply.partially.resolved.changes.confirmation.message", getChangesCount(), getConflictsCount()))
					.yesText(DiffBundle.message("apply.changes.and.mark.resolved"))
					.noText(DiffBundle.message("continue.merge"))
					.ask(myPanel.getRootPane())) {
				return;
			}
			if (result == MergeResult.CANCEL
				&& !MergeUtil.showExitWithoutApplyingChangesDialog(myTextMergeViewer, myMergeRequest, myMergeContext, myContentModified)) {
				return;
			}
			doFinishMerge(result, MergeResultSource.DIALOG_BUTTON);
		}

		return a;
	}

	private function doFinishMerge(result:MergeResult, source:MergeResultSource):Void {
		logMergeResult(result, source);
		destroyChangedBlocks();
		myMergeContext.finishMerge(result);
	}

	//
	// Diff
	//

	private function restartMergeResolveIfNeeded():Void {
		if (isDisposed())
			return;
		if (myTextDiffProvider.getIgnorePolicy().equals(myCurrentIgnorePolicy)
			&& getTextSettings().isAutoResolveImportConflicts() == myResolveImportConflicts) {
			return;
		}

		if (!myInitialRediffFinished) {
			ApplicationManager.getApplication().invokeLater(() -> restartMergeResolveIfNeeded());
			return;
		}

		if (myContentModified) {
			if (Messages.showYesNoDialog(myProject, DiffBundle.message("changing.highlighting.requires.the.file.merge.restart"),
				DiffBundle.message("update.highlighting.settings"), DiffBundle.message("discard.changes.and.restart.merge"),
				DiffBundle.message("continue.merge"), Messages.getQuestionIcon()) != Messages.YES) {
				getTextSettings().setIgnorePolicy(myCurrentIgnorePolicy);
				getTextSettings().setAutoResolveImportConflicts(myResolveImportConflicts);
				return;
			}
		}

		myInitialRediffFinished = false;
		doRediff();
	}

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
	// public Void rediff(Bool trySync) {
	//   if (myInitialRediffStarted) return;
	//   myInitialRediffStarted = true;
	//   assert myAllMergeChanges.isEmpty();
	//   doRediff();
	// }
	//
	// @NotNull
	// @Override
	// private function Runnable performRediff(ProgressIndicator indicator) {
	//   throw new UnsupportedOperationException();
	// }
	//
	// @RequiresEdt
	// private Void doRediff() {
	//   myStatusPanel.setBusy(true);
	//   myInnerDiffWorker.disable();
	//
	//   // This is made to reduce unwanted modifications before rediff is finished.
	//   // It could happen between this init() EDT chunk and invokeLater().
	//   getEditor().setViewer(true);
	//   myLoadingPanel.startLoading();
	//   myAcceptResolveAction.setEnabled(false);
	//
	//   BackgroundTaskUtil.executeAndTryWait(indicator -> BackgroundTaskUtil.runUnderDisposeAwareIndicator(this, () -> {
	//                                          try {
	//                                            return doPerformRediff(indicator);
	//                                          }
	//                                          catch (ProcessCanceledException e) {
	//                                            return () -> myMergeContext.finishMerge(MergeResult.CANCEL);
	//                                          }
	//                                          catch (Throwable e) {
	//                                            LOG.error(e);
	//                                            return () -> myMergeContext.finishMerge(MergeResult.CANCEL);
	//                                          }
	//                                        }), null, ProgressIndicatorWithDelayedPresentation.DEFAULT_PROGRESS_DIALOG_POSTPONE_TIME_MILLIS,
	//                                        ApplicationManager.getApplication().isUnitTestMode());
	// }
	//
	// @NotNull
	// private function Runnable doPerformRediff(ProgressIndicator indicator) {
	//   try {
	//     List<CharSequence> sequences = new ArrayList<>();
	//
	//     indicator.checkCanceled();
	//     IgnorePolicy ignorePolicy = myTextDiffProvider.getIgnorePolicy();
	//
	//     List<DocumentContent> contents = myMergeRequest.getContents();
	//     MergeRange importRange = ReadAction.compute(() -> {
	//       sequences.addAll(ContainerUtil.map(contents, content -> content.getDocument().getImmutableCharSequence()));
	//       if (getTextSettings().isAutoResolveImportConflicts()) {
	//         initPsiFiles();
	//         return MergeImportUtil.getImportMergeRange(myProject, myPsiFiles);
	//       }
	//       return null;
	//     });
	//     MergeLineFragmentsWithImportMetadata lineFragments = getLineFragments(indicator, sequences, importRange, ignorePolicy);
	//     List<LineOffsets> lineOffsets = ContainerUtil.map(sequences, LineOffsetsUtil::create);
	//     List<MergeConflictType> conflictTypes = ContainerUtil.map(lineFragments.getFragments(), fragment -> {
	//       return MergeRangeUtil.getLineMergeType(fragment, sequences, lineOffsets, ignorePolicy.getComparisonPolicy());
	//     });
	//
	//     FoldingModelSupport.Data foldingState =
	//       myFoldingModel.createState(lineFragments.getFragments(), lineOffsets, getFoldingModelSettings());
	//
	//     return () -> apply(ThreeSide.BASE.select(sequences), lineFragments, conflictTypes, foldingState, ignorePolicy);
	//   }
	//   catch (DiffTooBigException e) {
	//     return applyNotification(DiffNotifications.createDiffTooBig());
	//   }
	//   catch (ProcessCanceledException e) {
	//     throw e;
	//   }
	//   catch (Throwable e) {
	//     LOG.error(e);
	//     return () -> {
	//       clearDiffPresentation();
	//       myPanel.setErrorContent();
	//     };
	//   }
	// }
	//
	// @NotNull
	// @ApiStatus.Internal
	// public TextMergeRequest getMergeRequest() {
	//   return myMergeRequest;
	// }
	//
	private static function getLineFragments(indicator:ProgressIndicator, sequences:List<CharSequence>, importRange:Null<MergeRange>,
			ignorePolicy:IgnorePolicy):MergeLineFragmentsWithImportMetadata {
		if (importRange != null) {
			return MergeImportUtil.getDividedFromImportsFragments(sequences, ignorePolicy.getComparisonPolicy(), importRange, indicator);
		}
		var manager:ComparisonManager = ComparisonManager.getInstance();

		var fragments:List<MergeLineFragment> = manager.mergeLines(sequences.get(0), sequences.get(1), sequences.get(2), ignorePolicy.getComparisonPolicy(),
			indicator);
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

	private function apply(baseContent:CharSequence, fragmentsWithMetadata:MergeLineFragmentsWithImportMetadata, conflictTypes:List<MergeConflictType>,
			foldingState:Null<FoldingModelSupport.Data>, ignorePolicy:IgnorePolicy):Void {
		if (isDisposed())
			return;
		myFoldingModel.updateContext(myRequest, getFoldingModelSettings());
		clearDiffPresentation();
		resetChangeCounters();

		var success:Bool = setInitialOutputContent(baseContent);
		var fragments:List<MergeLineFragment> = fragmentsWithMetadata.getFragments();

		if (!success) {
			fragments = Collections.emptyList();
			conflictTypes = Collections.emptyList();
			myPanel.addNotification(DiffNotifications.createNotification(DiffBundle.message("error.cant.resolve.conflicts.in.a.read.only.file")));
		}

		myModel.setChanges(ContainerUtil.map(fragments, f -> new LineRange(f.getStartLine(ThreeSide.BASE), f.getEndLine(ThreeSide.BASE))));

		for (index in 0...fragments.size() - 1) {
			var fragment:MergeLineFragment = fragments.get(index);
			var conflictType:MergeConflictType = conflictTypes.get(index);

			var isInImportRange:Bool = fragmentsWithMetadata.isIndexInImportRange(index);
			var change:TextMergeChange = new TextMergeChange(index, isInImportRange, fragment, conflictType, myTextMergeViewer);

			myAllMergeChanges.add(change);
			onChangeAdded(change);
		}

		myFoldingModel.install(foldingState, myRequest, getFoldingModelSettings());

		myInitialScrollHelper.onRediff();

		myContentPanel.repaintDividers();
		myStatusPanel.update();

		getEditor().setViewer(false);
		myLoadingPanel.stopLoading();
		myAcceptResolveAction.setEnabled(true);

		myInnerDiffWorker.onEverythingChanged();
		myInitialRediffFinished = true;
		myContentModified = false;
		myCurrentIgnorePolicy = ignorePolicy;
		myResolveImportConflicts = getTextSettings().isAutoResolveImportConflicts();

		// build initial statistics
		var autoResolvableChanges:Int = ContainerUtil.count(getAllChanges(), c -> canResolveChangeAutomatically(c, ThreeSide.BASE));

		myAggregator = new MergeStatisticsAggregator(getAllChanges().size(), autoResolvableChanges, getConflictsCount());

		if (myResolveImportConflicts) {
			var importChanges:List<TextMergeChange> = ContainerUtil.filter(getChanges(), change -> change.isImportChange());
			if (importChanges.size() != fragmentsWithMetadata.getFragments().size()) {
				for (importChange in importChanges) {
					markChangeResolved(importChange);
				}
			}
		}
		if (getTextSettings().isAutoApplyNonConflictedChanges()) {
			if (hasNonConflictedChanges(ThreeSide.BASE)) {
				applyNonConflictedChanges(ThreeSide.BASE);
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

	public function getLoadedResolveAction(result:MergeResult):Action {
		return switch (result) {
			case CANCEL: myCancelResolveAction;
			case LEFT: myLeftResolveAction;
			case RIGHT: myRightResolveAction;
			case RESOLVED: myAcceptResolveAction;
		};
	}

	// public Bool isContentModified() {
	//   return myContentModified;
	// }
	//
	// By-word diff
	//
	//
	// Impl
	//

	private function onBeforeDocumentChange(e:DocumentEvent):Void {
		super.onBeforeDocumentChange(e);
		if (myInitialRediffFinished)
			myContentModified = true;
	}

	// public Void repaintDividers() {
	//   myContentPanel.repaintDividers();
	// }

	private function onChangeResolved(change:TextMergeChange):Void {
		if (change.isResolved()) {
			onChangeRemoved(change);
		} else {
			onChangeAdded(change);
		}
		if (getChangesCount() == 0 && getConflictsCount() == 0) {
			// LOG.assertTrue(ContainerUtil.and(getAllChanges(), TextMergeChange::isResolved));
			ApplicationManager.getApplication().invokeLater(function() {
				if (isDisposed())
					return;

				var component:JComponent = getEditor().getComponent();
				var point:RelativePoint = new RelativePoint(component, new Point(component.getWidth() / 2, JBUIScale.scale(5)));

				var title:String = DiffBundle.message("merge.all.changes.processed.title.text");
				var message:String = XmlStringUtil.wrapInHtmlTag(DiffBundle.message("merge.all.changes.processed.message.text"), "a");
				DiffBalloons.showSuccessPopup(title, message, point, this, function() {
					if (isDisposed() || myLoadingPanel.isLoading())
						return;
					doFinishMerge(MergeResult.RESOLVED, MergeResultSource.NOTIFICATION);
				});
			});
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

	public function getChanges():List<TextMergeChange> {
		return ContainerUtil.filter(myAllMergeChanges, mergeChange -> !mergeChange.isResolved());
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
	public function executeMergeCommand(commandName:String, underBulkUpdate:Bool, affected:Null<TextMergeChange>, task:Runnable):Bool {
		myContentModified = true;

		var affectedIndexes:IntList = null;
		if (affected != null) {
			affectedIndexes = new IntArrayList(affected.size());
			for (change in affected) {
				affectedIndexes.add(change.getIndex());
			}
		}

		return myModel.executeMergeCommand(commandName, null, UndoConfirmationPolicy.DEFAULT, underBulkUpdate, affectedIndexes, task);
	}

	public function executeMergeCommand(commandName:String, affected:Null<TextMergeChange>, task:Runnable):Bool {
		return executeMergeCommand(commandName, false, affected, task);
	}

	public function markChangeResolved(change:TextMergeChange):Void {
		if (change.isResolved())
			return;
		change.setResolved(Side.LEFT, true);
		change.setResolved(Side.RIGHT, true);

		onChangeResolved(change);
		myModel.invalidateHighlighters(change.getIndex());
	}

	public function markChangeResolved(change:TextMergeChange, side:Side):Void {
		if (change.isResolved(side))
			return;
		change.setResolved(side, true);

		if (change.isResolved())
			onChangeResolved(change);
		myModel.invalidateHighlighters(change.getIndex());
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
			markChangeResolved(change);
		} else {
			markChangeResolved(change, side);
		}
	}

	public function replaceChange(change:TextMergeChange, side:Side, resolveChange:Bool):LineRange {
		if (change.isResolved(side))
			return null;
		if (!change.isChange(side)) {
			markChangeResolved(change);
			return null;
		}

		var sourceSide:ThreeSide = side.select(ThreeSide.LEFT, ThreeSide.RIGHT);
		var oppositeSide:ThreeSide = side.select(ThreeSide.RIGHT, ThreeSide.LEFT);

		var sourceDocument:Document = getContent(sourceSide).getDocument();
		var sourceStartLine:Int = change.getStartLine(sourceSide);
		var sourceEndLine:Int = change.getEndLine(sourceSide);
		var newContent:List<String> = DiffUtil.getLines(sourceDocument, sourceStartLine, sourceEndLine);

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

			if (resolveChange || change.getStartLine(oppositeSide) == change.getEndLine(oppositeSide)) {
				markChangeResolved(change);
			} else {
				change.markOnesideAppliedConflict();
				markChangeResolved(change, side);
			}
		} else {
			myModel.replaceChange(change.getIndex(), newContent);
			newLineStart = myModel.getLineStart(change.getIndex());
			markChangeResolved(change);
		}
		var newLineEnd:Int = myModel.getLineEnd(change.getIndex());
		return new LineRange(newLineStart, newLineEnd);
	}

	private function resetResolvedChange(change:TextMergeChange):Void {
		if (!change.isResolved())
			return;
		var changeFragment:MergeLineFragment = change.getFragment();
		var startLine:Int = changeFragment.getStartLine(ThreeSide.BASE);
		var endLine:Int = changeFragment.getEndLine(ThreeSide.BASE);

		var content:Document = ThreeSide.BASE.select(myMergeRequest.getContents()).getDocument();
		var baseContent:List<String> = DiffUtil.getLines(content, startLine, endLine);

		myModel.replaceChange(change.getIndex(), baseContent);

		change.resetState();
		if (change.isResolvedWithAI()) {
			myAggregator.wasRolledBackAfterAI(change.getIndex());
		}
		onChangeResolved(change);
		myModel.invalidateHighlighters(change.getIndex());
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
	//     for (i in 0...changes.size() - 1) {
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
		return ContainerUtil.exists(getAllChanges(), function(change) {
			!change.isConflict()
			&& canResolveChangeAutomatically(change, side);
		});
	}

	private function applyNonConflictedChanges(side:ThreeSide):Void {
		executeMergeCommand(DiffBundle.message("merge.dialog.apply.non.conflicted.changes.command"), true, null, function() {
			resolveChangesAutomatically(ContainerUtil.filter(getAllChanges(), change -> !change.isConflict()), side);
		});

		var firstUnresolved:TextMergeChange = ContainerUtil.find(getAllChanges(), c -> !c.isResolved());
		if (firstUnresolved != null)
			doScrollToChange(firstUnresolved, true);
	}

	private function hasResolvableConflictedChanges():Bool {
		return ContainerUtil.exists(getAllChanges(), function(change) {
			canResolveChangeAutomatically(change, ThreeSide.BASE);
		});
	}

	public function applyResolvableConflictedChanges():Void {
		var changes:List<TextMergeChange> = getAllChanges();
		executeMergeCommand(DiffBundle.message("message.resolve.simple.conflicts.command"), true, null, function() {
			resolveChangesAutomatically(changes, ThreeSide.BASE);
		});

		var firstUnresolved:TextMergeChange = ContainerUtil.find(changes, c -> !c.isResolved());
		if (firstUnresolved != null)
			doScrollToChange(firstUnresolved, true);
	}

	public function canResolveChangeAutomatically(change:TextMergeChange, side:ThreeSide):Bool {
		if (change.isConflict()) {
			return side == ThreeSide.BASE
				&& change.getConflictType().canBeResolved()
				&& !change.isResolved(Side.LEFT)
				&& !change.isResolved(Side.RIGHT)
				&& !isChangeRangeModified(change);
		} else {
			return !change.isResolved() && change.isChange(side) && !isChangeRangeModified(change);
		}
	}

	private function isChangeRangeModified(change:TextMergeChange):Bool {
		var changeFragment:MergeLineFragment = change.getFragment();
		var baseStartLine:Int = changeFragment.getStartLine(ThreeSide.BASE);
		var baseEndLine:Int = changeFragment.getEndLine(ThreeSide.BASE);
		var baseDiffContent:DocumentContent = ThreeSide.BASE.select(myMergeRequest.getContents());
		var baseDocument:Document = baseDiffContent.getDocument();

		var resultStartLine:Int = change.getStartLine();
		var resultEndLine:Int = change.getEndLine();
		var resultDocument:Document = getEditor().getDocument();

		var baseContent:CharSequence = DiffUtil.getLinesContent(baseDocument, baseStartLine, baseEndLine);
		var resultContent:CharSequence = DiffUtil.getLinesContent(resultDocument, resultStartLine, resultEndLine);
		return !StringUtil.equals(baseContent, resultContent);
	}

	public function resolveChangesAutomatically(changes:List<TextMergeChange>, threeSide:ThreeSide):Void {
		processChangesAndTransferData(changes, threeSide, function(change) {
			resolveChangeAutomatically(change, threeSide);
		});
	}

	public function resolveSingleChangeAutomatically(change:TextMergeChange, side:ThreeSide):Void {
		resolveChangesAutomatically(Collections.singletonList(change), side);
	}

	public function replaceChanges(changes:List<TextMergeChange>, side:Side, resolveChanges:Bool):Void {
		processChangesAndTransferData(changes, side.select(ThreeSide.LEFT, ThreeSide.RIGHT), (change) -> replaceChange(change, side, resolveChanges));
	}

	public function replaceSingleChange(change:TextMergeChange, side:Side, resolveChange:Bool):Void {
		replaceChanges(Collections.singletonList(change), side, resolveChange);
	}

	private function processChangesAndTransferData(changes:List<TextMergeChange>, side:ThreeSide, processor:Function<TextMergeChange, LineRange>):Void {
		var newRanges:ArrayList<LineRange> = new ArrayList<>();
		var filteredChanges:List<TextMergeChange> = new ArrayList<>();

		for (change in changes) {
			if (change.isImportChange()) {
				continue;
			}
			var newRange:LineRange = processor.apply(change);
			if (newRange != null) {
				newRanges.add(newRange);
				filteredChanges.add(change);
			}
		}
		transferReferenceData(filteredChanges, side, newRanges);
	}

	private function transferReferenceData(changes:List<TextMergeChange>, side:ThreeSide, newRanges:List<LineRange>):Void {
		if (myResolveImportConflicts) {
			var document:Document = getContent(ThreeSide.BASE).getDocument();
			var markers:List<RangeMarker> = ContainerUtil.map(newRanges,
				range -> document.createRangeMarker(document.getLineStartOffset(range.start), document.getLineEndOffset(range.end)));
			transferReferences(side, changes, markers);
		}
	}

	public function resolveChangeAutomatically(change:TextMergeChange, side:ThreeSide):LineRange {
		if (!canResolveChangeAutomatically(change, side))
			return null;

		if (change.isConflict()) {
			var texts:List<CharSequence> = ThreeSide.map(it -> DiffUtil.getLinesContent(getEditor(it).getDocument(), change.getStartLine(it),
				change.getEndLine(it)));

			var newContent:CharSequence = ComparisonMergeUtil.tryResolveConflict(texts.get(0), texts.get(1), texts.get(2));
			if (newContent == null) {
				LOG.warn(String.format("Can't resolve conflicting change:\n'%s'\n'%s'\n'%s'\n", texts.get(0), texts.get(1), texts.get(2)));
				return null;
			}

			var newContentLines:Array<String> = LineTokenizer.tokenize(newContent, false);
			myModel.replaceChange(change.getIndex(), Arrays.asList(newContentLines));
			markChangeResolved(change);
			return new LineRange(myModel.getLineStart(change.getIndex()), myModel.getLineEnd(change.getIndex()));
		} else {
			var masterSide:Side = side.select(Side.LEFT, change.isChange(Side.LEFT) ? Side.LEFT : Side.RIGHT, Side.RIGHT);
			return replaceChange(change, masterSide, false);
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
}
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
// private function class MyMergeModel extends MergeModelBase<TextMergeChange.State> {
//   MyMergeModel(Null<Project> project, Document document) {
//     super(project, document);
//   }
//
//   @Override
//   private function Void reinstallHighlighters(Int index) {
//     TextMergeChange change = myAllMergeChanges.get(index);
//     change.reinstallHighlighters();
//     myInnerDiffWorker.scheduleRediff(change);
//   }
//
//   @NotNull
//   @Override
//   private function TextMergeChange.State storeChangeState(Int index) {
//     TextMergeChange change = myAllMergeChanges.get(index);
//     return change.storeState();
//   }
//
//   @Override
//   private function Void restoreChangeState(TextMergeChange.State state) {
//     super.restoreChangeState(state);
//     TextMergeChange change = myAllMergeChanges.get(state.myIndex);
//
//     Bool wasResolved = change.isResolved();
//     if (change.isResolvedWithAI()) {
//       myAggregator.wasUndoneAfterAI(change.getIndex());
//     }
//     change.restoreState(state);
//     if (wasResolved != change.isResolved()) onChangeResolved(change);
//   }
//
//   @Nullable
//   @Override
//   private function TextMergeChange.State processDocumentChange(Int index, Int oldLine1, Int oldLine2, Int shift) {
//     TextMergeChange.State state = super.processDocumentChange(index, oldLine1, oldLine2, shift);
//
//     TextMergeChange mergeChange = myAllMergeChanges.get(index);
//     if (mergeChange.getStartLine() == mergeChange.getEndLine() &&
//         mergeChange.getConflictType().getType() == MergeConflictType.Type.DELETED && !mergeChange.isResolved()) {
//       markChangeResolved(mergeChange);
//     }
//
//     return state;
//   }
//
//   @Override
//   private function Void onRangeManuallyEdit(Int index) {
//     TextMergeChange change = myAllMergeChanges.get(index);
//     if (change.isResolvedWithAI()) {
//       myAggregator.wasEditedAfterAi(index);
//     }
//   }
// }
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
