import diff.util.ThreeSide;
import diff.util.ThreeSide.ThreeSideEnum;
import diff.merge.MergeThreesideViewer;
import config.DiffConfig;

class MergeDriver {
	/**
		Merges base, current, other

		Will return a string with merge conflict markers if ther merge cannot be completed without conflicts

		See https://git-scm.com/docs/gitattributes#_defining_a_custom_merge_driver
	**/
	static public function mergeStrings(base:String, current:String, other:String, opts:Int):{diff:String, noConflicts:Bool} {
		DiffConfig.AUTO_APPLY_NON_CONFLICTED_CHANGES = (opts & (1 << 0)) != 0;
		DiffConfig.USE_GREEDY_MERGE_MAGIC_RESOLVE = (opts & (1 << 1)) != 0;
		DiffConfig.USE_PATIENCE_ALG = (opts & (1 << 2)) != 0;
		var conflicts = (opts & (1 << 3)) != 0;

		var viewer = new MergeThreesideViewer([current, base, other], base);
		viewer.rediff(false);

		if (conflicts) {
			viewer.applyResolvableConflictedChanges();
		}

		var git = new GitDiff([current, viewer.myModel.getDocument(), other], viewer.myAllMergeChanges);
		return {diff: git.formatDiff(), noConflicts: viewer.getChanges().length == 0};
	}

	static public function mergeStringsAtBaseLine(base:String, current:String, other:String, line:Int, opts:Int):{buffer:String, resolved:Bool} {
		DiffConfig.AUTO_APPLY_NON_CONFLICTED_CHANGES = (opts & (1 << 0)) != 0;
		DiffConfig.USE_GREEDY_MERGE_MAGIC_RESOLVE = (opts & (1 << 1)) != 0;
		DiffConfig.USE_PATIENCE_ALG = (opts & (1 << 2)) != 0;
		var conflicts = (opts & (1 << 3)) != 0;

		var viewer = new MergeThreesideViewer([current, base, other], base);
		viewer.rediff(false);

		if (conflicts) {
			viewer.applyResolvableConflictedChanges();
		}

		final baseSide = ThreeSide.fromEnum(ThreeSideEnum.BASE);

		for (change in viewer.myAllMergeChanges) {
			if (change.getStartLineA() < line && change.getEndLineA() >= line) {
				if (viewer.canResolveChangeAutomatically(change, baseSide)) {
					viewer.resolveChangesAutomatically([change], ThreeSide.fromEnum(ThreeSideEnum.BASE));
					return {buffer: viewer.myModel.getDocument(), resolved: true};
				}
			}
		}

		return {buffer: viewer.myModel.getDocument(), resolved: false};
	}
	/** 
		Merges base, current, other into result other

		Returns `true` if the merge was successful, with no conflicts.
		Returns `false` when there are still unresolved conflicts.

		See https://git-scm.com/docs/gitattributes#_defining_a_custom_merge_driver
	**/
	static public function mergeFiles(baseO:String, currentA:String, otherB:String, ?markerSizeL:String, ?pathP:String):Bool {
		#if sys
		DiffConfig.AUTO_APPLY_NON_CONFLICTED_CHANGES = true;
		DiffConfig.USE_GREEDY_MERGE_MAGIC_RESOLVE = false;
		DiffConfig.USE_PATIENCE_ALG = false;

		var base:String = sys.io.File.getContent(baseO);
		var current:String = sys.io.File.getContent(currentA);
		var other:String = sys.io.File.getContent(otherB);

		var viewer = new MergeThreesideViewer([current, base, other], base);
		viewer.rediff(false);

		var git = new GitDiff([current, viewer.myModel.getDocument(), other], viewer.myAllMergeChanges);
		var s = git.formatDiff();

		var output = sys.io.File.write(currentA);
		output.writeString(s);
		output.flush();
		output.close();

		return viewer.getChanges().length == 0;
		#end

		return false;
	}
}
