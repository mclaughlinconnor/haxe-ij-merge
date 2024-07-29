// Copyright 2000-2024 JetBrains s.r.o. and contributors. Use of this source code is governed by the Apache 2.0 license.
package diff.util;

import util.Runnable;
import diff.tools.util.text.LineOffsets;
import diff.tools.util.text.LineOffsetsUtil;
import diff.util.ThreeSide.ThreeSideEnum;
import diff.comparison.ByWordRt;
import diff.fragments.DiffFragment;
import ds.TextRange;
import diff.comparison.ComparisonUtil;
import diff.tools.util.text.MergeInnerDifferences;
import diff.comparison.ComparisonPolicy;

class Logger {
	public function error(...a:Dynamic) {
		trace(a);
	}

	public function warn(...a:Dynamic) {
		trace(a);
	}

	public function trace(...a:Dynamic) {
		trace(a);
	}

	public function info(...a:Dynamic) {
		trace(a);
	}
}

class DiffUtil {
	// private static final LOG:Logger = Logger.getInstance(DiffUtil);
	// private static final LOG:Logger = Logger;
	// public static final TEMP_FILE_KEY:Key<Bool> = Key.create("Diff.TempFile");
	// public static final DIFF_CONFIG:String = "diff.xml";
	// public static final TITLE_GAP:Float = 2.0;
	// public static final DIFF_FRAME_ICONS:NotNullLazyValue<Array<Image>> = NotNullLazyValue.createValue(() -> {
	// 	return ContainerUtil.skipNulls(Arrays.asList(iconToImage(PlatformDiffImplIcons.Diff_frame32), iconToImage(PlatformDiffImplIcons.Diff_frame64),
	// 		iconToImage(PlatformDiffImplIcons.Diff_frame128)));
	// });
	// private static function iconToImage(icon:Icon):Image {
	// 	return IconLoader.toImage(icon, null);
	// }
	// private static function getDocumentString(documentContent:DocumentContent):String {
	// 	return ReadAction.compute(() -> {
	// 		return documentContent.getDocument().getImmutableString();
	// 	});
	// }
	//
	// Editor
	//
	// public static function isDiffEditor(editor:Editor):Bool {
	// 	return editor.getEditorKind() == EditorKind.DIFF;
	// }
	// public static function isFileWithoutContent(file:VirtualFile):Bool {
	// 	if (Std.isOfType(file, VirtualFileWithoutContent))
	// 		return true;
	// 	return false;
	// }
	// public static function initEditorHighlighter(project:Project, content:DocumentContent, text:String):EditorHighlighter {
	// 	var highlighter:EditorHighlighter = createEditorHighlighter(project, content);
	// 	if (highlighter == null)
	// 		return null;
	// 	highlighter.setText(text);
	// 	return highlighter;
	// }
	// public static function initEmptyEditorHighlighter(text:String):EditorHighlighter {
	// 	var highlighter:EditorHighlighter = createEmptyEditorHighlighter();
	// 	highlighter.setText(text);
	// 	return highlighter;
	// }
	// public static function createEditorHighlighter(project:Project, content:DocumentContent):EditorHighlighter {
	// 	var highlighterFactory:EditorHighlighterFactory = EditorHighlighterFactory.getInstance();
	//
	// 	var file:VirtualFile = FileDocumentManager.getInstance().getFile(content.getDocument());
	// 	var contentType:FileType = content.getContentType();
	// 	var highlightFile:VirtualFile = content.getHighlightFile();
	// 	var language:Language = content.getUserData(DiffUserDataKeys.LANGUAGE);
	// 	var hasContentType:Bool = contentType != null
	// 		&& contentType != PlainTextFileType.INSTANCE
	// 		&& contentType != UnknownFileType.INSTANCE;
	//
	// 	if (language != null) {
	// 		var syntaxHighlighter:SyntaxHighlighter = SyntaxHighlighterFactory.getSyntaxHighlighter(language, project, highlightFile);
	// 		return highlighterFactory.createEditorHighlighter(syntaxHighlighter, EditorColorsManager.getInstance().getGlobalScheme());
	// 	}
	//
	// 	if (highlightFile != null && highlightFile.isValid()) {
	// 		if (!hasContentType
	// 			|| FileTypeRegistry.getInstance().isFileOfType(highlightFile, contentType)
	// 			|| Std.isOfType(highlightFile, LightVirtualFile)) {
	// 			return highlighterFactory.createEditorHighlighter(project, highlightFile);
	// 		}
	// 	}
	//
	// 	if (file != null && file.isValid()) {
	// 		var type:FileType = file.getFileType();
	// 		var hasFileType:Bool = !type.isBinary() && type != PlainTextFileType.INSTANCE;
	// 		if (!hasContentType || hasFileType) {
	// 			return highlighterFactory.createEditorHighlighter(project, file);
	// 		}
	// 	}
	//
	// 	if (contentType != null) {
	// 		return highlighterFactory.createEditorHighlighter(project, contentType);
	// 	}
	// 	return null;
	// }
	// public static function createEmptyEditorHighlighter():EditorHighlighter {
	// 	return new EmptyEditorHighlighter(EditorColorsManager.getInstance().getGlobalScheme().getAttributes(HighlighterColors.TEXT));
	// }
	// public static function setEditorHighlighter(project:Project, editor:EditorEx, content:DocumentContent):Void {
	// 	var disposable:Disposable = Std.downcast(editor, EditorImpl).getDisposable();
	// 	if (project != null) {
	// 		var updater:DiffEditorHighlighterUpdater = new DiffEditorHighlighterUpdater(project, disposable, editor, content);
	// 		updater.updateHighlighters();
	// 	} else {
	// 		ReadAction.nonBlocking(() -> {
	// 			var text:String = editor.getDocument().getImmutableString();
	// 			return initEditorHighlighter(null, content, text);
	// 		})
	// 			.finishOnUiThread(ModalityState.any(), result -> {
	// 				if (result != null)
	// 					editor.setHighlighter(result);
	// 			})
	// 			.expireWith(disposable)
	// 			.submit(NonUrgentExecutor.getInstance());
	// 	}
	// }
	// public static function setEditorCodeStyle(project:Null<Project>, editor:EditorEx, content:Null<DocumentContent>):Void {
	// 	if (project != null && content != null && editor.getVirtualFile() == null) {
	// 		var psiFile:PsiFile = PsiDocumentManager.getInstance(project).getPsiFile(content.getDocument());
	// 		var indentOptions:CommonCodeStyleSettings.IndentOptions = psiFile != null ? CodeStyle.getSettings(psiFile)
	// 			.getIndentOptionsByFile(psiFile) : CodeStyle.getSettings(project).getIndentOptions(content.getContentType());
	// 		editor.getSettings().setTabSize(indentOptions.TAB_SIZE);
	// 		editor.getSettings().setUseTabCharacter(indentOptions.USE_TAB_CHARACTER);
	// 	}
	//
	// 	var language:Language = content != null ? content.getUserData(DiffUserDataKeys.LANGUAGE) : null;
	// 	if (language != null) {
	// 		editor.getSettings().setLanguageSupplier(() -> language);
	// 	} else if (editor.getProject() != null) {
	// 		editor.getSettings().setLanguageSupplier(() -> TextEditorImpl.Companion.getDocumentLanguage(editor));
	// 	}
	//
	// 	editor.getSettings().setCaretRowShown(false);
	// 	editor.reinitSettings();
	// }
	// public static function setFoldingModelSupport(editor:EditorEx):Void {
	// 	editor.getSettings().setFoldingOutlineShown(true);
	// 	editor.getSettings().setAutoCodeFoldingEnabled(false);
	// 	editor.getColorsScheme().setAttributes(EditorColors.FOLDED_TEXT_ATTRIBUTES, null);
	// }
	// public static function createEditor(document:Document, project:Null<Project>, isViewer:Bool):EditorEx {
	// 	return createEditor(document, project, isViewer, false);
	// }
	// public static function createEditor(document:Document, project:Null<Project>, isViewer:Bool, enableFolding:Bool):EditorEx {
	// 	var factory:EditorFactory = EditorFactory.getInstance();
	// 	var kind:EditorKind = EditorKind.DIFF;
	// 	var editor:EditorEx = (EditorEx)(isViewer ? factory.createViewer(document, project, kind) : factory.createEditor(document, project, kind));
	//
	// 	editor.getSettings().setShowIntentionBulb(false);
	// 	Std.isOfType(editor, EditorMarkupModel).getMarkupModel().setErrorStripeVisible(true);
	// 	editor.getGutterComponentEx().setShowDefaultGutterPopup(false);
	//
	// 	if (enableFolding) {
	// 		setFoldingModelSupport(editor);
	// 	} else {
	// 		editor.getSettings().setFoldingOutlineShown(false);
	// 		editor.getFoldingModel().setFoldingEnabled(false);
	// 	}
	//
	// 	UIUtil.removeScrollBorder(editor.getComponent());
	//
	// 	return editor;
	// }
	// public static function configureEditor(editor:EditorEx, content:DocumentContent, project:Null<Project>):Void {
	// 	var virtualFile:VirtualFile = FileDocumentManager.getInstance().getFile(content.getDocument());
	// 	if (virtualFile != null) {
	// 		editor.setFile(virtualFile);
	// 	}
	//
	// 	setEditorHighlighter(project, editor, content);
	// 	setEditorCodeStyle(project, editor, content);
	// }
	// public static function isMirrored(editor:Editor):Bool {
	// 	if (Std.isOfType(editor, EditorEx)) {
	// 		return Std.isOfType(editor, EditorEx).getVerticalScrollbarOrientation() == EditorEx.VERTICAL_SCROLLBAR_LEFT;
	// 	}
	// 	return false;
	// }
	// @Contract("null, _ -> false; _, null -> false")
	// public static function canNavigateToFile(project:Null<Project>, file:Null<VirtualFile>):Bool {
	// 	if (project == null || project.isDefault())
	// 		return false;
	// 	if (file == null || !file.isValid())
	// 		return false;
	// 	if (OutsidersPsiFileSupport.isOutsiderFile(file))
	// 		return false;
	// 	if (file.getUserData(TEMP_FILE_KEY) == Bool.TRUE)
	// 		return false;
	// 	return true;
	// }
	// public static function installLineConvertor(editor:EditorEx, foldingSupport:FoldingModelSupport):Void {
	// 	// assert foldingSupport.getCount() == 1;
	// 	var foldingLinePredicate:IntPredicate = foldingSupport.hideLineNumberPredicate(0);
	// 	editor.getGutter().setLineNumberConverter(new DiffLineNumberConverter(foldingLinePredicate, null));
	// }
	// public static function installLineConvertor(editor:EditorEx, content:DocumentContent):Void {
	// 	var contentLineConvertor:IntUnaryOperator = getContentLineConvertor(content);
	// 	if (contentLineConvertor == null) {
	// 		editor.getGutter().setLineNumberConverter(null);
	// 	} else {
	// 		editor.getGutter().setLineNumberConverter(new DiffLineNumberConverter(null, contentLineConvertor));
	// 	}
	// }
	// public static function installLineConvertor(editor:EditorEx, content:Null<DocumentContent>, foldingSupport:FoldingModelSupport, editorIndex:Int):Void {
	// 	var contentLineConvertor:IntUnaryOperator = content != null ? getContentLineConvertor(content) : null;
	// 	var foldingLinePredicate:IntPredicate = foldingSupport.hideLineNumberPredicate(editorIndex);
	// 	editor.getGutter().setLineNumberConverter(new DiffLineNumberConverter(foldingLinePredicate, contentLineConvertor));
	// }
	// public static function getContentLineConvertor(content:DocumentContent):IntUnaryOperator {
	// 	return content.getUserData(DiffUserDataKeysEx.LINE_NUMBER_CONVERTOR);
	// }
	// public static function mergeLineConverters(convertor1:Null<IntUnaryOperator>, convertor2:Null<IntUnaryOperator>):IntUnaryOperator {
	// 	if (convertor1 == null && convertor2 == null)
	// 		return null;
	// 	if (convertor1 == null)
	// 		return convertor2;
	// 	if (convertor2 == null)
	// 		return convertor1;
	// 	return value -> {
	// 		var value2:Int = convertor2.applyAsInt(value);
	// 		return value2 >= 0 ? convertor1.applyAsInt(value2) : value2;
	// 	};
	// }
	//
	// Scrolling
	//
	// public static function disableBlitting(editor:EditorEx):Void {
	// 	if (Registry.is("diff.divider.repainting.disable.blitting")) {
	// 		editor.getScrollPane().getViewport().setScrollMode(JViewport.SIMPLE_SCROLL_MODE);
	// 	}
	// }
	// public static function moveCaret(editor:Null<Editor>, line:Int):Void {
	// 	if (editor == null) {
	// 		return;
	// 	}
	// 	editor.getSelectionModel().removeSelection();
	// 	editor.getCaretModel().removeSecondaryCarets();
	// 	editor.getCaretModel().moveToLogicalPosition(new LogicalPosition(line, 0));
	// }
	// public static function scrollEditor(editor:Null<Editor>, line:Int, animated:Bool):Void {
	// 	scrollEditor(editor, line, 0, animated);
	// }
	// public static function scrollEditor(editor:Null<Editor>, line:Int, column:Int, animated:Bool):Void {
	// 	if (editor == null)
	// 		return;
	// 	editor.getSelectionModel().removeSelection();
	// 	editor.getCaretModel().removeSecondaryCarets();
	// 	editor.getCaretModel().moveToLogicalPosition(new LogicalPosition(line, column));
	// 	scrollToCaret(editor, animated);
	// }
	// public static function scrollToPoint(editor:Null<Editor>, point:Point, animated:Bool):Void {
	// 	if (editor == null)
	// 		return;
	// 	if (!animated)
	// 		editor.getScrollingModel().disableAnimation();
	// 	editor.getScrollingModel().scrollHorizontally(point.x);
	// 	editor.getScrollingModel().scrollVertically(point.y);
	// 	if (!animated)
	// 		editor.getScrollingModel().enableAnimation();
	// }
	// public static function scrollToCaret(editor:Null<Editor>, animated:Bool):Void {
	// 	if (editor == null)
	// 		return;
	// 	if (!animated)
	// 		editor.getScrollingModel().disableAnimation();
	// 	editor.getScrollingModel().scrollToCaret(ScrollType.CENTER);
	// 	if (!animated)
	// 		editor.getScrollingModel().enableAnimation();
	// }
	// public static function getScrollingPosition(editor:Null<Editor>):Point {
	// 	if (editor == null)
	// 		return new Point(0, 0);
	// 	var model:ScrollingModel = editor.getScrollingModel();
	// 	return new Point(model.getHorizontalScrollOffset(), model.getVerticalScrollOffset());
	// }
	// public static function getCaretPosition(editor:Null<Editor>):LogicalPosition {
	// 	return editor != null ? editor.getCaretModel().getLogicalPosition() : new LogicalPosition(0, 0);
	// }
	// public static function moveCaretToLineRangeIfNeeded(editor:Editor, startLine:Int, endLine:Int):Void {
	// 	var caretLine:Int = editor.getCaretModel().getLogicalPosition().line;
	// 	if (!isSelectedByLine(caretLine, startLine, endLine)) {
	// 		editor.getSelectionModel().removeSelection();
	// 		editor.getCaretModel().moveToLogicalPosition(new LogicalPosition(startLine, 0));
	// 	}
	// }
	//
	// Icons
	//
	// public static function getArrowIcon(sourceSide:Side):Icon {
	// 	return sourceSide.select(AllIcons.Diff.ArrowRight, AllIcons.Diff.Arrow);
	// }
	// public static function getArrowDownIcon(sourceSide:Side):Icon {
	// 	return sourceSide.select(AllIcons.Diff.ArrowRightDown, AllIcons.Diff.ArrowLeftDown);
	// }
	//
	// UI
	//
	// public static function isFromShortcut(e:AnActionEvent):Bool {
	// 	var place:String = e.getPlace();
	// 	return ActionPlaces.KEYBOARD_SHORTCUT.equals(place) || ActionPlaces.MOUSE_SHORTCUT.equals(place);
	// }
	// public static function registerAction(action:AnAction, component:JComponent):Void {
	// 	action.registerCustomShortcutSet(action.getShortcutSet(), component);
	// }
	// public static function recursiveRegisterShortcutSet(group:ActionGroup, component:JComponent, parentDisposable:Null<Disposable>):Void {
	// 	for (action in group.getChildren(null)) {
	// 		if (Std.isOfType(action, ActionGroup)) {
	// 			recursiveRegisterShortcutSet(Std.downcast(action, ActionGroup), component, parentDisposable);
	// 		}
	// 		action.registerCustomShortcutSet(component, parentDisposable);
	// 	}
	// }
	//     public static function createMessagePanel(
	//         message: String
	// ) :JPanel {
	//       var text: String  = StringUtil.replace(
	// message, "\n", UIUtil.BR
	// );
	//       var label: JLabel  = new JBLabel(
	// text
	// ) {
	//         @Override
	//           public Dimension getMinimumSize() {
	//             Dimension size = super.getMinimumSize();
	//             size.width = Math.min(
	// size.width, 200
	// );
	//             size.height = Math.min(
	// size.height, 100
	// );
	//             return size;
	//           }
	//       }.setCopyable(
	// true
	// );
	//
	//       return createMessagePanel(
	// label
	// );
	//     }
	//     public static function JPanel createMessagePanel(
	// JComponent label
	// ) {
	//       Color commentFg = JBColor.lazy(() -> {
	//         EditorColorsScheme scheme = EditorColorsManager.getInstance().getGlobalScheme();
	//         TextAttributes commentAttributes = scheme.getAttributes(
	// DefaultLanguageHighlighterColors.LINE_COMMENT
	// );
	//         Color commentAttributesForegroundColor = commentAttributes.getForegroundColor();
	//         if (
	// commentAttributesForegroundColor != null && commentAttributes.getBackgroundColor() == null
	// ) {
	//           return commentAttributesForegroundColor;
	//         }
	//         return scheme.getDefaultForeground();
	//       });
	//       label.setForeground(
	// commentFg
	// );
	//
	//       JPanel panel = new JPanel(
	// new SingleComponentCenteringLayout());
	//       panel.setBorder(
	// JBUI.Borders.empty(5
	// ));
	//       panel.setBackground(
	// JBColor.lazy(() -> EditorColorsManager.getInstance().getGlobalScheme().getDefaultBackground()));
	//       panel.add(
	// label
	// );
	//       return panel;
	//     }
	// public static function addActionBlock(group:DefaultActionGroup, ...actions:AnAction):Void {
	// 	addActionBlock(group, Arrays.asList(actions));
	// }
	// public static function addActionBlock(group:DefaultActionGroup, actions:Null<Array<AnAction>>):Void {
	// 	addActionBlock(group, actions, true);
	// }
	// public static function addActionBlock(group:DefaultActionGroup, actions:Null<Array<AnAction>>, prependSeparator:Bool):Void {
	// 	if (actions == null || actions.isEmpty())
	// 		return;
	//
	// 	if (prependSeparator) {
	// 		group.addSeparator();
	// 	}
	//
	// 	var children:Array<AnAction> = group.getChildren(ActionManager.getInstance());
	// 	for (action in actions) {
	// 		if (Std.isOfType(action, Separator) || !ArrayUtil.contains(action, children)) {
	// 			group.add(action);
	// 		}
	// 	}
	// }
	// public static function getSettingsConfigurablePath():String {
	// 	return SystemInfo.isMac ? DiffBundle.message("label.diff.settings.path.macos") : DiffBundle.message("label.diff.settings.path");
	// }
	// public static function createTooltipText(text:String, appendix:String):String {
	// 	var result:HtmlBuilder = new HtmlBuilder();
	// 	result.append(text);
	// 	if (appendix != null) {
	// 		result.br();
	// 		result.append(HtmlChunk.div("margin-top:5px; font-size:small").addText(appendix));
	// 	}
	// 	return result.wrapWithHtmlBody().toString();
	// }
	// public static function createNotificationText(text:String, appendix:String):String {
	// 	var result:HtmlBuilder = new HtmlBuilder();
	// 	result.append(text);
	// 	if (appendix != null) {
	// 		result.br();
	// 		result.append(HtmlChunk.span("color:#" + ColorUtil.toHex(JBColor.gray) + "; font-size:small").addText(appendix));
	// 	}
	// 	return result.wrapWithHtmlBody().toString();
	// }
	//
	// Titles
	//
	// public static function createSimpleTitles(viewer:Null<DiffViewer>, request:ContentDiffRequest):Array<JComponent> {
	// 	var contents:Array<DiffContent> = request.getContents();
	// 	var titles:Array<String> = request.getContentTitles();
	//
	// 	var components:Array<JComponent> = [];
	// 	var diffTitleCustomizers:Array<DiffEditorTitleCustomizer> = request.getUserData(DiffUserDataKeysEx.EDITORS_TITLE_CUSTOMIZER);
	// 	var needCreateTitle:Bool = !isUserDataFlagSet(DiffUserDataKeysEx.EDITORS_HIDE_TITLE, request);
	// 	for (i in 0...contents.size()) {
	// 		var customizer:DiffEditorTitleCustomizer = diffTitleCustomizers != null ? diffTitleCustomizers.get(i) : null;
	// 		var title:JComponent = needCreateTitle ? createTitle(titles.get(i), customizer) : null;
	// 		title = createTitleWithNotifications(viewer, title, contents.get(i));
	// 		components.append(title);
	// 	}
	//
	// 	return components;
	// }
	// public static function createTextTitles(viewer:Null<DiffViewer>, request:ContentDiffRequest, editors:Array<Editor>):Array<JComponent> {
	// 	var contents:Array<DiffContent> = request.getContents();
	// 	var titles:Array<String> = request.getContentTitles();
	//
	// 	var equalCharsets:Bool = TextDiffViewerUtil.areEqualCharsets(contents);
	// 	var equalSeparators:Bool = TextDiffViewerUtil.areEqualLineSeparators(contents);
	//
	// 	var result:Array<JComponent> = [];
	//
	// 	var diffTitleCustomizers:Array<DiffEditorTitleCustomizer> = request.getUserData(DiffUserDataKeysEx.EDITORS_TITLE_CUSTOMIZER);
	// 	var needCreateTitle:Bool = !isUserDataFlagSet(DiffUserDataKeysEx.EDITORS_HIDE_TITLE, request);
	// 	for (i in 0...contents.size()) {
	// 		var title:JComponent = needCreateTitle ? createTitle(titles.get(i), contents.get(i), equalCharsets, equalSeparators, editors.get(i),
	// 			diffTitleCustomizers != null ? diffTitleCustomizers.get(i) : null) : null;
	// 		title = createTitleWithNotifications(viewer, title, contents.get(i));
	// 		result.add(title);
	// 	}
	//
	// 	return result;
	// }
	// public static function createPatchTextTitles(viewer:Null<DiffViewer>, request:DiffRequest, titles:Array<Null<String>>):Array<JComponent> {
	// 	var result:Array<JComponent> = [];
	//
	// 	var diffTitleCustomizers:Array<DiffEditorTitleCustomizer> = request.getUserData(DiffUserDataKeysEx.EDITORS_TITLE_CUSTOMIZER);
	// 	var needCreateTitle:Bool = !isUserDataFlagSet(DiffUserDataKeysEx.EDITORS_HIDE_TITLE, request);
	// 	for (i in 0...titles.size()) {
	// 		var title:JComponent = null;
	// 		if (needCreateTitle) {
	// 			var titleText:String = titles[i];
	// 			var customizer:DiffEditorTitleCustomizer = diffTitleCustomizers != null ? diffTitleCustomizers.get(i) : null;
	// 			// noinspection RedundantCast
	// 			title = createTitle(titleText, null /* yes, actually null */, null /* here too */, null /* yep */, true, customizer);
	// 		}
	//
	// 		title = createTitleWithNotifications(viewer, title, null);
	// 		result.add(title);
	// 	}
	//
	// 	return result;
	// }
	// private static function createTitleWithNotifications(viewer:Null<DiffViewer>, title:Null<JComponent>, content:Null<DiffContent>):JComponent {
	// 	var components:Array<JComponent> = [];
	// 	if (title != null)
	// 		components.add(title);
	//
	// 	if (content != null) {
	// 		components.addAll(createCustomNotifications(viewer, content));
	// 	}
	//
	// 	if (Std.isOfType(content, DocumentContent)) {
	// 		var documentContent = cast(content, DocumentContent);
	// 		var document:Document = documentContent.getDocument();
	// 		if (FileDocumentManager.getInstance().isPartialPreviewOfALargeFile(document)) {
	// 			components.add(wrapEditorNotificationComponent(DiffNotifications.createNotification(DiffBundle.message("error.file.is.too.large.only.preview.is.loaded"))));
	// 		}
	// 	}
	//
	// 	if (Std.isOfType(content, FileContent)) {
	// 		var fileCotent = cast(content, FileContent);
	// 		var file:VirtualFile = fileContent.getFile();
	// 		if (file.isInLocalFileSystem() && !file.isValid()) {
	// 			components.add(wrapEditorNotificationComponent(DiffNotifications.createNotification(DiffBundle.message("error.file.is.not.valid"))));
	// 		}
	// 	}
	//
	// 	if (components.isEmpty())
	// 		return null;
	// 	return createStackedComponents(components, TITLE_GAP);
	// }
	// private static function createTitle(title:Null<String>, content:DiffContent, equalCharsets:Bool, equalSeparators:Bool, editor:Null<Editor>,
	// 		titleCustomizer:Null<DiffEditorTitleCustomizer>):JComponent {
	// 	if (Std.isOfType(content, EmptyContent))
	// 		return null;
	// 	var documentContent:DocumentContent = Std.downcast(content, DocumentContent);
	//
	// 	var charset:Charset = equalCharsets ? null : documentContent.getCharset();
	// 	var bom:Bool = equalCharsets ? null : documentContent.hasBom();
	// 	var separator:LineSeparator = equalSeparators ? null : documentContent.getLineSeparator();
	// 	var isReadOnly:Bool = editor == null || editor.isViewer() || !canMakeWritable(editor.getDocument());
	//
	// 	return createTitle(title, separator, charset, bom, isReadOnly, titleCustomizer);
	// }
	// public static function createTitle(title:Null<String>):JComponent {
	// 	return createTitle(title, null, null, null, false, null);
	// }
	// public static function createTitle(title:Null<String>, titleCustomizer:Null<DiffEditorTitleCustomizer>):JComponent {
	// 	return createTitle(title, null, null, null, false, titleCustomizer);
	// }
	// public static function createTitle(title:Null<String>, separator:Null<LineSeparator>, charset:Null<Charset>, bom:Null<Bool>, readOnly:Bool,
	// 		titleCustomizer:Null<DiffEditorTitleCustomizer>):JComponent {
	// 	var panel:JPanel = new JPanel(new BorderLayout());
	// 	panel.setBorder(JBUI.Borders.empty(0, 4));
	// 	var labelWithIcon:BorderLayoutPanel = new BorderLayoutPanel();
	// 	var titleLabel:JComponent = titleCustomizer != null ? titleCustomizer.getLabel() : new JBLabel(StringUtil.notNullize(title)).setCopyable(true);
	// 	labelWithIcon.addToCenter(titleLabel);
	// 	if (readOnly) {
	// 		labelWithIcon.addToLeft(new JBLabel(AllIcons.Ide.Readonly));
	// 	}
	// 	panel.add(labelWithIcon, BorderLayout.CENTER);
	// 	if (charset != null || separator != null) {
	// 		var panel2:JPanel = new JPanel();
	// 		panel2.setLayout(new BoxLayout(panel2, BoxLayout.X_AXIS));
	// 		if (charset != null) {
	// 			panel2.add(Box.createRigidArea(JBUI.size(4, 0)));
	// 			panel2.add(createCharsetPanel(charset, bom));
	// 		}
	// 		if (separator != null) {
	// 			panel2.add(Box.createRigidArea(JBUI.size(4, 0)));
	// 			panel2.add(createSeparatorPanel(separator));
	// 		}
	// 		panel.add(panel2, BorderLayout.EAST);
	// 	}
	// 	return panel;
	// }
	// private static function createCharsetPanel(charset:Charset, bom:Null<Bool>):JComponent {
	// 	var text:String = charset.displayName();
	// 	if (bom != null && bom) {
	// 		text = DiffBundle.message("diff.utf.charset.name.bom.suffix", text);
	// 	}
	//
	// 	var label:JLabel = new JLabel(text);
	// 	// TODO: specific colors for other charsets
	// 	if (charset.equals(StandardCharsets.UTF_8)) {
	// 		label.setForeground(JBColor.BLUE);
	// 	} else if (charset.equals(StandardCharsets.ISO_8859_1)) {
	// 		label.setForeground(JBColor.RED);
	// 	} else {
	// 		label.setForeground(JBColor.BLACK);
	// 	}
	// 	return label;
	// }
	// private static function createSeparatorPanel(separator:LineSeparator):JComponent {
	// 	var label:JLabel = new JLabel(separator.toString());
	// 	var color:Color;
	// 	if (separator == LineSeparator.CRLF) {
	// 		color = JBColor.RED;
	// 	} else if (separator == LineSeparator.LF) {
	// 		color = JBColor.BLUE;
	// 	} else if (separator == LineSeparator.CR) {
	// 		color = JBColor.MAGENTA;
	// 	} else {
	// 		color = JBColor.BLACK;
	// 	}
	// 	label.setForeground(color);
	// 	return label;
	// }
	// public static function createSyncHeightComponents(components:ReadonlyArray<JComponent>):Array<JComponent> {
	// 	return SyncHeightComponent.createSyncHeightComponents(components);
	// }
	// public static function createStackedComponents(components:Array<JComponent>, vGap:JBValue):JComponent {
	// 	var panel:JPanel = new JBPanel(new VerticalLayout(vGap, VerticalLayout.FILL));
	// 	for (component in components) {
	// 		panel.add(component);
	// 	}
	// 	return panel;
	// }
	// public static function getStatusText(totalCount:Int, excludedCount:Int, isContentsEqual:ThreeState):String {
	// 	if (totalCount == 0 && isContentsEqual == ThreeState.NO) {
	// 		return DiffBundle.message("diff.all.differences.ignored.text");
	// 	}
	// 	var message:String = DiffBundle.message("diff.count.differences.status.text", totalCount - excludedCount);
	// 	if (excludedCount > 0) {
	// 		message += " " + DiffBundle.message("diff.inactive.count.differences.status.text", excludedCount);
	// 	}
	// 	return message;
	// }
	//
	// Focus
	//
	// public static function isFocusedComponent(component:Null<Component>):Bool {
	// 	return isFocusedComponent(null, component);
	// }
	// public static function isFocusedComponent(project:Null<Project>, component:Null<Component>):Bool {
	// 	if (component == null)
	// 		return false;
	// 	var ideFocusOwner:Component = IdeFocusManager.getInstance(project).getFocusOwner();
	// 	if (ideFocusOwner != null && SwingUtilities.isDescendingFrom(ideFocusOwner, component))
	// 		return true;
	//
	// 	var jdkFocusOwner:Component = KeyboardFocusManager.getCurrentKeyboardFocusManager().getFocusOwner();
	// 	if (jdkFocusOwner != null && SwingUtilities.isDescendingFrom(jdkFocusOwner, component))
	// 		return true;
	//
	// 	return false;
	// }
	// public static function requestFocus(project:Null<Project>, component:Null<Component>):Void {
	// 	if (component == null) {
	// 		return;
	// 	}
	//
	// 	IdeFocusManager.getInstance(project).requestFocus(component, true);
	// }
	// public static function isFocusedComponentInWindow(component:Null<Component>):Bool {
	// 	if (component == null) {
	// 		return false;
	// 	}
	// 	var window:Window = ComponentUtil.getWindow(component);
	// 	if (window == null) {
	// 		return false;
	// 	}
	// 	var windowFocusOwner:Component = window.getMostRecentFocusOwner();
	// 	return windowFocusOwner != null && SwingUtilities.isDescendingFrom(windowFocusOwner, component);
	// }
	// public static function requestFocusInWindow(component:Null<Component>):Void {
	// 	if (component != null) {
	// 		component.requestFocusInWindow();
	// 	}
	// }
	// public static function runPreservingFocus(context:FocusableContext, task:Runnable):Void {
	// 	var hadFocus:Bool = context.isFocusedInWindow();
	// 	if (hadFocus)
	// 		KeyboardFocusManager.getCurrentKeyboardFocusManager().clearFocusOwner();
	// 	task.run();
	// 	if (hadFocus)
	// 		context.requestFocusInWindow();
	// }
	//
	// Compare
	//
	// public static function createTextDiffProvider(project:Null</*Project*/Dynamic>, request:ContentDiffRequest, settings:TextDiffSettings, rediff:Runnable,
	// 		disposable:Disposable):TwosideTextDiffProvider {
	// 	var diffComputer:DiffUserDataKeysEx.DiffComputer = request.getUserData(DiffUserDataKeysEx.CUSTOM_DIFF_COMPUTER);
	// 	if (diffComputer != null)
	// 		return new SimpleTextDiffProvider(settings, rediff, disposable, diffComputer);
	//
	// 	var smartProvider:TwosideTextDiffProvider = SmartTextDiffProvider.create(project, request, settings, rediff, disposable);
	// 	if (smartProvider != null)
	// 		return smartProvider;
	//
	// 	return new SimpleTextDiffProvider(settings, rediff, disposable);
	// }
	// public static function createNoIgnoreTextDiffProvider(project:Null<Project>, request:ContentDiffRequest, settings:TextDiffSettings, rediff:Runnable,
	// 		disposable:Disposable):TwosideTextDiffProvider.NoIgnore {
	// 	var diffComputer:DiffUserDataKeysEx.DiffComputer = request.getUserData(DiffUserDataKeysEx.CUSTOM_DIFF_COMPUTER);
	// 	if (diffComputer != null)
	// 		return new SimpleTextDiffProvider.NoIgnore(settings, rediff, disposable, diffComputer);
	//
	// 	var smartProvider:TwosideTextDiffProvider.NoIgnore = SmartTextDiffProvider.createNoIgnore(project, request, settings, rediff, disposable);
	// 	if (smartProvider != null)
	// 		return smartProvider;
	//
	// 	return new SimpleTextDiffProvider.NoIgnore(settings, rediff, disposable);
	// }
	//   public static function  getDocumentContentsForViewer(
	//       project: Null<Project> ,
	//        byteContents: Array<byte[]> ,
	//        filePath: FilePath ,
	//       conflictType: Null<ConflictType>
	// ): Array<DocumentContent> {
	//     return getDocumentContentsForViewer(
	// project, byteContents, conflictType, new DiffContentFactoryEx.ContextProvider() {
	//       @Override
	//         public Void passContext(
	// DiffContentFactoryEx.DocumentContentBuilder builder
	// ) {
	//           builder.contextByFilePath(
	// filePath
	// );
	//         }
	//     });
	//   }
	//
	//   public static function  getDocumentContentsForViewer(
	//       project: Null<Project> ,
	//        byteContents: Array<byte[]> ,
	//        file: VirtualFile ,
	//       conflictType: Null<ConflictType>
	// ): Array<DocumentContent> {
	//     return getDocumentContentsForViewer(
	// project, byteContents, conflictType, new DiffContentFactoryEx.ContextProvider() {
	//       @Override
	//         public Void passContext(
	// DiffContentFactoryEx.DocumentContentBuilder builder
	// ) {
	//           builder.contextByHighlightFile(
	// file
	// );
	//         }
	//     });
	//   }
	// private static function getDocumentContentsForViewer(project:Null<Project>, byteContents:Array<Array<Bytes>>, conflictType:Null<ConflictType>,
	// 		contextProvider:DiffContentFactoryEx.ContextProvider):Array<DocumentContent> {
	// 	var contentFactory:DiffContentFactoryEx = DiffContentFactoryEx.getInstanceEx();
	//
	// 	var current:DocumentContent = contentFactory.documentContent(project, true)
	// 		.contextByProvider(contextProvider)
	// 		.buildFromBytes(notNull(byteContents.get(0), EMPTY_BYTE_ARRAY));
	// 	var last:DocumentContent = contentFactory.documentContent(project, true)
	// 		.contextByProvider(contextProvider)
	// 		.buildFromBytes(notNull(byteContents.get(2), EMPTY_BYTE_ARRAY));
	//
	// 	var original:DocumentContent;
	// 	if (conflictType == ConflictType.ADDED_ADDED) {
	// 		var indicator:ProgressIndicator = EmptyProgressIndicator.notNullize(ProgressManager.getInstance().getProgressIndicator());
	//
	// 		var currentContent:String = getDocumentString(current);
	// 		var lastContent:String = getDocumentString(last);
	// 		var newContent:String = ComparisonManager.getInstance()
	// 			.mergeLinesAdditions(currentContent, lastContent, ComparisonPolicy.IGNORE_WHITESPACES, indicator);
	// 		original = contentFactory.documentContent(project, true).contextByProvider(contextProvider).buildFromText(newContent, false);
	// 	} else {
	// 		original = contentFactory.documentContent(project, true)
	// 			.contextByProvider(contextProvider)
	// 			.buildFromBytes(notNull(byteContents.get(1), EMPTY_BYTE_ARRAY));
	// 	}
	// 	return Arrays.asList(current, original, last);
	// }
	public static function compareThreesideInner(chunks:Array<String>, comparisonPolicy:ComparisonPolicy):MergeInnerDifferences {
		if (chunks[0] == null && chunks[1] == null && chunks[2] == null)
			return null; // ---

		if (comparisonPolicy == ComparisonPolicy.IGNORE_WHITESPACES) {
			if (isChunksEquals(chunks[0], chunks[1], comparisonPolicy) && isChunksEquals(chunks[0], chunks[2], comparisonPolicy)) {
				// whitespace-only changes, ex: empty lines added/removed
				return new MergeInnerDifferences([], [], []);
			}
		}

		if (chunks[0] == null && chunks[1] == null || chunks[0] == null && chunks[2] == null || chunks[1] == null && chunks[2] == null) { // =--, -=-, --=
			return null;
		}

		if (chunks[0] != null && chunks[1] != null && chunks[2] != null) { // ===
			var fragments1:Array<DiffFragment> = ByWordRt.compareA(chunks[1], chunks[0], comparisonPolicy);
			var fragments2:Array<DiffFragment> = ByWordRt.compareA(chunks[1], chunks[2], comparisonPolicy);

			var left:Array<TextRange> = [];
			var base:Array<TextRange> = [];
			var right:Array<TextRange> = [];

			for (wordFragment in fragments1) {
				base.push(new TextRange(wordFragment.getStartOffset1(), wordFragment.getEndOffset1()));
				left.push(new TextRange(wordFragment.getStartOffset2(), wordFragment.getEndOffset2()));
			}

			for (wordFragment in fragments2) {
				base.push(new TextRange(wordFragment.getStartOffset1(), wordFragment.getEndOffset1()));
				right.push(new TextRange(wordFragment.getStartOffset2(), wordFragment.getEndOffset2()));
			}

			return new MergeInnerDifferences(left, base, right);
		}

		// ==-, =-=, -==
		final side1:ThreeSide = ThreeSide.fromEnum(chunks[0] != null ? ThreeSideEnum.LEFT : ThreeSideEnum.BASE);
		final side2:ThreeSide = ThreeSide.fromEnum(chunks[2] != null ? ThreeSideEnum.RIGHT : ThreeSideEnum.BASE);
		var chunk1:String = side1.selectC(chunks);
		var chunk2:String = side2.selectC(chunks);

		var wordConflicts:Array<DiffFragment> = ByWordRt.compareA(chunk1, chunk2, comparisonPolicy);

		var textRanges:Array<Array<TextRange>> = ThreeSide.map(function(side):Array<TextRange> {
			if (side == side1) {
				return wordConflicts.map(function(fragment) {
					return new TextRange(fragment.getStartOffset1(), fragment.getEndOffset1());
				});
			}
			if (side == side2) {
				return wordConflicts.map(function(fragment) {
					return new TextRange(fragment.getStartOffset2(), fragment.getEndOffset2());
				});
			}
			return [];
		});

		return new MergeInnerDifferences(textRanges[0], textRanges[1], textRanges[2]);
	}

