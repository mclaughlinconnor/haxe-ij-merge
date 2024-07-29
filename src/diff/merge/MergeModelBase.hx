// Copyright 2000-2024 JetBrains s.r.o. and contributors. Use of this source code is governed by the Apache 2.0 license.
package diff.merge;

import diff.fragments.MergeModelBase.MergeModelBaseState;
import util.Runnable;
import diff.util.DiffUtil;
import diff.tools.util.text.LineRange;

abstract class MergeModelBase<S:MergeModelBaseState> {
	// private static final Logger LOG = Logger.getInstance(MergeModelBase.class);
	// @Nullable private final Project myProject;
	// @NotNull private final Document myDocument;
	private var myDocument:String;

	// @Nullable private final UndoManager myUndoManager;
	private var myStartLines:Array<Int> = [];
	private var myEndLines:Array<Int> = [];

	private final myChangesToUpdate:thx.Set<Int> = thx.Set.createInt();
	private var myBulkChangeUpdateDepth:Int;

	private var myInsideCommand:Bool;

	private var myDisposed:Bool;

	public function new(/*project: Null<Project>, */ document:String) {
		// myProject = project;
		myDocument = document;
		// myUndoManager = myProject != null ? UndoManager.getInstance(myProject) : UndoManager.getGlobalInstance();

		// myDocument.addDocumentListener(new MyDocumentListener(), this);
	}

	public function dispose():Void {
		if (myDisposed)
			return;
		myDisposed = true;

		// LOG.assertTrue(myBulkChangeUpdateDepth == 0);

		myStartLines = [];
		myEndLines = [];
	}

	public function isDisposed():Bool {
		return myDisposed;
	}

	public function getChangesCount():Int {
		return myStartLines.length;
	}

	public function getDocument():String {
		return myDocument;
	}

	public function getLineStart(index:Int):Int {
		return myStartLines[index];
	}

	public function getLineEnd(index:Int):Int {
		return myEndLines[index];
	}

	public function setChanges(changes:Array<LineRange>):Void {
		myStartLines = [];
		myEndLines = [];

		for (range in changes) {
			myStartLines.push(range.start);
			myEndLines.push(range.end);
		}
	}

	public function isInsideCommand():Bool {
		return myInsideCommand;
	}

	private function setLineStart(index:Int, line:Int):Void {
		myStartLines[index] = line;
	}

	private function setLineEnd(index:Int, line:Int):Void {
		myEndLines[index] = line;
	}

	//
	// RepaInt
	//
	// public Void invalidateHighlighters(Int index) {
	//   if (myBulkChangeUpdateDepth > 0) {
	//     myChangesToUpdate.add(index);
	//   }
	//   else {
	//     reinstallHighlighters(index);
	//   }
	// }
	//
	// @RequiresEdt
	// public Void enterBulkChangeUpdateBlock() {
	//   myBulkChangeUpdateDepth++;
	// }
	//
	// @RequiresEdt
	// public Void exitBulkChangeUpdateBlock() {
	//   myBulkChangeUpdateDepth--;
	//   LOG.assertTrue(myBulkChangeUpdateDepth >= 0);
	//
	//   if (myBulkChangeUpdateDepth == 0) {
	//     myChangesToUpdate.forEach((IntConsumer)index -> {
	//       reinstallHighlighters(index);
	//     });
	//     myChangesToUpdate.clear();
	//   }
	// }
	//
	// @RequiresEdt
	// protected abstract Void reinstallHighlighters(Int index);
	//
	// Undo
	//
	private abstract function storeChangeState(index:Int):S;

	// @RequiresEdt
	private function restoreChangeState(state:S):Void {
		setLineStart(state.myIndex, state.myStartLine);
		setLineEnd(state.myIndex, state.myEndLine);
	}

	private function processDocumentChange(index:Int, oldLine1:Int, oldLine2:Int, shift:Int):S {
		var line1:Int = getLineStart(index);
		var line2:Int = getLineEnd(index);

		var newRange:UpdatedLineRange = DiffUtil.updateRangeOnModificationA(line1, line2, oldLine1, oldLine2, shift);

		// RangeMarker can be updated in a different way
		var rangeAffected:Bool = newRange.damaged || (oldLine2 >= line1 && oldLine1 <= line2);

		var rangeManuallyEdit:Bool = newRange.damaged || (oldLine2 > line1 && oldLine1 < line2);
		// if (rangeManuallyEdit && !isInsideCommand() && (myUndoManager != null && !myUndoManager.isUndoOrRedoInProgress())) {
		//   onRangeManuallyEdit(index);
		// }

		var oldState:S = rangeAffected ? storeChangeState(index) : null;

		setLineStart(index, newRange.startLine);
		setLineEnd(index, newRange.endLine);

		return oldState;
	}

