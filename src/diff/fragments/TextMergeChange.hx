// Copyright 2000-2024 JetBrains s.r.o. and contributors. Use of this source code is governed by the Apache 2.0 license.
package diff.fragments;

import diff.tools.util.text.MergeInnerDifferences;
import diff.fragments.MergeModelBase.MergeModelBaseState;
import diff.util.Side;
import diff.util.TextDiffType;
import diff.util.ThreeSide;
import diff.util.MergeConflictType;

class TextMergeChange extends ThreesideDiffChangeBase {
	// private final myMergeViewer:TextMergeViewer;
	// private final myViewer:MergeThreesideViewer;
	private final myIndex:Int;
	private final myFragment:MergeLineFragment;
	private final myIsImportChange:Bool;

	private final myResolved:Array<Bool> = [];
	private var myOnesideAppliedConflict:Bool;

	// private var myIsResolvedWithAI:Bool;
	private var myInnerFragments:MergeInnerDifferences; // warning: might be out of date

	public function new(index:Int, isImportChange:Bool, fragment:MergeLineFragment, conflictType:MergeConflictType/*, viewer:TextMergeViewer*/) {
		super(conflictType);
		// myMergeViewer = viewer;
		// myViewer = viewer.getViewer();

		myIndex = index;
		myFragment = fragment;
		myIsImportChange = isImportChange;

		// reinstallHighlighters();
	}

	// @RequiresEdt
	// public Void reinstallHighlighters() {
	//   destroyHighlighters();
	//   installHighlighters();
	//
	//   destroyOperations();
	//   installOperations();
	//
	//   myViewer.repaIntDividers();
	// }
	//
	// Getters
	//
	public function getIndex():Int {
		return myIndex;
	}

	public function setResolved(side:Side, value:Bool):Void {
		myResolved[side.getIndex()] = value;

		// if (isResolved()) {
		//   destroyInnerHighlighters();
		// }
		// else {
		//   // Destroy only resolved side to reduce blinking
		//   Document document = myViewer.getEditor(side.select(ThreeSide.LEFT, ThreeSide.RIGHT)).getDocument();
		//   for (RangeHighlighter highlighter : myInnerHighlighters) {
		//     if (document.equals(highlighter.getDocument())) {
		//       highlighter.dispose(); // it's OK to call dispose() few times
		//     }
		//   }
		// }
	}

	public function isResolvedA():Bool {
		return myResolved[0] && myResolved[1];
	}

	public function isResolvedB(side:Side):Bool {
		return side.selectB(myResolved);
	}

	public function isOnesideAppliedConflict():Bool {
		return myOnesideAppliedConflict;
	}

	private function markOnesideAppliedConflict():Void {
		myOnesideAppliedConflict = true;
	}

	// private function markChangeResolvedWithAI():Void {
	// 	myIsResolvedWithAI = true;
	// }
	// private function isResolvedWithAI():Bool {
	// 	return myIsResolvedWithAI;
	// }

	public function isImportChange():Bool {
		return myIsImportChange;
	}

	public function isResolvedC(side:ThreeSideEnum):Bool {
		return switch (side) {
			case LEFT: isResolvedB(Side.fromEnum(SideEnum.LEFT));
			case BASE: isResolvedA();
			case RIGHT: isResolvedB(Side.fromEnum(SideEnum.RIGHT));
		};
	}

	public function getStartLineA():Int {
		return 0;
		// return myViewer.getModel().getLineStart(myIndex);
	}

	public function getEndLineA():Int {
		return 100;
		// return myViewer.getModel().getLineEnd(myIndex);
	}

	public function getStartLineB(side:ThreeSideEnum):Int {
		if (side == ThreeSideEnum.BASE) {
			return getStartLineA();
		}
		return myFragment.getStartLine(ThreeSide.fromEnum(side));
	}

	public function getEndLineB(side:ThreeSide):Int {
		if (ThreeSide.fromIndex(side.getIndex()) == ThreeSideEnum.BASE)
			return getEndLineA();
		return myFragment.getEndLine(side);
	}

	public override function getDiffType():TextDiffType {
		var baseType:TextDiffType = super.getDiffType();
		// if (!myIsResolvedWithAI) {
		return baseType;
		// }

		// return new MyAIResolvedDiffType(baseType);
	}