	private static function isChunksEquals(chunk1:Null<String>, chunk2:Null<String>, comparisonPolicy:ComparisonPolicy):Bool {
		if (chunk1 == null)
			chunk1 = "";
		if (chunk2 == null)
			chunk2 = "";
		return ComparisonUtil.isEqualTexts(chunk1, chunk2, comparisonPolicy);
	}

	// @:generic
	// public static function getSortedIndexes<T>(values:Array<T>, comparator:Comparator<T>):Array<Int> {
	// 	final indexes:Array<Integer> = [];
	// 	for (i in 0...values.size()) {
	// 		indexes.add(i);
	// 	}
	//
	// 	ContainerUtil.sort(indexes, function(i1, i2) {
	// 		var val1:T = values.get(i1);
	// 		var val2:T = values.get(i2);
	// 		return comparator.compare(val1, val2);
	// 	});
	//
	// 	return ArrayUtil.toIntArray(indexes);
	// }
	// public static function invertIndexes(indexes:Array<Int>):Array<Int> {
	// 	var inverted:Array<Int> = [for (_ in 0...indexes.length) 0];
	// 	for (i in 0...indexes.length) {
	// 		inverted[indexes[i]] = i;
	// 	}
	// 	return inverted;
	// }
	// public static function compareStreams(stream:ThrowableComputable<InputStream, IOException>, stream2:ThrowableComputable<InputStream, IOException>):Bool {
	// 	var i:Int = 0;
	//
	// 	try {
	// 		var s1:InputStream = stream1.compute();
	//
	// 		try {
	// 			var s2:InputStream = stream2.compute();
	// 			if (s1 == null && s2 == null)
	// 				return true;
	// 			if (s1 == null || s2 == null)
	// 				return false;
	//
	// 			while (true) {
	// 				var b1:Int = s1.read();
	// 				var b2:Int = s2.read();
	// 				if (b1 != b2)
	// 					return false;
	// 				if (b1 == -1)
	// 					return true;
	//
	// 				if (i++ % 10000 == 0)
	// 					ProgressManager.checkCanceled();
	// 			}
	// 		}
	// 	}
	// }
	// public static function getFileInputStream(file:VirtualFile):InputStream {
	// 	var fs:VirtualFileSystem = file.getFileSystem();
	// 	if (Std.isOfType(fs, FileSystemInterface)) {
	// 		return Std.downcast(fs, FileSystemInterface).getInputStream(file);
	// 	}
	// 	// can't use VirtualFile.getInputStream here, as it will strip BOM
	// 	var content:Array<Bytes> = ReadAction.compute(() -> file.contentsToByteArray());
	// 	return new ByteArrayInputStream(content);
	// }
	//
	// Document modification
	//
	// public static function isSomeRangeSelected(editor:Editor, condition:Condition<BitSet>):Bool {
	// 	var carets:Array<Caret> = editor.getCaretModel().getAllCarets();
	// 	if (carets.size() != 1)
	// 		return true;
	// 	var caret:Caret = carets.get(0);
	// 	if (caret.hasSelection())
	// 		return true;
	//
	// 	return condition.value(getSelectedLines(editor));
	// }
	// public static function getSelectedLines(editor:Editor):BitSet {
	// 	var document:Document = editor.getDocument();
	// 	var totalLines:Int = getLineCount(document);
	// 	var lines:BitSet = new BitSet(totalLines + 1);
	//
	// 	for (caret in editor.getCaretModel().getAllCarets()) {
	// 		appendSelectedLines(editor, lines, caret);
	// 	}
	//
	// 	return lines;
	// }
	// private static function appendSelectedLines(editor:Editor, lines:BitSet, caret:Caret):Void {
	// 	var document:Document = editor.getDocument();
	// 	var totalLines:Int = getLineCount(document);
	//
	// 	if (caret.hasSelection()) {
	// 		var line1:Int = editor.offsetToLogicalPosition(caret.getSelectionStart()).line;
	// 		var line2:Int = editor.offsetToLogicalPosition(caret.getSelectionEnd()).line;
	// 		lines.set(line1, line2 + 1);
	// 		if (caret.getSelectionEnd() == document.getTextLength())
	// 			lines.set(totalLines);
	// 	} else {
	// 		var offset:Int = caret.getOffset();
	// 		var visualPosition:VisualPosition = caret.getVisualPosition();
	//
	// 		var pair:Pair<LogicalPosition, LogicalPosition> = EditorUtil.calcSurroundingRange(editor, visualPosition, visualPosition);
	// 		lines.set(pair.first.line, Math.max(pair.second.line, pair.first.line + 1));
	// 		if (offset == document.getTextLength())
	// 			lines.set(totalLines);
	// 	}
	// }
	// public static function isSelectedByLine(line:Int, line1:Int, line2:Int):Bool {
	// 	if (line1 == line2 && line == line1) {
	// 		return true;
	// 	}
	// 	if (line >= line1 && line < line2) {
	// 		return true;
	// 	}
	// 	return false;
	// }
	// public static function isSelectedByLine(selected:BitSet, line1:Int, line2:Int):Bool {
	// 	if (line1 == line2) {
	// 		return selected.get(line1);
	// 	} else {
	// 		var next:Int = selected.nextSetBit(line1);
	// 		return next != -1 && next < line2;
	// 	}
	// }

