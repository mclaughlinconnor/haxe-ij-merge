/**
	Multi-line comments for documentation.
**/

import diff.merge.MergeThreesideViewer;
import diff.comparison.MergeResolveUtil;

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

	static public function compareThreesideMerge(left, middle, right):String {
		left = "1 ======\ninsert left\n2 ======\nremove right\n3 ======\nnew both\n4 ======\nmodify both\n5 ======\nmodify\n6 ======\n7 ======\n8 ======\n";
		right = "1 ======\n2 ======\n3 ======\nnew both\n4 ======\nmodify both\n5 ======\nmodify right\n6 ======\n7 ======\nmodify\n8 ======\n";
		middle = "1 ======\n2 ======\nremove right\n3 ======\n4 ======\nmodify\n5 ======\nmodify\n6 ======\n7 ======\ndelete modify\n8 ======\n";

		var expected = "1 ======\ninsert left\n2 ======\n3 ======\nnew both\n4 ======\nmodify both\n5 ======\nmodify right\n6 ======\n7 ======\ndelete modify\n8 ======\n";

		var viewer = new MergeThreesideViewer([left, middle, right], middle);
		viewer.rediff(false);
		trace(viewer.myModel.getDocument() == expected);
		return viewer.myModel.getDocument();
	}
}
