import diff.merge.MergeThreesideViewer;
import config.DiffConfig;

class MergeDriver {
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