	private static function deleteLines(document:String, line1:Int, line2:Int):String {
		var range:TextRange = getLinesRangeA(document, line1, line2);
		var offset1:Int = range.getStartOffset();
		var offset2:Int = range.getEndOffset();

		if (offset1 > 0) {
			offset1--;
		} else if (offset2 < document.length) {
			offset2++;
		}

		var beforeRange = document.substring(0, offset1);
		var afterRange = document.substring(offset2, document.length);

		return beforeRange + afterRange;
	}

	private static function insertLines(document:String, line:Int, text:String):String {
		var lines = document.split("\n");

		if (line < 0)
			line = 0;
		if (line > lines.length)
			line = lines.length;

		lines.insert(line, text);

		// Join the lines back into a single string
		return lines.join("\n");

		// if (line == getLineCount(document)) {
		// 	document.insertString(document.length, "\n" + text);
		// } else {
		// 	document.insertString(document.getLineStartOffset(line), text + "\n");
		// }
	}

	private static function replaceLines(document:String, line1:Int, line2:Int, text:String):String {
		var currentTextRange:TextRange = getLinesRangeA(document, line1, line2);
		var offset1:Int = currentTextRange.getStartOffset();
		var offset2:Int = currentTextRange.getEndOffset();

		// document.replaceString(offset1, offset2, text);
		if (offset1 < 0)
			offset1 = 0;
		if (offset2 > document.length)
			offset2 = document.length;

		var beforeRange = document.substring(0, offset1);
		var afterRange = document.substring(offset2, document.length);

		return beforeRange + text + afterRange;
	}

