// Copyright 2000-2021 JetBrains s.r.o. and contributors. Use of this source code is governed by the Apache 2.0 license.

class Diff {
	static public function buildChangesA(before:String, after:String):Change {
		return buildChangesB(splitLines(before), splitLines(after));
	}

	static public function splitLines(s:String):Array<String> {
		return s.length == 0 ? [""] : LineTokenizer.tokenizeB(s, false, false);
	}

	@:generic
	public static function buildChangesB<T>(objects1:Array<T>, objects2:Array<T>):Change {
		// Old variant of enumerator worked incorrectly with null values.
		// This check is to ensure that the corrected version does not Introduce bugs.
		// for (anObjects1 in objects1) {
		// 	assert anObjects1 != null;
		// }
		// for (anObjects2 in objects2) {
		// 	assert anObjects2 != null;
		// }

		final startShift:Int = getStartShiftA(objects1, objects2);
		final endCut:Int = getEndCutA(objects1, objects2, startShift);

		var changeRef:Ref<Change> = doBuildChangesFast(objects1.length, objects2.length, startShift, endCut);
		if (changeRef != null) {
			return changeRef.get();
		}

		var trimmedLength:Int = objects1.length + objects2.length - 2 * startShift - 2 * endCut;
		var enumerator:Enumerator<T> = new Enumerator(trimmedLength);
		var Ints1:Array<Int> = enumerator.enumerate(objects1, startShift, endCut);
		var Ints2:Array<Int> = enumerator.enumerate(objects2, startShift, endCut);
		return doBuildChanges(Ints1, Ints2, new ChangeBuilder(startShift));
	}

	static public function buildChangesC(array1:Array<Int>, array2:Array<Int>):Change {
		final startShift:Int = getStartShiftA(array1, array2);
		final endCut:Int = getEndCut(array1, array2, startShift);

		var changeRef:Ref<Change> = doBuildChangesFast(array1.length, array2.length, startShift, endCut);
		if (changeRef != null) {
			return changeRef.get();
		}

		var copyArray:Bool = startShift != 0 || endCut != 0;
		var Ints1:Array<Int> = copyArray ? array1.slice(startShift, array1.length - endCut) : array1;
		var Ints2:Array<Int> = copyArray ? array2.slice(startShift, array2.length - endCut) : array2;
		return doBuildChanges(Ints1, Ints2, new ChangeBuilder(startShift));
	}

	private static function doBuildChangesFast(length1:Int, length2:Int, startShift:Int, endCut:Int):Ref<Change> {
		var trimmedLength1:Int = length1 - startShift - endCut;
		var trimmedLength2:Int = length2 - startShift - endCut;
		if (trimmedLength1 != 0 && trimmedLength2 != 0) {
			return null;
		}
		var change:Change = trimmedLength1 != 0
			|| trimmedLength2 != 0 ? new Change(startShift, startShift, trimmedLength1, trimmedLength2, null) : null;

		return new Ref(change);
	}

	private static function doBuildChanges(Ints1:Array<Int>, Ints2:Array<Int>, builder:ChangeBuilder):Change {
		var reindexer:Reindexer = new Reindexer(); // discard unique elements, that have no chance to be matched
		var discarded:Array<Array<Int>> = reindexer.discardUnique(Ints1, Ints2);

		if (discarded[0].length == 0 && discarded[1].length == 0) {
			// assert trimmedLength > 0
			builder.addChange(Ints1.length, Ints2.length);
			return builder.getFirstChange();
		}
		var changes:Array<BitSet>;
		if (DiffConfig.USE_PATIENCE_ALG) {
			var patienceIntLCS:PatienceIntLCS = new PatienceIntLCS(discarded[0], discarded[1]);
			patienceIntLCS.execute();
			changes = patienceIntLCS.getChanges();
		} else {
			try {
				var IntLCS:MyersLCS = new MyersLCS(discarded[0], discarded[1]);
				IntLCS.executeWithThreshold();
				changes = IntLCS.getChanges();
			} catch (e:FilesTooBigForDiffException) {
				var patienceIntLCS:PatienceIntLCS = new PatienceIntLCS(discarded[0], discarded[1]);

				patienceIntLCS.execute(true);
				changes = patienceIntLCS.getChanges();
				trace("Successful fallback to patience diff");
			}
		}
		reindexer.reindex(changes, builder);
		return builder.getFirstChange();
	}

	@:generic
	static private function getStartShiftA<T>(o1:Array<T>, o2:Array<T>):Int {
		final size:Int = Std.int(Math.min(o1.length, o2.length));
		var idx:Int = 0;

		for (i in 0...size) {
			if (o1[i] != o2[i])
				break;
			++idx;
		}
		return idx;
	}

	@:generic
	static private function getEndCutA<T>(o1:Array<T>, o2:Array<T>, startShift:Int):Int {
		final size:Int = Std.int(Math.min(o1.length, o2.length) - startShift);
		var idx:Int = 0;

		for (i in 0...size) {
			if (o1[o1.length - i - 1] != o2[o2.length - i - 1]) {
				break;
			}
			++idx;
		}
		return idx;
	}

