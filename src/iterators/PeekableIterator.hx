// Copyright 2000-2021 JetBrains s.r.o. and contributors. Use of this source code is governed by the Apache 2.0 license.
package iterators;

/**
 * An iterator with additional ability to {@link #peek()} the current element without moving the cursor.
 * <p>
 * Consider using {@link com.google.common.collect.PeekingIterator} instead.
 */
interface PeekableIterator<T> {
	public function hasNext():Bool;
	public function next():T;

	/**
	 * @return the current element.
	 * Upon iterator creation should return the first element.
	 * After {@link #hasNext()} returned false might throw {@link NoSuchElementException}.
	 */
	public function peek():T;
}