	public static function applyModificationA(document:String, line1:Int, line2:Int, newLines:Array<String>):String {
		if (line1 == line2 && newLines.length == 0)
			return document;

		if (line1 == line2) {
			insertLines(document, line1, newLines.join("\n"));
		} else if (newLines.length == 0) {
			deleteLines(document, line1, line2);
		} else {
			document = replaceLines(document, line1, line2, newLines.join("\n"));
		}

		return document;
	}

	public static function applyModificationB(document1:String, line1:Int, line2:Int, document2:String, oLine1:Int, oLine2:Int):Void {
		if (line1 == line2 && oLine1 == oLine2)
			return;
		if (line1 == line2) {
			insertLines(document1, line1, getLinesContentA(document2, oLine1, oLine2));
		} else if (oLine1 == oLine2) {
			deleteLines(document1, line1, line2);
		} else {
			replaceLines(document1, line1, line2, getLinesContentA(document2, oLine1, oLine2));
		}
	}

	public static function applyModificationC(text:String, lineOffsets:LineOffsets, otherText:String, otherLineOffsets:LineOffsets,
			ranges:Array<Range>):String {
		final stringBuilder:StringBuf = new StringBuf();
		var isEmpty:Bool = true;
		function append(content:String, lineCount:Int):Void {
			if (lineCount > 0 && !isEmpty) {
				stringBuilder.add('\n');
			}
			stringBuilder.add(content);
			isEmpty = isEmpty && lineCount == 0;
		}

		function appendOriginal(start:Int, end:Int):Void {
			append(DiffRangeUtil.getLinesContent(text, lineOffsets, start, end), end - start);
		}

		function execute():String {
			var lastLine:Int = 0;

			for (range in ranges) {
				var newChunkContent:String = DiffRangeUtil.getLinesContent(otherText, otherLineOffsets, range.start2, range.end2);

				appendOriginal(lastLine, range.start1);
				append(newChunkContent, range.end2 - range.start2);

				lastLine = range.end1;
			}

			appendOriginal(lastLine, lineOffsets.getLineCount());

			return stringBuilder.toString();
		}

		return execute();
	}

