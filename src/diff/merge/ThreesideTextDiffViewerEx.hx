// Copyright 2000-2020 JetBrains s.r.o. Use of this source code is governed by the Apache 2.0 license that can be found in the LICENSE file.
package diff.merge;

import diff.fragments.TextMergeChange;
import diff.fragments.ThreesideDiffChangeBase;

abstract class ThreesideTextDiffViewerEx extends ThreesideTextDiffViewer {
  // private final mySyncScrollable1: SyncScrollSupport.SyncScrollable ;
  // private final mySyncScrollable2: SyncScrollSupport.SyncScrollable ;

  // private final myPrevNextDifferenceIterable: PrevNextDifferenceIterable ;
  // private final myPrevNextConflictIterable: PrevNextDifferenceIterable ;
  // private final myStatusPanel: StatusPanel ;

  // private final myFoldingModel: MyFoldingModel ;
  // private final myInitialScrollHelper: MyInitialScrollHelper  = new MyInitialScrollHelper();

  private var myChangesCount: Int  = -1;
  private var myConflictsCount: Int  = -1;

  public function new (/*context: DiffContext ,*/ request: Array<String>) {
    super(/*context, */request);

    // mySyncScrollable1 = new MySyncScrollable(Side.LEFT);
    // mySyncScrollable2 = new MySyncScrollable(Side.RIGHT);
    // myPrevNextDifferenceIterable = new MyPrevNextDifferenceIterable();
    // myPrevNextConflictIterable = new MyPrevNextConflictIterable();
    // myStatusPanel = createStatusPanel();
    // myFoldingModel = new MyFoldingModel(getProject(), getEditors().toArray(/*new EditorEx[0]*/), myContentPanel, this);

    // for (side in ThreeSide.values()) {
    //   DiffUtil.installLineConvertor(getEditor(side), getContent(side), myFoldingModel, side.getIndex());
    // }
    //
    // DiffUtil.registerAction(new PrevConflictAction(), myPanel);
    // DiffUtil.registerAction(new NextConflictAction(), myPanel);
  }

  // private function createStatusPanel(): StatusPanel {
  //   return new MyStatusPanel();
  // }
  //
  // private function function onInit(): Void {
  //   super.onInit();
  //   myContentPanel.setPainter(new MyDividerPainter(Side.LEFT), Side.LEFT);
  //   myContentPanel.setPainter(new MyDividerPainter(Side.RIGHT), Side.RIGHT);
  // }
  //
  // private function function processContextHints(): Void {
  //   super.processContextHints();
  //   myInitialScrollHelper.processContext(myRequest);
  // }
  //
  // private function function updateContextHints(): Void {
  //   super.updateContextHints();
  //   myFoldingModel.updateContext(myRequest, getFoldingModelSettings());
  //   myInitialScrollHelper.updateContext(myRequest);
  // }

  //
  // Diff
  //

  // public function function getFoldingModelSettings(): FoldingModelSupport.Settings {
  //   return TextDiffViewerUtil.getFoldingModelSettings(myContext);
  // }

  // private function function applyNotification(notification: Null<JComponent> ): Runnable {
  //   return () -> {
  //     clearDiffPresentation();
  //     myFoldingModel.destroy();
  //     if (notification != null) myPanel.addNotification(notification);
  //   };
  // }

  // @RequiresEdt
  // private function Void clearDiffPresentation() {
  //   myStatusPanel.setBusy(false);
  //   myPanel.resetNotifications();
  //   destroyChangedBlocks();
  //
  //   myContentPanel.repaintDividers();
  //   myStatusPanel.update();
  // }

  private function destroyChangedBlocks(): Void {
  }

  //
  // Impl
  //

  // @RequiresEdt
  // private function Bool doScrollToChange(ScrollToPolicy scrollToPolicy) {
  //   ThreesideDiffChangeBase targetChange = scrollToPolicy.select(getChanges());
  //   if (targetChange == null) return false;
  //
  //   doScrollToChange(targetChange, false);
  //   return true;
  // }
  //
  // private function Void doScrollToChange(ThreesideDiffChangeBase change, Bool animated) {
  //   Int[] startLines = new Int[3];
  //   Int[] endLines = new Int[3];
  //
  //   for (Int i = 0; i < 3; i++) {
  //     ThreeSide side = ThreeSide.fromIndex(i);
  //     startLines[i] = change.getStartLine(side);
  //     endLines[i] = change.getEndLine(side);
  //     DiffUtil.moveCaret(getEditor(side), startLines[i]);
  //   }
  //
  //   getSyncScrollSupport().makeVisible(getCurrentSide(), startLines, endLines, animated);
  // }

