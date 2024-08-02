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
	static public function merge(left, middle, right):String {
		return MergeResolveUtil.tryResolve(left, middle, right);
	}

	static public function greedyMerge(left, middle, right):String {
		return MergeResolveUtil.tryGreedyResolve(left, middle, right);
	}

	static public function applyResolvableConflictedChanges(left, middle, right):Array<String> {
		var viewer = new MergeThreesideViewer([left, middle, right], middle);
		viewer.rediff(false);
		viewer.applyResolvableConflictedChanges();

		var finalMergedText = viewer.myModel.getDocument();

		var diff = new Diff(viewer.myAllMergeChanges);

		var formattedLeft = diff.formatSide(left, ThreeSideEnum.LEFT);
		var formattedMiddle = diff.formatSide(finalMergedText, ThreeSideEnum.BASE);
		var formattedRight = diff.formatSide(right, ThreeSideEnum.RIGHT);

		return [finalMergedText, formattedLeft, formattedMiddle, formattedRight];
	}

	static public function diff(left, middle, right):Array<String> {
		DiffConfig.AUTO_APPLY_NON_CONFLICTED_CHANGES = false;
		var viewer = new MergeThreesideViewer([left, middle, right], middle);
		viewer.rediff(false);

		var finalMergedText = viewer.myModel.getDocument();

		var diff = new Diff(viewer.myAllMergeChanges);

		var formattedLeft = diff.formatSide(left, ThreeSideEnum.LEFT);
		var formattedMiddle = diff.formatSide(finalMergedText, ThreeSideEnum.BASE);
		var formattedRight = diff.formatSide(right, ThreeSideEnum.RIGHT);

		return [finalMergedText, formattedLeft, formattedMiddle, formattedRight];
	}

	static public function resolveNonConflicting(left, middle, right):Array<String> {
		DiffConfig.AUTO_APPLY_NON_CONFLICTED_CHANGES = true;
		var viewer = new MergeThreesideViewer([left, middle, right], middle);
		viewer.rediff(false);

		var finalMergedText = viewer.myModel.getDocument();

		var diff = new Diff(viewer.myAllMergeChanges);

		var formattedLeft = diff.formatSide(left, ThreeSideEnum.LEFT);
		var formattedMiddle = diff.formatSide(finalMergedText, ThreeSideEnum.BASE);
		var formattedRight = diff.formatSide(right, ThreeSideEnum.RIGHT);

		return [finalMergedText, formattedLeft, formattedMiddle, formattedRight];
	}

	static public function test():String {
		var left = "1 ======\ninsert left\n2 ======\nremove right\n3 ======\nnew both\n4 ======\nmodify both\n5 ======\nmodify\n6 ======\n7 ======\n8 ======\n";
		var right = "1 ======\n2 ======\n3 ======\nnew both\n4 ======\nmodify both\n5 ======\nmodify right\n6 ======\n7 ======\nmodify\n8 ======\n";
		var middle = "1 ======\n2 ======\nremove right\n3 ======\n4 ======\nmodify\n5 ======\nmodify\n6 ======\n7 ======\ndelete modify\n8 ======\n";

		var expected = "1 ======\ninsert left\n2 ======\n3 ======\nnew both\n4 ======\nmodify both\n5 ======\nmodify right\n6 ======\n7 ======\ndelete modify\n8 ======\n";

		var viewer = new MergeThreesideViewer([left, middle, right], middle);
		viewer.rediff(false);
		trace(viewer.myModel.getDocument() == expected);
		return viewer.myModel.getDocument();
	}

	#if js
	static public function decorate():Void{
    DiffDecorations.decorate();
  }
	#end
}
