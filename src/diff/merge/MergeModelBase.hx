// Copyright 2000-2024 JetBrains s.r.o. and contributors. Use of this source code is governed by the Apache 2.0 license.
package diff.merge;

import util.Runnable;
import diff.util.DiffUtil;
import diff.tools.util.text.LineRange;

abstract class MergeModelBase<S:MergeModelBaseState> {
	private var myDocument:String;

	private var myStartLines:Array<Int> = [];
	private var myEndLines:Array<Int> = [];

	private final myChangesToUpdate:thx.Set<Int> = thx.Set.createInt();
	private var myBulkChangeUpdateDepth:Int;

	private var myInsideCommand:Bool;

	private var myDisposed:Bool;

	public function new(document:String) {
		myDocument = document;
	}

	public function dispose():Void {
		if (myDisposed)
			return;
		myDisposed = true;

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

	public function getLineStartOffset(line:Int):Int {
		if (line == 0) {
			return 0; // for 0 length document
		}

		var currentLine = 0;
		for (i in 0...myDocument.length) {
			if (currentLine == line) {
				return i;
			}
			if (myDocument.charAt(i) == '\n') {
				currentLine++;
			}
		}

		throw "Line number out of bounds";
	}

	public function getLineNumber(index:Int):Int {
		if (index < 0) {
			index = 0;
		}

		if (index > myDocument.length) {
			index = myDocument.length;
		}

		var lineNumber = 0;
		for (i in 0...index) {
			if (myDocument.charAt(i) == '\n') {
				lineNumber++;
			}
		}

		return lineNumber;
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
	// Undo
	//
	private abstract function storeChangeState(index:Int):S;

	private function processDocumentChange(index:Int, oldLine1:Int, oldLine2:Int, shift:Int):S {
		var line1:Int = getLineStart(index);
		var line2:Int = getLineEnd(index);

		var newRange:UpdatedLineRange = DiffUtil.updateRangeOnModificationA(line1, line2, oldLine1, oldLine2, shift);

		// RangeMarker can be updated in a different way
		var rangeAffected:Bool = newRange.damaged || (oldLine2 >= line1 && oldLine1 <= line2);

		var oldState:S = rangeAffected ? storeChangeState(index) : null;

		setLineStart(index, newRange.startLine);
		setLineEnd(index, newRange.endLine);

		return oldState;
	}

	public function executeMergeCommand(commandName:Null<String>, commandGroupId:Null<String>, underBulkUpdate:Bool, affectedChanges:Null<Array<Int>>,
			task:Runnable):Bool {
		return DiffUtil.executeWriteCommand(task);
	}

	//
	// Actions
	//

	public function replaceChange(index:Int, newContent:Array<String>):Void {
		var outputStartLine:Int = getLineStart(index);
		var outputEndLine:Int = getLineEnd(index);

		var lines = StringUtil.countNewLines(myDocument) + 1;
		var newString:String;

		var offset1 = 0;
		var offset2 = 0;

		if (newContent.length == 0) {
			newString = "";

			var range = DiffUtil.getLinesRangeA(myDocument, outputStartLine, outputEndLine);
			offset1 = range.getStartOffset();
			offset2 = range.getEndOffset();

			if (offset1 > 0) {
				offset1--;
			} else if (offset2 < myDocument.length) {
				offset2++;
			}
		} else {
			offset1 = getLineStartOffset(outputStartLine);
			offset2 = getLineStartOffset(outputEndLine);
			if (index == lines) {
				newString = "\n" + newContent.join("\n");
			} else {
				newString = newContent.join("\n") + "\n";
			}
		}

		var event:DocumentEvent<S> = new DocumentEvent(this, offset1, myDocument.substring(offset1, offset2), newString);
		beforeDocumentChange(event);

		myDocument = DiffUtil.applyModificationA(myDocument, outputStartLine, outputEndLine, newContent);

		if (outputStartLine == outputEndLine) { // onBeforeDocumentChange() should process other cases correctly
			var newOutputEndLine:Int = outputStartLine + newContent.length;
			moveChangesAfterInsertion(index, outputStartLine, newOutputEndLine);
		}
	}

	public function appendChange(index:Int, newContent:Array<String>):Void {
		var outputStartLine:Int = getLineStart(index);
		var outputEndLine:Int = getLineEnd(index);

		var event:DocumentEvent<S> = new DocumentEvent(this, getLineStartOffset(outputStartLine), "", newContent.join("\n"));
		beforeDocumentChange(event);
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
		if (getLineStart(index) != newOutputStartLine || getLineEnd(index) != newOutputEndLine) {
			setLineStart(index, newOutputStartLine);
			setLineEnd(index, newOutputEndLine);
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

		return result;
	}

	//
	// Helpers
	//

	public function beforeDocumentChange(e:DocumentEvent<S>):Void {
		if (isDisposed())
			return;

		if (getChangesCount() == 0)
			return;

		// CM: Weird types here
		var lineRange:LineRange = DiffUtil.getAffectedLineRange(cast e);
		var shift:Int = DiffUtil.countLinesShift(cast e);

		var corruptedStates:Array<S> = [];
		for (index in 0...getChangesCount()) {
			var oldState:S = processDocumentChange(index, lineRange.start, lineRange.end, shift);
			if (oldState == null)
				continue;

			// invalidateHighlighters(index);
			if (!isInsideCommand())
				corruptedStates.push(oldState);
		}
	}
}

class DocumentEvent<S:MergeModelBaseState> {
	private final myMergeModel:MergeModelBase<S>;
	private final myOffset:Int;
	private final myOldString:String;
	private final myNewString:String;
	private final myOldLength:Int;
	private final myNewLength:Int;

	public function new(mergeModel:MergeModelBase<S>, offset:Int, oldString:String, newString:String) {
		myMergeModel = mergeModel;
		myOffset = offset;
		myOldString = oldString;
		myNewString = newString;
		myOldLength = oldString.length;
		myNewLength = newString.length;
	}

	public function getOffset():Int {
		return myOffset;
	}

	public function getOldLength():Int {
		return myOldLength;
	}

	public function getNewFragment():String {
		return myNewString;
	}

	public function getOldFragment():String {
		return myOldString;
	}

	public function getModel():MergeModelBase<S> {
		return myMergeModel;
	}
}

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
