// Copyright 2000-2020 JetBrains s.r.o. Use of this source code is governed by the Apache 2.0 license that can be found in the LICENSE file.
package diff.comparison;

import diff.comparison.ComparisonManageImpl.ComparisonManagerImpl;
import diff.fragments.MergeLineFragment;
import diff.fragments.LineFragment;

/**
 * Class for the text comparison
 * CharSequences should to have '\n' as line separator
 * <p/>
 * It's good idea not to compare String due to expensive subSequence() implementation. Use CharSequenceSubSequence.
 */
abstract class ComparisonManager {
	public function new() {}

	public static function getInstance():ComparisonManager {
    return new ComparisonManagerImpl();
  };

	/**
	 * Compare two texts by-line
	 */
	public abstract function compareLinesA(text1:String, text2:String, policy:ComparisonPolicy /*, indicator:ProgressIndicator*/):Array<LineFragment>;

	// /**
	//  * Compare two texts by-line and then compare changed fragments by-word
	//  */
	// public abstract function compareLinesInner(text1:String, text2:String, policy:ComparisonPolicy/*, indicator:ProgressIndicator*/):Array<LineFragment>;

	/**
	 * Compare three texts by-line (LEFT - BASE - RIGHT)
	 */
	public abstract function compareLinesB(text1:String, text2:String, text3:String,
		policy:ComparisonPolicy /*, indicator:ProgressIndicator*/):Array<MergeLineFragment>;

	// /**
	//  * Compare three texts by-line (LEFT - BASE - RIGHT)
	//  * Do not actually skip "ignored" changes, but keep them from forming merge conflicts.
	//  */
	public abstract function mergeLines(text1:String, text2:String, text3:String, policy:ComparisonPolicy/*, indicator:ProgressIndicator*/):Array<MergeLineFragment>;
	//
	// /**
	//  * Compare three texts by-line (LEFT - BASE - RIGHT)
	//  * Do not actually skip "ignored" changes, but keep them from forming merge conflicts.
	//  */
	// public abstract function mergeLinesWithinRange(text1:String, text2:String, text3:String, policy:ComparisonPolicy, range:MergeRange/*, indicator:ProgressIndicator*/):Array<MergeLineFragment>;
	//
	// /**
	//  * Return the common parts of the two files, that can be used as an ad-hoc merge base content.
	//  */
	// public abstract function mergeLinesAdditions(text1:String, text3:String, policy:ComparisonPolicy/*, indicator:ProgressIndicator*/):String;
	//
	// /**
	//  * Compare two texts by-word
	//  */
	// public abstract function compareWords(text1:String, text2:String, policy:ComparisonPolicy/*, indicator:ProgressIndicator*/):Array<DiffFragment>;
	//
	// /**
	//  * Compare two texts by-char
	//  */
	// public abstract function compareChars(text1:String, text2:String, policy:ComparisonPolicy/*, indicator:ProgressIndicator*/):Array<DiffFragment>;
	//
	// /**
	//  * Check if two texts are equal using ComparisonPolicy
	//  */
	// public abstract function isEquals(text1:String, text2:String, policy:ComparisonPolicy):Bool;
	//
	// //
	// // Post process line fragments
	// //
	//
	// /**
	//  * compareLinesInner() comparison can produce adjustment line chunks. This method allows to squash shem.
	//  *
	//  * ex: "A\nB" vs "A X\nB Y" will result to two LineFragments: [0, 1) - [0, 1) and [1, 2) - [1, 2)
	//  *     squash will produce a single fragment: [0, 2) - [0, 2)
	//  */
	// public abstract function squash(oldFragments:Array<LineFragment>):Array<LineFragment>;
	//
	// /**
	//  * @see #squash
	//  * @param trim - if leading/trailing LineFragments with equal contents should be skipped
	//  */
	// public abstract function processBlocks(oldFragments:Array<LineFragment>, text1:String, text2:String, policy:ComparisonPolicy, squash:Bool, trim:Bool):Array<LineFragment>;
}
