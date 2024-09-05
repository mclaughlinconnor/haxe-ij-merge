import util.PushLineUntil.pushLinesUntil;
import diff.util.ThreeSide;
import diff.fragments.TextMergeChange;

class GitDiff {
	private static final LEFT_MARKER = "<<<<<<< ours\n";
	private static final PRE_BASE_MARKER = "||||||| base\n";
	private static final POST_BASE_MARKER = "=======\n";
	private static final RIGHT_MARKER = ">>>>>>> theirs\n";

	private final myChanges:Array<TextMergeChange>;
	private final myLines:Array<Array<String>>;

	private var currentLine:Int = 0;

	public function new(files:Array<String>, changes:Array<TextMergeChange>) {
		myChanges = changes;
		myLines = files.map(t -> t.split("\n"));
	}

	public function formatDiff():String {
		var formattedString = new StringBuf();
		var baseSide = ThreeSide.fromEnum(ThreeSideEnum.BASE);
		var baseLines = myLines[baseSide.getIndex()];

		for (change in myChanges) {
			var changeStartLine = change.getStartLineA();

			if (currentLine < changeStartLine) {
				currentLine = pushLinesUntil(formattedString, baseLines, currentLine, changeStartLine);
			}

			if (change.isResolvedA()) {
				currentLine = pushLinesUntil(formattedString, baseLines, changeStartLine, change.getEndLineA());
			} else {
				formattedString.add(createConflictHunk(change));
			}
		}

		currentLine = pushLinesUntil(formattedString, baseLines, currentLine, baseLines.length, false);

		return formattedString.toString();
	}

	private function createConflictHunk(change:TextMergeChange):String {
		var hunk = new StringBuf();
		hunk.add(LEFT_MARKER);

		var sideEnum = ThreeSideEnum.LEFT;
		var side = ThreeSide.fromEnum(sideEnum);
		var start = change.getStartLineB(sideEnum);
		var end = change.getEndLineB(side);

		currentLine = pushLinesUntil(hunk, myLines[side.getIndex()], start, end);

		hunk.add(PRE_BASE_MARKER);

		sideEnum = ThreeSideEnum.BASE;
		side = ThreeSide.fromEnum(sideEnum);
		start = change.getStartLineB(sideEnum);
		end = change.getEndLineB(side);

		currentLine = pushLinesUntil(hunk, myLines[side.getIndex()], start, end);

		hunk.add(POST_BASE_MARKER);

		sideEnum = ThreeSideEnum.RIGHT;
		side = ThreeSide.fromEnum(sideEnum);
		start = change.getStartLineB(sideEnum);
		end = change.getEndLineB(side);

		currentLine = pushLinesUntil(hunk, myLines[side.getIndex()], start, end);

		hunk.add(RIGHT_MARKER);

		return hunk.toString();
	}
}