	// public static function clearLineModificationFlags(document:Document, startLine:Int, endLine:Int):Void {
	// 	if (document.getTextLength() == 0)
	// 		return; // empty document has no lines
	// 	if (startLine == endLine)
	// 		return;
	// 	Std.downcast(document, DocumentImpl).clearLineModificationFlags(startLine, endLine);
	// }
	public static function getLinesContentA(document:String, line1:Int, line2:Int):String {
		return getLinesRangeA(document, line1, line2).subSequence(document /*.getImmutableString()*/);
	}

	public static function getLinesContentB(document:String, line1:Int, line2:Int, includeNewLine:Bool):String {
		return getLinesRangeB(document, line1, line2, includeNewLine).subSequence(document /*.getImmutableString()*/);
	}

	/**
	 * Return affected range, without non-internal newlines
	 * <p/>
	 * we consider '\n' not as a part of line, but a separator between lines
	 * ex: if last line is not empty, the last symbol will not be '\n'
	 */
	public static function getLinesRangeA(document:String, line1:Int, line2:Int):TextRange {
		return getLinesRangeB(document, line1, line2, false);
	}

	public static function getLinesRangeB(document:String, line1:Int, line2:Int, includeNewline:Bool):TextRange {
		return DiffRangeUtil.getLinesRange(LineOffsetsUtil.createB(document), line1, line2, includeNewline);
	}