  //
  // Counters
  //

  public function getChangesCount(): Int {
    return myChangesCount;
  }

  public function getConflictsCount(): Int {
    return myConflictsCount;
  }

  private function resetChangeCounters(): Void {
    myChangesCount = 0;
    myConflictsCount = 0;
  }

  private function onChangeAdded(change: ThreesideDiffChangeBase ): Void {
    if (change.isConflict()) {
      myConflictsCount++;
    }
    else {
      myChangesCount++;
    }
    // myStatusPanel.update();
  }

  private function onChangeRemoved(change: ThreesideDiffChangeBase ): Void {
    if (change.isConflict()) {
      myConflictsCount--;
    }
    else {
      myChangesCount--;
    }
    // myStatusPanel.update();
  }

  //
  // Getters
  //

  // @NotNull
  // private abstract function DividerPaintable getDividerPaintable(Side side);

  /*
   * Some changes (ex: applied ones) can be excluded from general processing, but should be painted/used for synchronized scrolling
   */
  @NotNull
  public function getAllChanges(): Array<TextMergeChange> {
    return getChanges();
  }

  private abstract function getChanges(): Array<TextMergeChange>;

  // private function getSyncScrollable(side: Side ): SyncScrollSupport.SyncScrollable {
  //   return side.select(mySyncScrollable1, mySyncScrollable2);
  // }

  // private function function getStatusPanel(): JComponent {
  //   return myStatusPanel;
  // }

  // @NotNull
  // public function SyncScrollSupport.ThreesideSyncScrollSupport getSyncScrollSupport() {
  //   //noinspection ConstantConditions
  //   return mySyncScrollSupport;
  // }

  //
  // Misc
  //

  // private function getSelectedChange(side: ThreeSide ): ThreesideDiffChangeBase {
  //   var caretLine: Int  = getEditor(side).getCaretModel().getLogicalPosition().line;
  //
  //   for (change in getChanges()) {
  //     var line1: Int  = change.getStartLine(side);
  //     var line2: Int  = change.getEndLine(side);
  //
  //     if (DiffUtil.isSelectedByLine(caretLine, line1, line2)) return change;
  //   }
  //   return null;
  // }

  //
  // Actions
  //

  // private class PrevConflictAction extends DumbAwareAction {
  //   PrevConflictAction() {
  //     ActionUtil.copyFrom(this, "Diff.PreviousConflict");
  //   }
  //
  //   @Override
  //   public function Void actionPerformed(AnActionEvent e) {
  //     if (!myPrevNextConflictIterable.canGoPrev()) return;
  //     myPrevNextConflictIterable.goPrev();
  //   }
  // }

  // private function class NextConflictAction extends DumbAwareAction {
  //   NextConflictAction() {
  //     ActionUtil.copyFrom(this, "Diff.NextConflict");
  //   }
  //
  //   @Override
  //   public function Void actionPerformed(AnActionEvent e) {
  //     if (!myPrevNextConflictIterable.canGoNext()) return;
  //     myPrevNextConflictIterable.goNext();
  //   }
  // }

  // private function class MyPrevNextConflictIterable extends MyPrevNextDifferenceIterable {
  //   @NotNull
  //   @Override
  //   private function List<? extends ThreesideDiffChangeBase> getChanges() {
  //     List<? extends ThreesideDiffChangeBase> changes = ThreesideTextDiffViewerEx.this.getChanges();
  //     return ContainerUtil.filter(changes, change -> change.isConflict());
  //   }
  // }

  // private function class MyPrevNextDifferenceIterable extends PrevNextDifferenceIterableBase<ThreesideDiffChangeBase> {
  //   @NotNull
  //   @Override
  //   private function List<? extends ThreesideDiffChangeBase> getChanges() {
  //     List<? extends ThreesideDiffChangeBase> changes = ThreesideTextDiffViewerEx.this.getChanges();
  //     final ThreeSide currentSide = getCurrentSide();
  //     if (currentSide == ThreeSide.BASE) return changes;
  //     return ContainerUtil.filter(changes, change -> change.isChange(currentSide));
  //   }
  //
  //   @NotNull
  //   @Override
  //   private function EditorEx getEditor() {
  //     return getCurrentEditor();
  //   }
  //
  //   @Override
  //   private function Int getStartLine(ThreesideDiffChangeBase change) {
  //     return change.getStartLine(getCurrentSide());
  //   }
  //
  //   @Override
  //   private function Int getEndLine(ThreesideDiffChangeBase change) {
  //     return change.getEndLine(getCurrentSide());
  //   }
  //
  //   @Override
  //   private function Void scrollToChange(ThreesideDiffChangeBase change) {
  //     doScrollToChange(change, true);
  //   }
  // }
  //
  // private function class MyToggleExpandByDefaultAction extends TextDiffViewerUtil.ToggleExpandByDefaultAction {
  //   public function MyToggleExpandByDefaultAction() {
  //     super(getTextSettings(), myFoldingModel);
  //   }
  // }

