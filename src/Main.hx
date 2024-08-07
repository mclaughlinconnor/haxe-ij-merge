import diff.comparison.MergeResolveUtil;
import diff.merge.MergeThreesideViewer;
import diff.util.ThreeSide;
import config.DiffConfig;

class Main {
	static public function main():Void {
		trace("Loaded haxe-ij-merge");
	}
}

@:expose
class API {
	static public function resolve(left, middle, right, applyNonConflicted = false, greedy = false, patience = false, conflicts = false):Array<String> {
		DiffConfig.AUTO_APPLY_NON_CONFLICTED_CHANGES = applyNonConflicted;
		DiffConfig.USE_GREEDY_MERGE_MAGIC_RESOLVE = greedy;
		DiffConfig.USE_PATIENCE_ALG = patience;

		var viewer = new MergeThreesideViewer([left, middle, right], middle);
		viewer.rediff(false);

		if (conflicts) {
			viewer.applyResolvableConflictedChanges();
		}

		var finalMergedText = viewer.myModel.getDocument();

		var diff = new Diff(viewer.myAllMergeChanges);

		var formattedLeft = diff.formatSide(left, ThreeSideEnum.LEFT);
		var formattedMiddle = diff.formatSide(finalMergedText, ThreeSideEnum.BASE);
		var formattedRight = diff.formatSide(right, ThreeSideEnum.RIGHT);

		return [finalMergedText, formattedLeft, formattedMiddle, formattedRight];
	}

	#if js
	static public function decorate():Void {
		DiffDecorations.decorate();
	}
	#end
}