	// public static function getOffset(document:Document, line:Int, column:Int):Int {
	// 	if (line < 0)
	// 		return 0;
	// 	if (line >= getLineCount(document))
	// 		return document.getTextLength();
	//
	// 	var start:Int = document.getLineStartOffset(line);
	// 	var end:Int = document.getLineEndOffset(line);
	// 	return Math.min(start + column, end);
	// }

	/**
		* Document.getLineCount() returns 0 for empty text.
		* <p>
		* This breaks an assumption "getLineCount() == StringUtil.countNewLines(
		text
		) + 1"
		* and adds unnecessary corner case into line ranges logic.
	 */
	// public static function getLineCount(document:Document):Int {
	// 	return Math.max(document.getLineCount(), 1);
	// }
	public static function getLineCount(document:String):Int {
		return Std.int(Math.max(document.split("\n").length - 1, 1));
	}

	public static function getLinesA(document:String):Array<String> {
		return getLinesB(document, 0, getLineCount(document));
	}

	public static function getLinesB(document:String, startLine:Int, endLine:Int):Array<String> {
		return DiffRangeUtil.getLines(document /*.getCharsSequence()*/, LineOffsetsUtil.createB(document), startLine, endLine);
	}

	// public static function bound(value:Int, lowerBound:Int, upperBound:Int):Int {
	// 	// assert lowerBound <= upperBound :String.format ("%s - [%s, %s]", value, lowerBound, upperBound);
	// 	return MathUtil.clamp(value, lowerBound, upperBound);
	// }
	//
	// Updating ranges on change
	//
	// public static function getAffectedLineRange(e:DocumentEvent):LineRange {
	// 	var line1:Int = e.getDocument().getLineNumber(e.getOffset());
	// 	var line2:Int = e.getDocument().getLineNumber(e.getOffset() + e.getOldLength()) + 1;
	// 	return new LineRange(line1, line2);
	// }
	// public static function countLinesShift(e:DocumentEvent):Int {
	// 	return StringUtil.countNewLines(e.getNewFragment()) - StringUtil.countNewLines(e.getOldFragment());
	// }
	public static function updateRangeOnModificationA(start:Int, end:Int, changeStart:Int, changeEnd:Int, shift:Int):UpdatedLineRange {
		return updateRangeOnModificationB(start, end, changeStart, changeEnd, shift, false);
	}

	public static function updateRangeOnModificationB(start:Int, end:Int, changeStart:Int, changeEnd:Int, shift:Int, greedy:Bool):UpdatedLineRange {
		if (end <= changeStart) { // change before
			return new UpdatedLineRange(start, end, false);
		}
		if (start >= changeEnd) { // change after
			return new UpdatedLineRange(start + shift, end + shift, false);
		}

		if (start <= changeStart && end >= changeEnd) { // change inside
			return new UpdatedLineRange(start, end + shift, false);
		}

		// range is damaged. We don't know new boundaries.
		// But we can try to return approximate new position
		var newChangeEnd:Int = changeEnd + shift;

		if (start >= changeStart && end <= changeEnd) { // fully inside change
			return greedy ? new UpdatedLineRange(changeStart, newChangeEnd, true) : new UpdatedLineRange(newChangeEnd, newChangeEnd, true);
		}

		if (start < changeStart) { // bottom boundary damaged
			return greedy ? new UpdatedLineRange(start, newChangeEnd, true) : new UpdatedLineRange(start, changeStart, true);
		} else { // top boundary damaged
			return greedy ? new UpdatedLineRange(changeStart, end + shift, true) : new UpdatedLineRange(newChangeEnd, end + shift, true);
		}
	}