  //
  // Helpers
  //

  // @Nullable
  // @Override
  // public function Object getData(@NonNls String dataId) {
  //   if (DiffDataKeys.PREV_NEXT_DIFFERENCE_ITERABLE.is(dataId)) {
  //     return myPrevNextDifferenceIterable;
  //   }
  //   else if (DiffDataKeys.CURRENT_CHANGE_RANGE.is(dataId)) {
  //     ThreesideDiffChangeBase change = getSelectedChange(getCurrentSide());
  //     if (change != null) {
  //       return new LineRange(change.getStartLine(getCurrentSide()), change.getEndLine(getCurrentSide()));
  //     }
  //   }
  //   else if (DiffDataKeys.EDITOR_CHANGED_RANGE_PROVIDER.is(dataId)) {
  //     return new MyChangedRangeProvider();
  //   }
  //   return super.getData(dataId);
  // }
  //
  // private function class MySyncScrollable extends BaseSyncScrollable {
  //   private function final Side mySide;
  //
  //   public function MySyncScrollable(Side side) {
  //     mySide = side;
  //   }
  //
  //   @Override
  //   public function Bool isSyncScrollEnabled() {
  //     return getTextSettings().isEnableSyncScroll();
  //   }
  //
  //   @Override
  //   private function Void processHelper(ScrollHelper helper) {
  //     ThreeSide left = mySide.select(ThreeSide.LEFT, ThreeSide.BASE);
  //     ThreeSide right = mySide.select(ThreeSide.BASE, ThreeSide.RIGHT);
  //
  //     if (!helper.process(0, 0)) return;
  //     for (diffChange in getAllChanges()) {
  //       if (!helper.process(diffChange.getStartLine(left), diffChange.getStartLine(right))) return;
  //       if (!helper.process(diffChange.getEndLine(left), diffChange.getEndLine(right))) return;
  //     }
  //     helper.process(getLineCount(getEditor(left).getDocument()), getLineCount(getEditor(right).getDocument()));
  //   }
  // }
  //
  // private function class MyDividerPainter implements DiffSplitter.Painter {
  //   private function final Side mySide;
  //   private function final DividerPaintable myPaintable;
  //
  //   public function MyDividerPainter(Side side) {
  //     mySide = side;
  //     myPaintable = getDividerPaintable(side);
  //   }
  //
  //   @Override
  //   public function Void paint(Graphics g, JComponent divider) {
  //     Graphics2D gg = DiffDividerDrawUtil.getDividerGraphics(g, divider, getEditor(ThreeSide.BASE).getComponent());
  //
  //     gg.setColor(DiffDrawUtil.getDividerColor(getEditor(ThreeSide.BASE)));
  //     gg.fill(gg.getClipBounds());
  //
  //     Editor editor1 = mySide.select(getEditor(ThreeSide.LEFT), getEditor(ThreeSide.BASE));
  //     Editor editor2 = mySide.select(getEditor(ThreeSide.BASE), getEditor(ThreeSide.RIGHT));
  //
  //     DiffDividerDrawUtil.paintPolygons(gg, divider.getWidth(), editor1, editor2, myPaintable);
  //
  //     myFoldingModel.paintOnDivider(gg, divider, mySide);
  //
  //     gg.dispose();
  //   }
  // }
  //
  // private function class MyStatusPanel extends StatusPanel {
  //   @Nullable
  //   @Override
  //   private function String getMessage() {
  //     if (myChangesCount < 0 || myConflictsCount < 0) return null;
  //     if (myChangesCount == 0 && myConflictsCount == 0) {
  //       return DiffBundle.message("merge.dialog.all.conflicts.resolved.message.text");
  //     }
  //     return DiffBundle.message("merge.differences.status.text", myChangesCount, myConflictsCount);
  //   }
  // }
  //
  // private function static class MyFoldingModel extends FoldingModelSupport {
  //   private function final MyPaintable myPaintable1 = new MyPaintable(0, 1);
  //   private function final MyPaintable myPaintable2 = new MyPaintable(1, 2);
  //   private function final ThreesideContentPanel myContentPanel;
  //
  //   public function MyFoldingModel(Null<Project> project,
  //                         EditorEx [] editors,
  //                         ThreesideContentPanel contentPanel,
  //                         Disposable disposable) {
  //     super(project, editors, disposable);
  //     myContentPanel = contentPanel;
  //     assert editors.length == 3;
  //   }
  //
  //   @Override
  //   private function Void repaintSeparators() {
  //     myContentPanel.repaint();
  //   }
  //
  //   @Nullable
  //   public function Data createState(Null<List><? extends MergeLineFragment> fragments,
  //                           FoldingModelSupport.Settings settings) {
  //     return createState(fragments, countLines(myEditors), settings);
  //   }
  //
  //   @Nullable
  //   public function Data createState(Null<List><? extends MergeLineFragment> fragments,
  //                           List<? extends LineOffsets> lineOffsets,
  //                           FoldingModelSupport.Settings settings) {
  //     Int[] lineCount = new Int[myEditors.length];
  //     for (Int i = 0; i < myEditors.length; i++) {
  //       lineCount[i] = lineOffsets.get(i).getLineCount();
  //     }
  //     return createState(fragments, lineCount, settings);
  //   }
  //
  //   @Nullable
  //   private function Data createState(Null<List><? extends MergeLineFragment> fragments,
  //                            Int [] lineCount,
  //                            FoldingModelSupport.Settings settings) {
  //     Iterator<Int[]> it = map(fragments, fragment -> new Int[]{
  //       fragment.getStartLine(ThreeSide.LEFT),
  //       fragment.getEndLine(ThreeSide.LEFT),
  //       fragment.getStartLine(ThreeSide.BASE),
  //       fragment.getEndLine(ThreeSide.BASE),
  //       fragment.getStartLine(ThreeSide.RIGHT),
  //       fragment.getEndLine(ThreeSide.RIGHT)
  //     });
  //     return computeFoldedRanges(it, lineCount, settings);
  //   }
  //
  //   @Nullable
  //   private function Data computeFoldedRanges(Null<final> Iterator<Int[]> changedLines,
  //                                    Int [] lineCount,
  //                                    final Settings settings) {
  //     if (changedLines == null || settings.range == -1) return null;
  //
  //     FoldingBuilderBase builder = new MyFoldingBuilder(myEditors, lineCount, settings);
  //     return builder.build(changedLines);
  //   }
  //
  //   public function Void paintOnDivider(Graphics2D gg, Component divider, Side side) {
  //     MyPaintable paintable = side.select(myPaintable1, myPaintable2);
  //     paintable.paintOnDivider(gg, divider);
  //   }
  //
  //   private function static final class MyFoldingBuilder extends FoldingBuilderBase {
  //     private function final EditorEx [] myEditors;
  //
  //     private function MyFoldingBuilder(EditorEx [] editors, Int [] lineCount, Settings settings) {
  //       super(lineCount, settings);
  //       myEditors = editors;
  //     }
  //
  //     @Nullable
  //     @Override
  //     private function FoldedRangeDescription getDescription(Project project, Int lineNumber, Int index) {
  //       return getLineSeparatorDescription(project, myEditors[index].getDocument(), lineNumber);
  //     }
  //   }
  // }
  //
  // private function class MyInitialScrollHelper extends MyInitialScrollPositionHelper {
  //   @Override
  //   private function Bool doScrollToChange() {
  //     if (myScrollToChange == null) return false;
  //     return ThreesideTextDiffViewerEx.this.doScrollToChange(myScrollToChange);
  //   }
  //
  //   @Override
  //   private function Bool doScrollToFirstChange() {
  //     return ThreesideTextDiffViewerEx.this.doScrollToChange(ScrollToPolicy.FIRST_CHANGE);
  //   }
  // }
  //
  // private function class MyChangedRangeProvider implements DiffChangedRangeProvider {
  //   @Override
  //   public function Null<List><TextRange> getChangedRanges(Editor editor) {
  //     ThreeSide side = ThreeSide.fromValue(getEditors(), editor);
  //     if (side == null) return null;
  //
  //     return ContainerUtil.map(getAllChanges(), change -> {
  //       return DiffUtil.getLinesRange(editor.getDocument(), change.getStartLine(side), change.getEndLine(side));
  //     });
  //   }
  // }
}