	// private override function getEditor(side:ThreeSide):Editor {
	// 	return myViewer.getEditor(side);
	// }

	private function getInnerFragments():MergeInnerDifferences {
		return myInnerFragments;
	}

	public function getFragment():MergeLineFragment {
		return myFragment;
	}

	public function setInnerFragments(innerFragments:Null<MergeInnerDifferences>):Void {
		if (myInnerFragments == null && innerFragments == null) {
			return;
		}
		myInnerFragments = innerFragments;

		// reinstallHighlighters();
		//
		// destroyInnerHighlighters();
		// installInnerHighlighters();
	}

	//
	// Gutter actions
	//
	// @Override
	// @RequiresEdt
	// protected Void installOperations() {
	//   if (myViewer.isExternalOperationInProgress()) return;
	//
	//   ContainerUtil.addIfNotNull(myOperations, createResolveOperation());
	//   ContainerUtil.addIfNotNull(myOperations, createAcceptOperation(Side.LEFT, OperationType.APPLY));
	//   ContainerUtil.addIfNotNull(myOperations, createAcceptOperation(Side.LEFT, OperationType.IGNORE));
	//   ContainerUtil.addIfNotNull(myOperations, createAcceptOperation(Side.RIGHT, OperationType.APPLY));
	//   ContainerUtil.addIfNotNull(myOperations, createAcceptOperation(Side.RIGHT, OperationType.IGNORE));
	//   ContainerUtil.addIfNotNull(myOperations, createResetOperation());
	// }
	//
	// @Nullable
	// private DiffGutterOperation createOperation(@NotNull ThreeSide side, @NotNull DiffGutterOperation.ModifiersRendererBuilder builder) {
	//   if (isResolved(side)) return null;
	//
	//   EditorEx editor = myViewer.getEditor(side);
	//   Int offset = DiffGutterOperation.lineToOffset(editor, getStartLine(side));
	//
	//   return new DiffGutterOperation.WithModifiers(editor, offset, myViewer.getModifierProvider(), builder);
	// }
	//
	// @Nullable
	// private DiffGutterOperation createResolveOperation() {
	//   return createOperation(ThreeSide.BASE, (ctrlPressed, shiftPressed, altPressed) -> {
	//     return createResolveRenderer();
	//   });
	// }
	//
	// @Nullable
	// private DiffGutterOperation createAcceptOperation(@NotNull Side versionSide, @NotNull OperationType type) {
	//   ThreeSide side = versionSide.select(ThreeSide.LEFT, ThreeSide.RIGHT);
	//   return createOperation(side, (ctrlPressed, shiftPressed, altPressed) -> {
	//     if (!isChange(versionSide)) return null;
	//
	//     if (type == OperationType.APPLY) {
	//       return createApplyRenderer(versionSide, ctrlPressed);
	//     }
	//     else {
	//       return createIgnoreRenderer(versionSide, ctrlPressed);
	//     }
	//   });
	// }
	//
	// @Nullable
	// private DiffGutterOperation createResetOperation() {
	//   if (!isResolved() || !myIsResolvedWithAI) return null;
	//
	//   EditorEx editor = myViewer.getEditor(ThreeSide.BASE);
	//   Int offset = DiffGutterOperation.lineToOffset(editor, getStartLine(ThreeSide.BASE));
	//
	//
	//   return new DiffGutterOperation.Simple(editor, offset, () -> {
	//     return createIconRenderer(DiffBundle.message("action.presentation.diff.revert.text"), AllIcons.Diff.Revert, false, () -> {
	//       myViewer.executeMergeCommand(DiffBundle.message("merge.dialog.reset.change.command"),
	//                                    Collections.singletonList(this),
	//                                    () -> myViewer.resetResolvedChange(this));
	//     });
	//   });
	// }
	//
	// @Nullable
	// private GutterIconRenderer createApplyRenderer(@NotNull final Side side, final Bool modifier) {
	//   if (isResolved(side)) return null;
	//   Icon icon = isOnesideAppliedConflict() ? DiffUtil.getArrowDownIcon(side) : DiffUtil.getArrowIcon(side);
	//   return createIconRenderer(DiffBundle.message("action.presentation.diff.accept.text"), icon, isConflict(), () -> {
	//     myViewer.executeMergeCommand(DiffBundle.message("merge.dialog.accept.change.command"),
	//                                  Collections.singletonList(this),
	//                                  () -> myViewer.replaceSingleChange(this, side, modifier));
	//   });
	// }
	//
	// @Nullable
	// private GutterIconRenderer createIgnoreRenderer(@NotNull final Side side, final Bool modifier) {
	//   if (isResolved(side)) return null;
	//   return createIconRenderer(DiffBundle.message("action.presentation.merge.ignore.text"), AllIcons.Diff.Remove, isConflict(), () -> {
	//     myViewer.executeMergeCommand(DiffBundle.message("merge.dialog.ignore.change.command"), Collections.singletonList(this),
	//                                  () -> myViewer.ignoreChange(this, side, modifier));
	//   });
	// }
	//
	// @Nullable
	// private GutterIconRenderer createResolveRenderer() {
	//   if (!this.isConflict() || !myViewer.canResolveChangeAutomatically(this, ThreeSide.BASE)) return null;
	//
	//   return createIconRenderer(DiffBundle.message("action.presentation.merge.resolve.text"), AllIcons.Diff.MagicResolve, false, () -> {
	//     myViewer.executeMergeCommand(DiffBundle.message("merge.dialog.resolve.conflict.command"), Collections.singletonList(this),
	//                                  () -> myViewer.resolveSingleChangeAutomatically(this, ThreeSide.BASE));
	//   });
	// }
	//
	// @NotNull
	// private static GutterIconRenderer createIconRenderer(@NotNull final @NlsContexts.Tooltip String text,
	//                                                      @NotNull final Icon icon,
	//                                                      Bool ctrlClickVisible,
	//                                                      @NotNull final Runnable perform) {
	//   @Nls String appendix = ctrlClickVisible ? DiffBundle.message("tooltip.merge.ctrl.click.to.resolve.conflict") : null;
	//   final String tooltipText = DiffUtil.createTooltipText(text, appendix);
	//   return new DiffGutterRenderer(icon, tooltipText) {
	//     @Override
	//     protected Void handleMouseClick() {
	//       perform.run();
	//     }
	//   };
	// }
	//
	// private enum OperationType {
	//   APPLY, IGNORE
	// }
	//
	// State
	//