	//
	// Types
	//
	// public static function getLineDiffType(fragment:LineFragment):TextDiffType {
	// 	var left:Bool = fragment.getStartLine1() != fragment.getEndLine1();
	// 	var right:Bool = fragment.getStartLine2() != fragment.getEndLine2();
	// 	return getDiffType(left, right);
	// }
	public static function getDiffTypeA(fragment:DiffFragment):TextDiffType {
		var left:Bool = fragment.getEndOffset1() != fragment.getStartOffset1();
		var right:Bool = fragment.getEndOffset2() != fragment.getStartOffset2();
		return getDiffTypeC(left, right);
	}

	public static function getDiffTypeB(range:Range):TextDiffType {
		var left:Bool = range.start1 != range.end1;
		var right:Bool = range.start2 != range.end2;
		return getDiffTypeC(left, right);
	}

	public static function getDiffTypeC(hasDeleted:Bool, hasInserted:Bool):TextDiffType {
		if (hasDeleted && hasInserted) {
			return TextDiffType.MODIFIED;
		} else if (hasDeleted) {
			return TextDiffType.DELETED;
		} else if (hasInserted) {
			return TextDiffType.INSERTED;
		} else {
			// LOG.error("Diff fragment should not be empty");
			return TextDiffType.MODIFIED;
		}
	}

	public static function getDiffTypeD(conflictType:MergeConflictType):TextDiffType {
		return switch (conflictType.getType()) {
			case INSERTED: TextDiffType.INSERTED;
			case DELETED: TextDiffType.DELETED;
			case MODIFIED: TextDiffType.MODIFIED;
			case CONFLICT: TextDiffType.CONFLICT;
		};
	}

	//
	// Writable
	//
	// public static function executeWriteCommandA(/*project:Null<Project>, document:Document, commandName:Null<String>, commandGroupId:Null<String>,
	// 		confirmationPolicy:UndoConfirmationPolicy, underBulkUpdate:Bool,*/ task:Runnable):Bool {
	// 	return executeWriteCommandB(/*project, document, commandName, commandGroupId, confirmationPolicy, underBulkUpdate, true,*/ task);
	// }

	public static function executeWriteCommand(/*project:Null<Project>, document:Document, commandName:Null<String>, commandGroupId:Null<String>,
		confirmationPolicy:UndoConfirmationPolicy, underBulkUpdate:Bool, shouldRecordCommandForActiveDocument:Bool, */ task:Runnable):Bool {
		// if (!makeWritable(project, document)) {
		// 	var file:VirtualFile = FileDocumentManager.getInstance().getFile(document);
		// 	var warning:String = "Document is read-only";
		// 	if (file != null) {
		// 		warning += ": " + file.getPresentableName();
		// 		if (!file.isValid())
		// 			warning += " (invalid)";
		// 	}
		// 	LOG.warn(warning);
		// 	return false;
		// }

		// ApplicationManager.getApplication().runWriteAction(() -> CommandProcessor.getInstance().executeCommand(project, () -> {
		// 	if (underBulkUpdate) {
		// 		DocumentUtil.executeInBulk(document, task);
		// 	} else {
		task();
		// }
		// }, commandName, commandGroupId, confirmationPolicy,
		// shouldRecordCommandForActiveDocument, document));
		return true;
	}

