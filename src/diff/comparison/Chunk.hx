package diff.comparison;

import util.Hashable;

abstract class Chunk implements Hashable {
	abstract public function equals(a: Chunk):Bool;

	abstract public function getContent():String;
}