	public function storeState():State {
		return new State(myIndex, getStartLineA(), getEndLineA(), myResolved[0], myResolved[1], myOnesideAppliedConflict/*, myIsResolvedWithAI*/);
	}

	public function restoreState(state:State):Void {
		myResolved[0] = state.myResolved1;
		myResolved[1] = state.myResolved2;

		myOnesideAppliedConflict = state.myOnesideAppliedConflict;
		// myIsResolvedWithAI = state.myIsResolvedByAI;
	}

	private function resetState():Void {
		myResolved[0] = false;
		myResolved[1] = false;
		myOnesideAppliedConflict = false;
		// myIsResolvedWithAI = false;
	}

	// }
}

class State extends MergeModelBaseState {
	public final myResolved1:Bool;
	public final myResolved2:Bool;

	public final myOnesideAppliedConflict:Bool;
	// public final myIsResolvedByAI:Bool;

	public function new(index:Int, startLine:Int, endLine:Int, resolved1:Bool, resolved2:Bool, onesideAppliedConflict:Bool/*, isResolvedByAI:Bool*/) {
		super(index, startLine, endLine);
		myResolved1 = resolved1;
		myResolved2 = resolved2;
		myOnesideAppliedConflict = onesideAppliedConflict;
		// myIsResolvedByAI = isResolvedByAI;
	}
}

// private static class MyAIResolvedDiffType implements TextDiffType {
//   private final TextDiffType myBaseType;
//
//   private MyAIResolvedDiffType(TextDiffType baseType) {
//     myBaseType = baseType;
//   }
//
//   @Override
//   public @NotNull String getName() {
//     return myBaseType.getName();
//   }
//
//   @Override
//   public @NotNull Color getColor(@Nullable Editor editor) {
//     return AI_COLOR;
//   }
//
//   @Override
//   public @NotNull Color getIgnoredColor(@Nullable Editor editor) {
//     return myBaseType.getIgnoredColor(editor);
//   }
//
//   @Override
//   public @Nullable Color getMarkerColor(@Nullable Editor editor) {
//     return myBaseType.getMarkerColor(editor);
//   }
// }
