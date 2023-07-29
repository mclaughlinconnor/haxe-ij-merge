// Copyright 2000-2021 JetBrains s.r.o. and contributors. Use of this source code is governed by the Apache 2.0 license.
package diff.util;

import diff.util.Side;
import diff.util.ThreeSide.ThreeSideEnum;
import exceptions.IllegalArgumentException;

enum MergeConflictTypeEnum {
	INSERTED;
	DELETED;
	MODIFIED;
	CONFLICT;
}

class MergeConflictType {
	private final myType:MergeConflictTypeEnum;
	private final myLeftChange:Bool;
	private final myRightChange:Bool;
	private final myCanBeResolved:Bool;

	public function new(type:MergeConflictTypeEnum, leftChange:Bool, rightChange:Bool, ?canBeResolved:Bool = true) {
		myType = type;
		myLeftChange = leftChange;
		myRightChange = rightChange;
		myCanBeResolved = canBeResolved;
	}

	public function getType():MergeConflictTypeEnum {
		return myType;
	}

	public function canBeResolved():Bool {
		return myCanBeResolved;
	}

	public function isChangeA(side:Side):Bool {
		// Wrong?
		return side.isLeft() ? myLeftChange : myRightChange;
		// return side == SideEnum.LEFT ? myLeftChange : myRightChange;
	}

	public function isChangeB(side:ThreeSideEnum):Bool {
		var isChange:Bool;
		switch (side) {
			case ThreeSideEnum.LEFT:
				isChange = myLeftChange;
			case ThreeSideEnum.BASE:
				isChange = true;
			case ThreeSideEnum.RIGHT:
				isChange = myRightChange;
			default:
				throw new IllegalArgumentException('');
		}

		return isChange;
	}
}