	// @ApiStatus.Internal
	// protected Void onRangeManuallyEdit(Int index) {
	//
	// }

	public function executeMergeCommand(commandName:Null<String>, commandGroupId:Null<String>, /*confirmationPolicy: UndoConfirmationPolicy,*/
			underBulkUpdate:Bool, affectedChanges:Null<Array<Int>>, task:Runnable):Bool {
		var allAffectedChanges:Array<Int> = affectedChanges != null ? collectAffectedChanges(affectedChanges) : null;
		return DiffUtil.executeWriteCommand(task);
		// return DiffUtil.executeWriteCommand(/*myProject, myDocument, commandName, commandGroupId, confirmationPolicy, underBulkUpdate,*/ () -> {
		// 	LOG.assertTrue(!myInsideCommand);
		//
		// 	// We should restore states after changes in document (by DocumentUndoProvider) to aVoid corruption by our onBeforeDocumentChange()
		// 	// Undo actions are performed in backward order, while redo actions are performed in forward order.
		// 	// Thus we should register two UndoableActions.
		//
		// 	// myInsideCommand = true;
		// 	// enterBulkChangeUpdateBlock();
		// 	task.run();
		// 	// try {
		// 	//   registerUndoRedo(true, allAffectedChanges);
		// 	//   try {
		// 	//     task.run();
		// 	//   }
		// 	//   finally {
		// 	//     registerUndoRedo(false, allAffectedChanges);
		// 	//   }
		// 	// }
		// 	// finally {
		// 	//   exitBulkChangeUpdateBlock();
		// 	//   myInsideCommand = false;
		// 	// }
		// });
	}

	// private function registerUndoRedo(undo: Bool , affectedChanges: Null<Array<Int>> ): Void {
	//   if (myUndoManager == null) return;
	//
	//   var  states: List<S>;
	//   if (affectedChanges != null) {
	//     states = [];
	//     for (change in affectedChanges) {
	//       states.add(storeChangeState(index));
	//     }
	//   }
	//   else {
	//     states = [];
	//     for (index in 0...getChangesCount()-1) {
	//       states.add(storeChangeState(index));
	//     }
	//   }
	//   myUndoManager.undoableActionPerformed(new MyUndoableAction(this, states, undo));
	// }
	//
	// Actions
	//

	public function replaceChange(index:Int, newContent:Array<String>):Void {
		// LOG.assertTrue(isInsideCommand());
		var outputStartLine:Int = getLineStart(index);
		var outputEndLine:Int = getLineEnd(index);

		myDocument = DiffUtil.applyModificationA(myDocument, outputStartLine, outputEndLine, newContent);

		if (outputStartLine == outputEndLine) { // onBeforeDocumentChange() should process other cases correctly
			var newOutputEndLine:Int = outputStartLine + newContent.length;
			moveChangesAfterInsertion(index, outputStartLine, newOutputEndLine);
		}
	}

	public function appendChange(index:Int, newContent:Array<String>):Void {
		// LOG.assertTrue(isInsideCommand());
		var outputStartLine:Int = getLineStart(index);
		var outputEndLine:Int = getLineEnd(index);

		myDocument = DiffUtil.applyModificationA(myDocument, outputEndLine, outputEndLine, newContent);

		var newOutputEndLine:Int = outputEndLine + newContent.length;
		moveChangesAfterInsertion(index, outputStartLine, newOutputEndLine);
	}

	/*
	 * We want to include inserted block Into change, so we are updating endLine(BASE).
	 *
	 * It could break order of changes if there are other changes that starts/ends at this line.
	 * So we should check all other changes and shift them if necessary.
	 */
	private function moveChangesAfterInsertion(index:Int, newOutputStartLine:Int, newOutputEndLine:Int):Void {
		// LOG.assertTrue(isInsideCommand());

		if (getLineStart(index) != newOutputStartLine || getLineEnd(index) != newOutputEndLine) {
			setLineStart(index, newOutputStartLine);
			setLineEnd(index, newOutputEndLine);
			// invalidateHighlighters(index);
		}

		var beforeChange:Bool = true;
		for (otherIndex in 0...getChangesCount()) {
			var startLine:Int = getLineStart(otherIndex);
			var endLine:Int = getLineEnd(otherIndex);
			if (endLine < newOutputStartLine)
				continue;
			if (startLine > newOutputEndLine)
				break;
			if (index == otherIndex) {
				beforeChange = false;
				continue;
			}

			var newStartLine:Int = beforeChange ? Std.int(Math.min(startLine, newOutputStartLine)) : newOutputEndLine;
			var newEndLine:Int = beforeChange ? Std.int(Math.min(endLine, newOutputStartLine)) : Std.int(Math.max(endLine, newOutputEndLine));
			if (startLine != newStartLine || endLine != newEndLine) {
				setLineStart(otherIndex, newStartLine);
				setLineEnd(otherIndex, newEndLine);
				// invalidateHighlighters(otherIndex);
			}
		}
	}

