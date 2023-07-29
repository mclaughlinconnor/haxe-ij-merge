// Copyright 2000-2021 JetBrains s.r.o. and contributors. Use of this source code is governed by the Apache 2.0 license.
package iterators;

import exceptions.UnsupportedOperationException;
import exceptions.NoSuchElementException;

/**
 * Consider using {@link com.google.common.collect.Iterators#peekingIterator(Iterator)} instead.
 */
class PeekableIteratorWrapper<T> implements PeekableIterator<T> {
	private var myIterator:Iterator<T>;

	private var myValue:Null<T> = null;

	private var myValidValue:Bool = false;

	public function new(values:Iterable<T>):Void {
		this.myIterator = values.iterator();
		this.advance();
	}

	public function hasNext():Bool {
		return myValidValue;
	}

	public function next():T {
		if (myValidValue) {
			var save:T = myValue;
			advance();
			return save;
		}

		throw new NoSuchElementException('');
	}

	public function peek():T {
		if (myValidValue) {
			return myValue;
		}
		throw new NoSuchElementException('');
	}

	public function remove():Void {
		throw new UnsupportedOperationException('');
	}

	private function advance():Void {
		this.myValidValue = this.myIterator.hasNext();
		this.myValue = myValidValue ? this.myIterator.next() : null;
	}
}