	@:generic
	static private function getStartShiftB<T>(o1:Array<T>, o2:Array<T>):Int {
		final size:Int = Std.int(Math.min(o1.length, o2.length));
		var idx:Int = 0;
		for (i in 0...size) {
			if (o1[i] != o2[i])
				break;
			++idx;
		}
		return idx;
	}

	@:generic
	static private function getEndCutB<T>(o1:Array<T>, o2:Array<T>, startShift:Int):Int {
		final size:Int = Std.int(Math.min(o1.length, o2.length) - startShift);
		var idx:Int = 0;
		for (i in 0...size) {
			if (o1[o1.length - i - 1] != o2[o2.length - i - 1])
				break;
			++idx;
		}
		return idx;
	}

	static public function translateLineA(before:String, after:String, line:Int, approximate:Bool):Int {
		var strings1:Array<String> = LineTokenizer.tokenizeA(before, false);
		var strings2:Array<String> = LineTokenizer.tokenizeA(after, false);
		if (approximate) {
			strings1 = trim(strings1);
			strings2 = trim(strings2);
		}
		var change:Change = buildChangesB(strings1, strings2);

		return translateLineC(change, line, approximate);
	}

	static private function trim(lines:Array<String>):Array<String> {
		var result:Array<String> = [for (i in 0...lines.length) ""];

		for (i in 0...lines.length) {
			result[i] = StringTools.trim(lines[i]);
		}
		return result;
	}

	/**
	 * Tries to translate given line that poInted to the text before change to the line that poInts to the same text after the change.
	 *
	 * @param change    target change
	 * @param line      target line before change
	 * @return          translated line if the processing is ok; negative value otherwise
	 */
	static public function translateLineB(change:Null<Change>, line:Int):Int {
		return translateLineC(change, line, false);
	}

	static public function translateLineC(change:Null<Change>, line:Int, approximate:Bool):Int {
		var result:Int = line;

		var currentChange:Change = change;
		while (currentChange != null) {
			if (line < currentChange.line0) {
				break;
			}
			if (line >= currentChange.line0 + currentChange.deleted) {
				result += currentChange.inserted - currentChange.deleted;
			} else {
				return approximate ? currentChange.line1 : -1;
			}
			currentChange = currentChange.link;
		}
		return result;
	}

	static public function linesDiff(lines1:Array<String>, lines2:Array<String>):Null<String> {
		var ch:Change = buildChangesB(lines1, lines2);
		if (ch == null) {
			return null;
		}

		var sb:StringBuilder = new StringBuilder();
		while (ch != null) {
			if (sb.length() != 0) {
				sb.append("====================").append("\n");
			}
			for (i in ch.line0...ch.line0 + ch.deleted) {
				sb.append('-').append(lines1[i]).append('\n');
			}
			for (i in ch.line1...ch.line1 + ch.inserted) {
				sb.append('+').append(lines2[i]).append('\n');
			}
			ch = ch.link;
		}
		return sb.toString();
	}
}

class Change {
	// todo remove. Return lists instead.

	/**
	 * Previous or next edit command.
	 */
	public var link:Change;

	/** # lines of file 1 changed here.  */
	public final inserted:Int;

	/** # lines of file 0 changed here.  */
	public final deleted:Int;

	/** Line number of 1st deleted line.  */
	public final line0:Int;

	/** Line number of 1st inserted line.  */
	public final line1:Int;

	/** Cons an additional entry onto the front of an edit script OLD.
		LINE0 and LINE1 are the first affected lines in the two files (origin 0).
		DELETED is the number of lines deleted here from file 0.
		INSERTED is the number of lines inserted here in file 1.

		If DELETED is 0 then LINE0 is the number of the line before
		which the insertion was done; vice versa for INSERTED and LINE1. */
	public function new(line0:Int, line1:Int, deleted:Int, inserted:Int, old:Null<Change>) {
		this.line0 = line0;
		this.line1 = line1;
		this.inserted = inserted;
		this.deleted = deleted;
		link = old;
		// System.err.prIntln(line0+","+line1+","+inserted+","+deleted);
	}

	public function toString():String {
		return "change[" + "inserted=" + inserted + ", deleted=" + deleted + ", line0=" + line0 + ", line1=" + line1 + "]";
	}

	public function toList():Array<Change> {
		var result:Array<Change> = new Array();
		var current:Change = this;
		while (current != null) {
			result.push(current);
			current = current.link;
		}
		return result;
	}
}

class ChangeBuilder implements LCSBuilder {
	private var myIndex1:Int = 0;
	private var myIndex2:Int = 0;
	private var myFirstChange:Change;
	private var myLastChange:Change;

	public function new(startShift:Int) {
		skip(startShift, startShift);
	}

	public function addChange(first:Int, second:Int):Void {
		var change:Change = new Change(myIndex1, myIndex2, first, second, null);
		if (myLastChange != null) {
			myLastChange.link = change;
		} else {
			myFirstChange = change;
		}
		myLastChange = change;
		skip(first, second);
	}

	private function skip(first:Int, second:Int):Void {
		myIndex1 += first;
		myIndex2 += second;
	}

	public function addEqual(length:Int):Void {
		skip(length, length);
	}

	public function getFirstChange():Change {
		return myFirstChange;
	}
}
