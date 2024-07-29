// Copyright 2000-2020 JetBrains s.r.o. Use of this source code is governed by the Apache 2.0 license that can be found in the LICENSE file.
package diff.merge;

import diff.fragments.TextMergeChange;
import diff.fragments.ThreesideDiffChangeBase;

abstract class ThreesideTextDiffViewerEx {
	private var myChangesCount:Int = -1;
	private var myConflictsCount:Int = -1;

	private function destroyChangedBlocks():Void {}

	public function getChangesCount():Int {
		return myChangesCount;
	}

	public function getConflictsCount():Int {
		return myConflictsCount;
	}

	private function resetChangeCounters():Void {
		myChangesCount = 0;
		myConflictsCount = 0;
	}

	private function onChangeAdded(change:ThreesideDiffChangeBase):Void {
		if (change.isConflict()) {
			myConflictsCount++;
		} else {
			myChangesCount++;
		}
	}

	private function onChangeRemoved(change:ThreesideDiffChangeBase):Void {
		if (change.isConflict()) {
			myConflictsCount--;
		} else {
			myChangesCount--;
		}
	}

	//
	// Getters
	//

	/*
	 * Some changes (ex: applied ones) can be excluded from general processing, but should be painted/used for synchronized scrolling
	 */
	@NotNull
	public function getAllChanges():Array<TextMergeChange> {
		return getChanges();
	}

	private abstract function getChanges():Array<TextMergeChange>;
}
