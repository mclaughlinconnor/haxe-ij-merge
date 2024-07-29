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

	// static public function compare(left, middle, right):String {
	// 	var diffProvider = new SimpleThreesideTextDiffProvider(ThreeSideDiffColors.MERGE_CONFLICT);
	// 	// TODO: needs to be `MergeLineFragmentsWithImportMetadata`
	// 	var fragments = diffProvider.compare(left, middle, right);
	//
	// 	var myAllMergeChanges:Array<TextMergeChange> = [];
	// 	// var contents:Array<DocumentContent> = myMergeRequest.getContents();
	// 	var contents:Array<String> = [left, middle, right];
	// 	var sequences:Array<String> = [];
	//
	// 	for (content in contents) {
	// 		// sequences.push(content.getDocument().getImmutableCharSequence());
	// 		sequences.push(content);
	// 	}
	//
	// 	// var importRange:MergeRange = null;
	// 	// if (getTextSettings().isAutoResolveImportConflicts()) {
	// 	// 	initPsiFiles();
	// 	// 	importRange = MergeImportUtil.getImportMergeRange(myProject, myPsiFiles);
	// 	// }
	//
	// 	var lineOffsets:Array<LineOffsets> = sequences.map(function(seq) {
	// 		return LineOffsetsUtil.createB(seq);
	// 	});
	//
	// 	var conflictTypes:Array<MergeConflictType> = fragments.map(function(fragment) {
	// 		// var conflictTypes: List<MergeConflictType>  = fragments.getFragments().map(function(fragment) {
	// 		return MergeRangeUtil.getLineMergeType(fragment, sequences, lineOffsets, IgnorePolicy.getComparisonPolicyB(IgnorePolicyEnum.DEFAULT));
	// 	});
	//
	// 	for (index in 0...fragments.length) {
	// 		var fragment:MergeLineFragment = fragments[index];
	// 		var conflictType:MergeConflictType = conflictTypes[index];
	//
	// 		// var isInImportRange:Bool = fragmentsWithMetadata.isIndexInImportRange(index);
	// 		var isInImportRange = false;
	// 		//     /* <b> You are currently creating an array of changes so that you can use the loop below to apply them </b> */
	// 		var change:TextMergeChange = new TextMergeChange(index, isInImportRange, fragment, conflictType /*, myTextMergeViewer*/);
	//
	// 		myAllMergeChanges.push(change);
	// 		// onChangeAdded(change); // TODO: increment/decrement conflict counter. Only used for UI stuff
	// 	}
	//
	// 	var newRanges:Array<Any> = [];
	//
	// 	var myModel = new MyMergeModel(/*getProject(), */ middle, myAllMergeChanges, (_) -> {}, (_) -> {});
	//
	// 	var side = ThreeSideEnum.BASE;
	//
	// 	for (change in myAllMergeChanges) {
	// 		// TODO: result document should come as a param?
	// 		if (!MergeThreesideViewer.canResolveChangeAutomaticallyA(change, ThreeSide.fromEnum(side), contents, ""))
	// 			// return null;
	// 			continue;
	//
	// 		if (change.isConflict()) {
	// 			var texts:Array<String> = ThreeSide.map(function(it) {
	// 				return DiffUtil.getLinesContentA(it.selectC(contents), change.getStartLineB(ThreeSide.fromIndex(it.getIndex())), change.getEndLineB(it));
	// 			});
	//
	// 			var newContent:String = ComparisonMergeUtil.tryResolveConflict(texts[0], texts[1], texts[2]);
	// 			if (newContent == null) {
	// 				trace('Can\'t resolve conflicting change:\n"${texts[0]}"\n"${texts[1]}"\n"${texts[2]}"\n');
	// 				continue;
	// 				return null;
	// 			}
	//
	// 			var newContentLines:Array<String> = LineTokenizer.tokenizeA(newContent, false);
	// 			myModel.replaceChange(change.getIndex(), newContentLines);
	// 			if (!change.isResolvedA()) {
	// 				change.setResolved(Side.fromEnum(SideEnum.LEFT), true);
	// 				change.setResolved(Side.fromEnum(SideEnum.RIGHT), true);
	// 			}
	// 			newRanges.push(new LineRange(myModel.getLineStart(change.getIndex()), myModel.getLineEnd(change.getIndex())));
	// 		} else {
	// 			var masterSide:SideEnum = ThreeSide.fromEnum(side)
	// 				.selectA(SideEnum.LEFT, change.isChangeA(Side.fromEnum(SideEnum.LEFT)) ? SideEnum.LEFT : SideEnum.RIGHT, SideEnum.RIGHT);
	// 			// TODO: needs logic like below
	// 			// newRanges.push(replaceChange(change, masterSide, false));
	// 		}
	// 	}
	//
	// 	trace(fragments);
	// 	return MergeResolveUtil.tryGreedyResolve(left, middle, right);
	// }

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