	/*
	 * Nearby changes could be affected as well (ex: by moveChangesAfterInsertion)
	 *
	 * null means all changes could be affected
	 */
	private function collectAffectedChanges(directChanges:Array<Int>):Array<Int> {
		var result:Array<Int> = [];

		var directArrayIndex:Int = 0;
		var otherIndex:Int = 0;
		while (directArrayIndex < directChanges.length && otherIndex < getChangesCount()) {
			var directIndex:Int = directChanges[directArrayIndex];

			if (directIndex == otherIndex) {
				result.push(directIndex);
				otherIndex++;
				continue;
			}

			var directStart:Int = getLineStart(directIndex);
			var directEnd:Int = getLineEnd(directIndex);
			var otherStart:Int = getLineStart(otherIndex);
			var otherEnd:Int = getLineEnd(otherIndex);

			if (otherEnd < directStart) {
				otherIndex++;
				continue;
			}
			if (otherStart > directEnd) {
				directArrayIndex++;
				continue;
			}

			result.push(otherIndex);
			otherIndex++;
		}

		// LOG.assertTrue(directChanges.size() <= result.size());
		return result;
	}

	//
	// Helpers
	//
}
// private class MyDocumentListener implements DocumentListener {
//   @Override
//   public Void beforeDocumentChange(@NotNull DocumentEvent e) {
//     if (isDisposed()) return;
//     enterBulkChangeUpdateBlock();
//
//     if (getChangesCount() == 0) return;
//
//     LineRange lineRange = DiffUtil.getAffectedLineRange(e);
//     Int shift = DiffUtil.countLinesShift(e);
//
//     List<S> corruptedStates = new SmartList<>();
//     for (Int index = 0; index < getChangesCount(); index++) {
//       S oldState = processDocumentChange(index, lineRange.start, lineRange.end, shift);
//       if (oldState == null) continue;
//
//       invalidateHighlighters(index);
//       if (!isInsideCommand()) corruptedStates.add(oldState);
//     }
//
//     if (myUndoManager != null && !corruptedStates.isEmpty()) {
//       // document undo is registered inside onDocumentChange, so our undo() will be called after its undo().
//       // thus thus we can aVoid checks for isUndoInProgress() (to aVoid modification of the same TextMergeChange by this listener)
//       myUndoManager.undoableActionPerformed(new MyUndoableAction(MergeModelBase.this, corruptedStates, true));
//     }
//   }
//
//   @Override
//   public Void documentChanged(@NotNull DocumentEvent e) {
//     if (isDisposed()) return;
//     exitBulkChangeUpdateBlock();
//   }
// }
// private static final class MyUndoableAction extends BasicUndoableAction {
//   @NotNull private final WeakReference<MergeModelBase<?>> myModelRef;
//   @NotNull private final List<? extends State> myStates;
//   private final Bool myUndo;
//
//   MyUndoableAction(@NotNull MergeModelBase<?> model, @NotNull List<? extends State> states, Bool undo) {
//     super(model.myDocument);
//     myModelRef = new WeakReference<>(model);
//
//     myStates = states;
//     myUndo = undo;
//   }
//
//   @Override
//   public Void undo() {
//     MergeModelBase<?> model = myModelRef.get();
//     if (model != null && myUndo) restoreStates(model);
//   }
//
//   @Override
//   public Void redo() {
//     MergeModelBase<?> model = myModelRef.get();
//     if (model != null && !myUndo) restoreStates(model);
//   }
//
//   private Void restoreStates(@NotNull MergeModelBase model) {
//     if (model.isDisposed()) return;
//     if (model.getChangesCount() == 0) return;
//
//     model.enterBulkChangeUpdateBlock();
//     try {
//       for (state in myStates) {
//         //noinspection unchecked
//         model.restoreChangeState(state);
//         model.invalidateHighlighters(state.myIndex);
//       }
//     }
//     finally {
//       model.exitBulkChangeUpdateBlock();
//     }
//   }
// }

class MergeModelBaseState {
	public final myIndex:Int;
	public final myStartLine:Int;
	public final myEndLine:Int;

	public function new(index:Int, startLine:Int, endLine:Int) {
		myIndex = index;
		myStartLine = startLine;
		myEndLine = endLine;
	}
}
