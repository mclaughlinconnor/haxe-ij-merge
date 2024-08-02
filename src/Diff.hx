import diff.util.MergeConflictType;
import diff.util.ThreeSide;
import diff.fragments.TextMergeChange;

class Diff {
	private final DELETED_COLOUR = "#880000";
	private final INSERTED_COLOUR = "#008800";
	private final MODIFIED_COLOUR = "#000088";
	private final CONFLICT_COLOUR = "#884444";

	private final myChanges:Array<TextMergeChange>;

	private var currentLine:Int = 0;

	public function new(changes:Array<TextMergeChange>) {
		myChanges = changes;
	}

	public function formatSide(text:String, side:ThreeSideEnum):String {
		currentLine = 0;
		var lines = text.split("\n");
		var formattedString = new StringBuf();

		for (change in myChanges) {
			var start = change.getStartLineB(side);
			var end = change.getEndLineB(ThreeSide.fromEnum(side));

			pushLinesUntil(formattedString, lines, start);

			var type = change.getConflictType();
			var isThisSide = type.isChangeB(side);
			var prefix = "";
			var suffix = "";

			if (start == end) {
				formattedString.add(handleOtherSide(change));
			} else if (isThisSide) {
				var s = handleThisSide(change);
				prefix = s[0];
				suffix = s[1];
			}

			formattedString.add(prefix);
			pushLinesUntil(formattedString, lines, end);
			formattedString.add(suffix);
		}

		pushLinesUntil(formattedString, lines, lines.length);

		return formattedString.toString();
	}

	private function createColouredElement(element:String, colour:String, index:Int):String {
		return '<$element data-index=$index style="background-color:$colour;">';
	}

	private function createHr(colour:String, index:Int):String {
		return '<hr data-index=$index style="border: 2px solid $colour"; margin: 0;/>';
	}

	private function handleThisSide(change:TextMergeChange):Array<String> {
		var prefix:String;
		var suffix:String;

		var type = change.getConflictType();

		switch (type.getType()) {
			case MergeConflictTypeEnum.DELETED:
				prefix = createColouredElement('del', DELETED_COLOUR, change.getIndex());
				suffix = "</del>";
			case MergeConflictTypeEnum.INSERTED:
				prefix = createColouredElement('ins', INSERTED_COLOUR, change.getIndex());
				suffix = "</ins>";
			case MergeConflictTypeEnum.MODIFIED:
				prefix = createColouredElement('span', MODIFIED_COLOUR, change.getIndex());
				suffix = "</span>";
			case MergeConflictTypeEnum.CONFLICT:
				prefix = createColouredElement('span', CONFLICT_COLOUR, change.getIndex());
				suffix = "</span>";
		}

		return [prefix, suffix];
	}

	private function handleOtherSide(change:TextMergeChange) {
		var type = change.getConflictType();

		switch (type.getType()) {
			case(MergeConflictTypeEnum.DELETED):
				return "";
			case MergeConflictTypeEnum.INSERTED:
				return createHr(INSERTED_COLOUR, change.getIndex());
			case MergeConflictTypeEnum.MODIFIED:
				return createHr(MODIFIED_COLOUR, change.getIndex());
			case MergeConflictTypeEnum.CONFLICT:
				return createHr(CONFLICT_COLOUR, change.getIndex());
		}
	}

	private function pushLinesUntil(formattedString:StringBuf, lines:Array<String>, end:Int) {
		while (currentLine < end) {
			formattedString.add(lines[currentLine]);
			formattedString.add("\n");
			currentLine++;
		}
	}
}