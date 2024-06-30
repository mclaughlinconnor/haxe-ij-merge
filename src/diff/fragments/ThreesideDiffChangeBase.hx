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

package diff.fragments;

import diff.util.DiffUtil;
import diff.util.Side;
import diff.tools.util.text.MergeInnerDifferences;
import diff.util.ThreeSide;
import diff.util.MergeConflictType;
import diff.util.TextDiffType;

abstract class ThreesideDiffChangeBase {
	private var myType:MergeConflictType;

	// private final myHighlighters:Array<RangeHighlighter> = [];
	// private final myInnerHighlighters:Array<RangeHighlighter> = [];
	// private final myOperations:Array<DiffGutterOperation> = [];

	public function new(type:MergeConflictType) {
		myType = type;
	}

	// public function  destroy(): Void {
	//   destroyHighlighters();
	//   destroyInnerHighlighters();
	//   destroyOperations();
	// }
	// private function  installHighlighters(): Void {
	//   assert myHighlighters.isEmpty();
	//
	//   createHighlighter(ThreeSide.BASE);
	//   if (isChange(Side.LEFT)) createHighlighter(ThreeSide.LEFT);
	//   if (isChange(Side.RIGHT)) createHighlighter(ThreeSide.RIGHT);
	// }
	//
	// @RequiresEdt
	// protected Void installInnerHighlighters() {
	//   assert myInnerHighlighters.isEmpty();
	//
	//   createInnerHighlighter(ThreeSide.BASE);
	//   if (isChange(Side.LEFT)) createInnerHighlighter(ThreeSide.LEFT);
	//   if (isChange(Side.RIGHT)) createInnerHighlighter(ThreeSide.RIGHT);
	// }
	//
	// @RequiresEdt
	// protected Void destroyHighlighters() {
	//   for (RangeHighlighter highlighter : myHighlighters) {
	//     highlighter.dispose();
	//   }
	//   myHighlighters.clear();
	// }
	//
	// @RequiresEdt
	// protected Void destroyInnerHighlighters() {
	//   for (RangeHighlighter highlighter : myInnerHighlighters) {
	//     highlighter.dispose();
	//   }
	//   myInnerHighlighters.clear();
	// }
	//
	// @RequiresEdt
	// protected Void installOperations() {
	// }
	//
	// @RequiresEdt
	// protected Void destroyOperations() {
	//   for (DiffGutterOperation operation : myOperations) {
	//     operation.dispose();
	//   }
	//   myOperations.clear();
	// }
	//
	// public Void updateGutterActions(Bool force) {
	//   for (DiffGutterOperation operation : myOperations) {
	//     operation.update(force);
	//   }
	// }
	//
	// Getters
	//

	// public abstract function getStartLineA(side:ThreeSideEnum):Int;
	//
	// public abstract function getEndLineA(side:ThreeSideEnum):Int;
	//
	// public abstract function isResolved(side:ThreeSideEnum):Bool;

	// private abstract function getEditor(side:ThreeSide):Editor;

	private abstract function getInnerFragments():MergeInnerDifferences;

	public function getDiffType():TextDiffType {
		return DiffUtil.getDiffTypeD(myType);
	}

	public function getConflictType():MergeConflictType {
		return myType;
	}

	public function isConflict():Bool {
		return myType.getType() == MergeConflictTypeEnum.CONFLICT;
	}

	public function isChangeA(side:Side):Bool {
		return myType.isChangeA(side);
	}

	public function isChangeB(side:ThreeSideEnum):Bool {
		return myType.isChangeB(side);
	}

	//
	// Highlighters
	//
	// protected Void createHighlighter(@NotNull ThreeSide side) {
	//   Editor editor = getEditor(side);
	//
	//   TextDiffType type = getDiffType();
	//   Int startLine = getStartLine(side);
	//   Int endLine = getEndLine(side);
	//
	//   Bool resolved = isResolved(side);
	//   Bool ignored = !resolved && getInnerFragments() != null;
	//   Bool shouldHideWithoutLineNumbers = side == ThreeSide.BASE && !isChange(Side.LEFT) && isChange(Side.RIGHT);
	//   myHighlighters.addAll(new DiffDrawUtil.LineHighlighterBuilder(editor, startLine, endLine, type)
	//                           .withIgnored(ignored)
	//                           .withResolved(resolved)
	//                           .withHideWithoutLineNumbers(shouldHideWithoutLineNumbers)
	//                           .withHideStripeMarkers(side == ThreeSide.BASE)
	//                           .done());
	// }
	//
	// protected Void createInnerHighlighter(@NotNull ThreeSide side) {
	//   if (isResolved(side)) return;
	//   MergeInnerDifferences innerFragments = getInnerFragments();
	//   if (innerFragments == null) return;
	//
	//   List<TextRange> ranges = innerFragments.get(side);
	//   if (ranges == null) return;
	//
	//   Editor editor = getEditor(side);
	//   Int start = DiffUtil.getLinesRange(editor.getDocument(), getStartLine(side), getEndLine(side)).getStartOffset();
	//   for (TextRange fragment : ranges) {
	//     Int innerStart = start + fragment.getStartOffset();
	//     Int innerEnd = start + fragment.getEndOffset();
	//     myInnerHighlighters.addAll(DiffDrawUtil.createInlineHighlighter(editor, innerStart, innerEnd, getDiffType()));
	//   }
	// }
}