	// public static function executeWriteCommandC(/*document:Document, project:Null<Project>, commandName:Null<String>, task:Runnable):Bool {
	// 	return executeWriteCommand(project, document, commandName, null, UndoConfirmationPolicy.DEFAULT, false, */task);
	// }
	// public static function isEditable(editor:Editor):Bool {
	// 	return !editor.isViewer() && canMakeWritable(editor.getDocument());
	// }
	// public static function canMakeWritable(document:Document):Bool {
	// 	var file:VirtualFile = FileDocumentManager.getInstance().getFile(document);
	//
	// 	if (file != null && file.isInLocalFileSystem() && !file.isValid()) {
	// 		// Deleted files have writable Document, but are not writable.
	// 		// See 'com.intellij.openapi.editor.impl.EditorImpl.processKeyTyped(char)'
	// 		return false;
	// 	}
	// 	if (document.isWritable()) {
	// 		return true;
	// 	}
	//
	// 	if (file != null && file.isValid() && file.isInLocalFileSystem()) {
	// 		if (file.getUserData(TEMP_FILE_KEY) == Bool.TRUE)
	// 			return false;
	// 		// decompiled file can be writable, but Document with decompiled content is still read-only
	// 		return !file.isWritable();
	// 	}
	// 	return false;
	// }
	// public static function makeWritable(project:Null<Project>, document:Document):Bool {
	// 	var file:VirtualFile = FileDocumentManager.getInstance().getFile(document);
	// 	if (file == null)
	// 		return document.isWritable();
	// 	if (!file.isValid())
	// 		return false;
	// 	return makeWritable(project, file) && document.isWritable();
	// }
	// public static function makeWritable(project:Null<Project>, file:VirtualFile):Bool {
	// 	if (project == null)
	// 		project = ProjectManager.getInstance().getDefaultProject();
	// 	return !ReadonlyStatusHandler.getInstance(project).ensureFilesWritable(Collections.singletonList(file)).hasReadonlyFiles();
	// }
	// public static function putNonundoableOperation(project:Null<Project>, document:Document):Void {
	// 	var undoManager:UndoManager = project != null ? UndoManager.getInstance(project) : UndoManager.getGlobalInstance();
	// 	if (undoManager != null) {
	// 		var ref:DocumentReference = DocumentReferenceManager.getInstance().create(document);
	// 		undoManager.nonundoableActionPerformed(ref, false);
	// 	}
	// }
	// public static function refreshOnFrameActivation(...files:VirtualFile):Void {
	// 	if (GeneralSettings.getInstance().isSyncOnFrameActivation()) {
	// 		markDirtyAndRefresh(true, false, false, files);
	// 	}
	// }
	/**
	 * Difference with {@link VfsUtil#markDirtyAndRefresh} is that refresh from VfsUtil will be performed with ModalityState.NON_MODAL.
	 */
	// public static function markDirtyAndRefresh(async:Bool, recursive:Bool, reloadChildren:Bool, ...files:VirtualFile):Void {
	// 	if (files.length == 0)
	// 		return;
	// 	var modalityState:ModalityState = ApplicationManager.getApplication().getDefaultModalityState();
	// 	VfsUtil.markDirty(recursive, reloadChildren, files);
	// 	RefreshQueue.getInstance().refresh(async, recursive, null, modalityState, files);
	// }
	//
	// Windows
	//
	// public static function getDefaultDiffPanelSize():Dimension {
	// 	return new Dimension(400, 200);
	// }
	// public static function getDefaultDiffWindowSize():Dimension {
	// 	var screenBounds:Rectangle = ScreenUtil.getMainScreenBounds();
	// 	var width:Int = (Int)(screenBounds.width * 0.8);
	// 	var height:Int = (Int)(screenBounds.height * 0.8);
	// 	return new Dimension(width, height);
	// }
	// public static function getWindowMode(hints:DiffDialogHints):WindowWrapper.Mode {
	// 	var mode:WindowWrapper.Mode = hints.getMode();
	// 	if (mode == null) {
	// 		var isUnderDialog:Bool = LaterInvocator.isInModalContext();
	// 		mode = isUnderDialog ? WindowWrapper.Mode.MODAL : WindowWrapper.Mode.FRAME;
	// 	}
	// 	return mode;
	// }
	// public static function closeWindow(window:Null<Window>, modalOnly:Bool, recursive:Bool):Void {
	// 	if (window == null)
	// 		return;
	//
	// 	var component:Component = window;
	// 	while (component != null) {
	// 		if (Std.isOfType(component, Window)) {
	// 			var isClosed:Bool = closeWindow(Std.downcast(component, Window), modalOnly);
	// 			if (!isClosed)
	// 				break;
	// 		}
	//
	// 		component = recursive ? component.getParent() : null;
	// 	}
	// }
	/**
	 * @return whether window was closed
	 */
	// private static function closeWindow(window:Window, modalOnly:Bool):Bool {
	// 	if (Std.isOfType(window, IdeFrameImpl) || (modalOnly && canBeHiddenBehind(window))) {
	// 		return false;
	// 	}
	//
	// 	if (Std.isOfType(window, DialogWrapperDialog)) {
	// 		(Std.downcast(window, DialogWrapperDialog)).getDialogWrapper().doCancelAction();
	// 		return !window.isVisible();
	// 	}
	//
	// 	window.setVisible(false);
	// 	window.dispose();
	// 	return true;
	// }
	/**
	 * MacOS hack. Try to minimize the window while we are navigating to sources from the window diff in full screen mode.
	 */
	// public static function minimizeDiffIfOpenedInWindow(diffComponent:Component):Void {
	// 	if (!SystemInfo.isMac)
	// 		return;
	// 	var holder:EditorWindowHolder = UIUtil.getParentOfType(EditorWindowHolder, diffComponent);
	// 	if (holder == null)
	// 		return;
	//
	// 	var composites:Array<EditorComposite> = holder.getEditorWindow().getAllComposites();
	// 	if (composites.size() == 1) {
	// 		if (DIFF_OPENED_IN_NEW_WINDOW.get(composites.get(0).getFile(), false)) {
	// 			var window:Window = UIUtil.getWindow(diffComponent);
	// 			if (window != null && !canBeHiddenBehind(window)) {
	// 				if (Std.isOfType(window, Frame)) {
	// 					Std.downcast(window, Frame).setState(Frame.ICONIFIED);
	// 				}
	// 			}
	// 		}
	// 	}
	// }
	// private static function canBeHiddenBehind(window:Window):Bool {
	// 	if (!(Std.isOfType(window, Frame)))
	// 		return false;
	// 	if (SystemInfo.isMac) {
	// 		if (Std.isOfType(window, IdeFrame)) {
	// 			// we can't move focus to full-screen main frame, as it will be hidden behind other frame windows
	// 			var project:Project = Std.downcast(window, IdeFrame).getProject();
	// 			var projectFrame:IdeFrame = WindowManager.getInstance().getIdeFrame(project);
	// 			if (projectFrame != null) {
	// 				var projectFrameComponent:JComponent = projectFrame.getComponent();
	// 				if (projectFrameComponent != null) {
	// 					return !projectFrame.isInFullScreen()
	// 						|| window.getGraphicsConfiguration().getDevice() != projectFrameComponent.getGraphicsConfiguration().getDevice();
	// 				}
	// 			}
	// 		}
	// 	}
	// 	return true;
	// }
	//
	// UserData
	//
	// @:generic
	// public static function createUserDataHolder<T>(key:Key<T>, value:Null<T>):UserDataHolderBase {
	// 	var holder:UserDataHolderBase = new UserDataHolderBase();
	// 	holder.putUserData(key, value);
	// 	return holder;
	// }
	// public static function isUserDataFlagSet(key:Key<Bool>, ...holders:UserDataHolder):Bool {
	// 	for (holder in holders) {
	// 		if (holder == null)
	// 			continue;
	// 		var data:Bool = holder.getUserData(key);
	// 		if (data != null)
	// 			return data;
	// 	}
	// 	return false;
	// }
	// @:generic
	// public static function getUserData<T>(first:Null<UserDataHolder>, second:Null<UserDataHolder>, key:Key<T>):T {
	// 	if (first != null) {
	// 		var data:T = first.getUserData(key);
	// 		if (data != null)
	// 			return data;
	// 	}
	// 	if (second != null) {
	// 		var data:T = second.getUserData(key);
	// 		if (data != null)
	// 			return data;
	// 	}
	// 	return null;
	// }
	// public static function addNotification(provider:Null<DiffNotificationProvider>, holder:UserDataHolder):Void {
	// 	if (provider == null)
	// 		return;
	// 	var newProviders:Array<DiffNotificationProvider> = [];
	// 	newProviders.push(provider);
	// 	holder.putUserData(DiffUserDataKeys.NOTIFICATION_PROVIDERS, newProviders);
	// }
	// public static function createCustomNotifications(viewer:Null<DiffViewer>, context:UserDataHolder, request:UserDataHolder):Array<JComponent> {
	// 	var contextProviders:Array<DiffNotificationProvider> = getNotificationProviders(context);
	// 	var requestProviders:Array<DiffNotificationProvider> = getNotificationProviders(request);
	// 	return createNotifications(viewer, ContainerUtil.concat(contextProviders, requestProviders));
	// }
	// public static function createCustomNotifications(viewer:Null<DiffViewer>, content:DiffContent):Array<JComponent> {
	// 	var providers:Array<DiffNotificationProvider> = getNotificationProviders(content);
	// 	return createNotifications(viewer, providers);
	// }
	// private static function getNotificationProviders(holder:UserDataHolder):Array<DiffNotificationProvider> {
	// 	return ContainerUtil.notNullize(holder.getUserData(DiffUserDataKeys.NOTIFICATION_PROVIDERS));
	// }
	// private static function createNotifications(viewer:Null<DiffViewer>, providers:Array<DiffNotificationProvider>):Array<JComponent> {
	// 	var notifications:Array<JComponent> = ContainerUtil.mapNotNull(providers, it -> it.createNotification(viewer));
	// 	return wrapEditorNotificationBorders(notifications);
	// }
	// public static function wrapEditorNotificationBorders(notifications:Array<JComponent>):Array<JComponent> {
	// 	return ContainerUtil.map(notifications, component -> wrapEditorNotificationComponent(component));
	// }
	// private static function wrapEditorNotificationComponent(component:JComponent):JComponent {
	// 	var border:Border = ClientProperty.get(component, FileEditorManager.SEPARATOR_BORDER);
	// 	if (border == null)
	// 		return component;
	//
	// 	var wrapper:Wrapper = new InvisibleWrapper();
	// 	wrapper.setContent(component);
	// 	wrapper.setBorder(border);
	// 	return wrapper;
	// }
	//
	// DataProvider
	//
	// public static function getData(provider:Null<DataProvider>, fallbackProvider:Null<DataProvider>, dataId:String):Object {
	// 	if (provider != null) {
	// 		var data:Object = provider.getData(dataId);
	// 		if (data != null)
	// 			return data;
	// 	}
	// 	if (fallbackProvider != null) {
	// 		var data:Object = fallbackProvider.getData(dataId);
	// 		if (data != null)
	// 			return data;
	// 	}
	// 	return null;
	// }
	// @:generic
	// public static function putDataKey<T>(holder:UserDataHolder, key:DataKey<T>, value:Null<T>):Void {
	// 	var dataProvider:DataProvider = holder.getUserData(DiffUserDataKeys.DATA_PROVIDER);
	// 	if (!(Std.isOfType(dataProvider, GenericDataProvider))) {
	// 		dataProvider = new GenericDataProvider(dataProvider);
	// 		holder.putUserData(DiffUserDataKeys.DATA_PROVIDER, dataProvider);
	// 	}
	// 	Std.downcast(dataProvider, GenericDataProvider).putData(key, value);
	// }
	// public static function getDiffSettings(context:DiffContext):DiffSettings {
	// 	var settings:DiffSettings = context.getUserData(DiffSettings.KEY);
	// 	if (settings == null) {
	// 		settings = DiffSettings.getSettings(context.getUserData(DiffUserDataKeys.PLACE));
	// 		context.putUserData(DiffSettings.KEY, settings);
	// 	}
	// 	return settings;
	// }
	// @:generic
	// public static function trimDefaultValues<K, V>(map:TreeMap<K, V>, defaultValue:Convertor<K, V>):TreeMap<K, V> {
	// 	var result:Map<K, V> = [];
	// 	for (it in map.entrySet()) {
	// 		var key:K = it.getKey();
	// 		var value:V = it.getValue();
	// 		if (!value.equals(defaultValue.convert(key)))
	// 			result.put(key, value);
	// 	}
	// 	return result;
	// }
	//
	// Tools
	//
	// public static function filterSuppressedTools(tools:Array<DiffTool>):Array<DiffTool> {
	// 	if (tools.size() < 2)
	// 		return tools;
	//
	// 	final suppressedTools:Array<Class<DiffTool>> = [];
	// 	for (tool in tools) {
	// 		try {
	// 			if (Std.isOfType(tool, SuppressiveDiffTool))
	// 				suppressedTools.addAll(Std.downcast(tool, SuppressiveDiffTool)).getSuppressedTools();
	// 		} catch (e:Throwable) {
	// 			LOG.error(e);
	// 		}
	// 	}
	//
	// 	if (suppressedTools.isEmpty())
	// 		return tools;
	//
	// 	var filteredTools:Array<T> = ContainerUtil.filter(tools, tool -> !suppressedTools.contains(tool.getClass()));
	// 	return filteredTools.isEmpty() ? tools : filteredTools;
	// }
	// public static function findToolSubstitutor(tool:DiffTool, context:DiffContext, request:DiffRequest):DiffTool {
	// 	for (substitutor in DiffToolSubstitutor.EP_NAME.getExtensions()) {
	// 		var replacement:DiffTool = substitutor.getReplacement(tool, context, request);
	// 		if (replacement == null)
	// 			continue;
	//
	// 		var canShow:Bool = replacement.canShow(context, request);
	// 		if (!canShow) {
	// 			LOG.error("DiffTool substitutor returns invalid tool");
	// 			continue;
	// 		}
	//
	// 		return replacement;
	// 	}
	// 	return null;
	// }
}

class UpdatedLineRange {
	public final startLine:Int;
	public final endLine:Int;
	public final damaged:Bool;

	public function new(startLine:Int, endLine:Int, damaged:Bool) {
		this.startLine = startLine;
		this.endLine = endLine;
		this.damaged = damaged;
	}
}
