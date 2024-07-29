/*
 * Copyright 2000-2015 JetBrains s.r.o.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package diff.merge;

import diff.util.ThreeSide;

// import diff.util.ThreeSide;
abstract class ThreesideTextDiffViewer {
	// private var myEditors:Null<List<EditorEx>>;
	// private final myEditableEditors:List<EditorEx>;
	// private final myVisibleAreaListener:MyVisibleAreaListener = new MyVisibleAreaListener();
	// private var mySyncScrollSupport:Null<ThreesideSyncScrollSupport>;
	// private final myEditorSettingsAction:SetEditorSettingsAction;
	private final myRequest:Array<String>;

	public function new(/*context:DiffContext, */ request:Array<String>) {
		myRequest = request;

		// super(/*context, */request, TextEditorHolder.TextEditorHolderFactory.INSTANCE);
		//
		// new MyFocusOppositePaneAction(true).install(myPanel);
		// new MyFocusOppositePaneAction(false).install(myPanel);
		//
		// myEditorSettingsAction = new SetEditorSettingsAction(getTextSettings(), getEditors());
		// myEditorSettingsAction.applyDefaults();
		//
		// new MyOpenInEditorWithMouseAction().install(getEditors());
		//
		// myEditableEditors = TextDiffViewerUtil.getEditableEditors(getEditors());
		//
		// TextDiffViewerUtil.checkDifferentDocuments(myRequest);
		//
		// for (side in ThreeSide.values()) {
		// 	DiffUtil.installLineConvertor(getEditor(side), getContent(side));
		// }
		//
		// if (getProject() != null) {
		// 	for (side in ThreeSide.values()) {
		// 		myContentPanel.setBreadcrumbs(side, new SimpleDiffBreadcrumbsPanel(getEditor(side), this), getTextSettings());
		// 	}
		// }
	}

	// private function onInit():Void {
	// 	super.onInit();
	// 	installEditorListeners();
	// }
	//
	// private function onDispose():Void {
	// 	destroyEditorListeners();
	// 	super.onDispose();
	// }
	//
	// private function createEditorHolders(factory:EditorHolderFactory<TextEditorHolder>):List<TextEditorHolder> {
	// 	var holders:List<TextEditorHolder> = super.createEditorHolders(factory);
	//
	// 	var forceReadOnly:Array<Bool> = TextDiffViewerUtil.checkForceReadOnly(myContext, myRequest);
	// 	for (i = 0...3 - 1
	// )
	// 	{
	// 		if (forceReadOnly[i])
	// 			holders.get(i).getEditor().setViewer(true);
	// 	}
	//
	// 	ThreeSide.LEFT.select(holders).getEditor().setVerticalScrollbarOrientation(EditorEx.VERTICAL_SCROLLBAR_LEFT);
	//
	// 	for (holder in holders) {
	// 		DiffUtil.disableBlitting(holder.getEditor());
	// 	}
	//
	// 	return holders;
	// }
	//
	// private List<JComponent> createTitles() {
	//   return DiffUtil.createTextTitles(this, myRequest, getEditors());
	// }
	//
	// Listeners
	//
	// private function installEditorListeners(): Void {
	//   new TextDiffViewerUtil.EditorActionsPopup(createEditorPopupActions()).install(getEditors(), myPanel);
	//
	//   new TextDiffViewerUtil.EditorFontSizeSynchronizer(getEditors()).install(this);
	//
	//   getEditor(ThreeSide.LEFT).getScrollingModel().addVisibleAreaListener(myVisibleAreaListener);
	//   getEditor(ThreeSide.BASE).getScrollingModel().addVisibleAreaListener(myVisibleAreaListener);
	//   getEditor(ThreeSide.RIGHT).getScrollingModel().addVisibleAreaListener(myVisibleAreaListener);
	//
	//   SyncScrollSupport.SyncScrollable scrollable1 = getSyncScrollable(Side.LEFT);
	//   SyncScrollSupport.SyncScrollable scrollable2 = getSyncScrollable(Side.RIGHT);
	//   if (scrollable1 != null && scrollable2 != null) {
	//     mySyncScrollSupport = new ThreesideSyncScrollSupport(getEditors(), scrollable1, scrollable2);
	//     myEditorSettingsAction.setSyncScrollSupport(mySyncScrollSupport);
	//   }
	// }
	//
	// @RequiresEdt
	// public Void destroyEditorListeners() {
	//   getEditor(ThreeSide.LEFT).getScrollingModel().removeVisibleAreaListener(myVisibleAreaListener);
	//   getEditor(ThreeSide.BASE).getScrollingModel().removeVisibleAreaListener(myVisibleAreaListener);
	//   getEditor(ThreeSide.RIGHT).getScrollingModel().removeVisibleAreaListener(myVisibleAreaListener);
	//
	//   mySyncScrollSupport = null;
	// }
	// private Void disableSyncScrollSupport(Bool disable) {
	//   if (mySyncScrollSupport != null) {
	//     if (disable) {
	//       mySyncScrollSupport.enterDisableScrollSection();
	//     }
	//     else {
	//       mySyncScrollSupport.exitDisableScrollSection();
	//     }
	//   }
	// }
	//
	//
	// Diff
	//
	// @NotNull
	// public TextDiffSettings getTextSettings() {
	//   return TextDiffViewerUtil.getTextSettings(myContext);
	// }
	//
	// @NotNull
	// private List<AnAction> createEditorPopupActions() {
	//   return TextDiffViewerUtil.createEditorPopupActions();
	// }
	//
	// @Override
	// private function onDocumentChange(event:DocumentEvent):Void {
	// 	super.onDocumentChange(event);
	// 	myContentPanel.repaintDividers();
	// }
	//
	// Getters
	//
	// @NotNull
	// @Override
	// public EditorEx getCurrentEditor() {
	//   return getEditor(getCurrentSide());
	// }
	// public function getCurrentContent():DocumentContent {
	// 	return getContent(getCurrentSide());
	// }
	//
	public function getContents():Array<String> {
		// noinspection unchecked,rawtypes
		// return myRequest.getContents();
		return myRequest;
	}

	//
	// public function getEditors():List<EditorEx> {
	// 	if (myEditors == null) {
	// 		myEditors = ContainerUtil.map(getEditorHolders(), holder -> holder.getEditor());
	// 	}
	// 	return myEditors;
	// }
	//
	// private function getEditableEditors():List<EditorEx> {
	// 	return myEditableEditors;
	// }
	//
	// public function getEditor(side:ThreeSide):EditorEx {
	// 	return side.select(getEditors());
	// }
	//
	// public function getContent(side:ThreeSide):DocumentContent {
	// 	return side.select(getContents());
	// }

	public function getContentString(side:ThreeSide):String {
		return side.selectC(getContents());
	}

	//
	// public function getEditorSide(editor:Null<Editor>):ThreeSide {
	// 	if (getEditor(ThreeSide.BASE) == editor)
	// 		return ThreeSide.BASE;
	// 	if (getEditor(ThreeSide.RIGHT) == editor)
	// 		return ThreeSide.RIGHT;
	// 	if (getEditor(ThreeSide.LEFT) == editor)
	// 		return ThreeSide.LEFT;
	// 	return null;
	// }
	//
	// Abstract
	//
	// private function scrollToLine(ThreeSide side, Int line): Void {
	//   DiffUtil.scrollEditor(getEditor(side), line, false);
	//   setCurrentSide(side);
	// }
	//
	// @Nullable
	// private abstract SyncScrollSupport.SyncScrollable getSyncScrollable(Side side);
	//
	// @RequiresEdt
	// @NotNull
	// private LogicalPosition transferPosition(ThreeSide baseSide,
	//                                            ThreeSide targetSide,
	//                                            LogicalPosition position) {
	//   if (mySyncScrollSupport == null) return position;
	//   if (baseSide == targetSide) return position;
	//
	//   SyncScrollSupport.SyncScrollable scrollable12 = mySyncScrollSupport.getScrollable12();
	//   SyncScrollSupport.SyncScrollable scrollable23 = mySyncScrollSupport.getScrollable23();
	//
	//   Int baseLine; // line number in BASE
	//   if (baseSide == ThreeSide.LEFT) {
	//     baseLine = scrollable12.transfer(Side.LEFT, position.line);
	//   }
	//   else if (baseSide == ThreeSide.RIGHT) {
	//     baseLine = scrollable23.transfer(Side.RIGHT, position.line);
	//   }
	//   else {
	//     baseLine = position.line;
	//   }
	//
	//   Int targetLine;
	//   if (targetSide == ThreeSide.LEFT) {
	//     targetLine = scrollable12.transfer(Side.RIGHT, baseLine);
	//   }
	//   else if (targetSide == ThreeSide.RIGHT) {
	//     targetLine = scrollable23.transfer(Side.LEFT, baseLine);
	//   }
	//   else {
	//     targetLine = baseLine;
	//   }
	//
	//   return new LogicalPosition(targetLine, position.column);
	// }
	//
	// Misc
	//
	// @Nullable
	// @Override
	// private Navigatable getNavigatable() {
	//   return getCurrentContent().getNavigatable(LineCol.fromCaret(getCurrentEditor()));
	// }
	//
	// public static Bool canShowRequest(DiffContext context, DiffRequest request) {
	//   return ThreesideDiffViewer.canShowRequest(context, request, TextEditorHolder.TextEditorHolderFactory.INSTANCE);
	// }
	//
	// Actions
	//
	// private class MyOpenInEditorWithMouseAction extends OpenInEditorWithMouseAction {
	//   @Override
	//   private Navigatable getNavigatable(Editor editor, Int line) {
	//     ThreeSide side = getEditorSide(editor);
	//     if (side == null) return null;
	//
	//     return getContent(side).getNavigatable(new LineCol(line));
	//   }
	// }
	//
	// private class MyToggleAutoScrollAction extends TextDiffViewerUtil.ToggleAutoScrollAction {
	//   public MyToggleAutoScrollAction() {
	//     super(getTextSettings());
	//   }
	// }
	//
	// Helpers
	//
	// @Nullable
	// @Override
	// public Object getData(@NonNls String dataId) {
	//   if (DiffDataKeys.CURRENT_EDITOR.is(dataId)) {
	//     return getCurrentEditor();
	//   }
	//   return super.getData(dataId);
	// }
	//
	// private class MyVisibleAreaListener implements VisibleAreaListener {
	//   @Override
	//   public Void visibleAreaChanged(VisibleAreaEvent e) {
	//     if (mySyncScrollSupport != null) mySyncScrollSupport.visibleAreaChanged(e);
	//     myContentPanel.repaint();
	//   }
	// }
	//
	// private abstract class MyInitialScrollPositionHelper extends InitialScrollPositionSupport.ThreesideInitialScrollHelper {
	//   @NotNull
	//   @Override
	//   private List<? extends Editor> getEditors() {
	//     return ThreesideTextDiffViewer.this.getEditors();
	//   }
	//
	//   @Override
	//   private Void disableSyncScroll(Bool value) {
	//     disableSyncScrollSupport(value);
	//   }
	//
	//   @Override
	//   private Bool doScrollToLine() {
	//     if (myScrollToLine == null) return false;
	//
	//     scrollToLine(myScrollToLine.first, myScrollToLine.second);
	//     return true;
	//   }
	// }
	//
	// private class TextShowPartialDiffAction extends ShowPartialDiffAction {
	//   public TextShowPartialDiffAction(PartialDiffMode mode, Bool hasFourSides) {
	//     super(mode, hasFourSides);
	//   }
	//
	//   @NotNull
	//   @Override
	//   private SimpleDiffRequest createRequest() {
	//     SimpleDiffRequest request = super.createRequest();
	//
	//     ThreeSide currentSide = getCurrentSide();
	//     LogicalPosition currentPosition = DiffUtil.getCaretPosition(getCurrentEditor());
	//
	//     // we won't use DiffUserDataKeysEx.EDITORS_CARET_POSITION to aVoid desync scroll position (as they can point to different places)
	//     // TODO: pass EditorsVisiblePositions in case if view was scrolled without changing caret position ?
	//     if (currentSide == mySide1) {
	//       request.putUserData(DiffUserDataKeys.SCROLL_TO_LINE, Pair.create(Side.LEFT, currentPosition.line));
	//     }
	//     else if (currentSide == mySide2) {
	//       request.putUserData(DiffUserDataKeys.SCROLL_TO_LINE, Pair.create(Side.RIGHT, currentPosition.line));
	//     }
	//     else {
	//       LogicalPosition position1 = transferPosition(currentSide, mySide1, currentPosition);
	//       LogicalPosition position2 = transferPosition(currentSide, mySide2, currentPosition);
	//       request.putUserData(DiffUserDataKeysEx.EDITORS_CARET_POSITION, new Array<LogicalPosition>{position1, position2});
	//     }
	//
	//     return request;
	//   }
	// }
	//
	// private class MyFocusOppositePaneAction extends FocusOppositePaneAction {
	//   MyFocusOppositePaneAction(Bool scrollToPosition) {
	//     super(scrollToPosition);
	//   }
	//
	//   @Override
	//   public Void actionPerformed(AnActionEvent e) {
	//     ThreeSide currentSide = getCurrentSide();
	//     ThreeSide targetSide = currentSide.select(ThreeSide.BASE, ThreeSide.RIGHT, ThreeSide.LEFT); // cycle right
	//
	//     EditorEx targetEditor = getEditor(targetSide);
	//
	//     if (myScrollToPosition) {
	//       LogicalPosition currentPosition = DiffUtil.getCaretPosition(getCurrentEditor());
	//       LogicalPosition position = transferPosition(currentSide, targetSide, currentPosition);
	//       targetEditor.getCaretModel().moveToLogicalPosition(position);
	//     }
	//
	//     setCurrentSide(targetSide);
	//     targetEditor.getScrollingModel().scrollToCaret(ScrollType.MAKE_VISIBLE);
	//
	//     DiffUtil.requestFocus(getProject(), getPreferredFocusedComponent());
	//   }
	// }
}
