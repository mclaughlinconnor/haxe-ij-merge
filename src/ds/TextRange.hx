// Copyright 2000-2023 JetBrains s.r.o. and contributors. Use of this source code is governed by the Apache 2.0 license.
package ds;

/**
 * A text range defined by start and end (exclusive) offset.
 *
 * @see ProperTextRange
 * @see com.Intellij.util.text.TextRangeUtil
 */
class TextRange {
	static public final EMPTY_RANGE:TextRange = new TextRange(0, 0);
	static public final EMPTY_ARRAY:Array<TextRange> = [];

	private final myStartOffset:Int;
	private final myEndOffset:Int;

	//  /**
	//   * @see #create(Int, Int)
	//   * @see #from(Int, Int)
	//   * @see #allOf(String)
	//   */
	//  public function new TextRange(
	// startOffset:Int,endOffset:Int) {
	//    this(startOffset, endOffset, true);
	//  }

	/**
	 * @param checkForProperTextRange {@code true} if offsets should be checked by {@link #assertProperRange(Int, Int, Object)}
	 * @see UnfairTextRange
	 */
	public function new(startOffset:Int, endOffset:Int) {
		myStartOffset = startOffset;
		myEndOffset = endOffset;
	}

	public final function getStartOffset():Int {
		return myStartOffset;
	}

	public final function getEndOffset():Int {
		return myEndOffset;
	}
	//
	// public final function getLength():Int {
	// 	return myEndOffset - myStartOffset;
	// }
	// public boolean contains(@NotNull TextRange range) {
	//   return contains((Segment)range);
	// }
	//
	// public boolean contains(@NotNull Segment range) {
	//   return containsRange(range.getStartOffset(), range.getEndOffset());
	// }
	//
	// public boolean containsRange(Int startOffset, Int endOffset) {
	//   return getStartOffset() <= startOffset && endOffset <= getEndOffset();
	// }
	//
	// public static boolean containsRange(@NotNull Segment outer, @NotNull Segment inner) {
	//   return outer.getStartOffset() <= inner.getStartOffset() && inner.getEndOffset() <= outer.getEndOffset();
	// }
	//
	// public boolean containsOffset(Int offset) {
	//   return myStartOffset <= offset && offset <= myEndOffset;
	// }
	//
	// @Override
	// public String toString() {
	//   return "(" + myStartOffset + "," + myEndOffset + ")";
	// }
	//
	// public boolean contains(Int offset) {
	//   return myStartOffset <= offset && offset < myEndOffset;
	// }
	// @NotNull
	// @Contract(pure = true)
	// public String substring(@NotNull String str) {
	//   return str.substring(myStartOffset, myEndOffset);
	// }
	//
	public function subSequence(str:String):String {
		return str.substring(myStartOffset, myEndOffset);
	}

	//
	// @NotNull
	// public TextRange cutOut(@NotNull TextRange subRange) {
	//   if (subRange.getStartOffset() > getLength()) {
	//     throw new IllegalArgumentException("SubRange: " + subRange + "; this=" + this);
	//   }
	//   if (subRange.getEndOffset() > getLength()) {
	//     throw new IllegalArgumentException("SubRange: " + subRange + "; this=" + this);
	//   }
	//   assertProperRange(subRange);
	//   return new TextRange(myStartOffset + subRange.getStartOffset(),
	//                        Math.min(myEndOffset, myStartOffset + subRange.getEndOffset()));
	// }
	//
	// @NotNull
	// public TextRange shiftRight(Int delta) {
	//   if (delta == 0) return this;
	//   return new TextRange(myStartOffset + delta, myEndOffset + delta);
	// }
	//
	// @NotNull
	// public TextRange shiftLeft(Int delta) {
	//   if (delta == 0) return this;
	//   return new TextRange(myStartOffset - delta, myEndOffset - delta);
	// }
	//
	// @NotNull
	// public TextRange grown(Int lengthDelta) {
	//   if (lengthDelta == 0) {
	//     return this;
	//   }
	//   return from(myStartOffset, getLength() + lengthDelta);
	// }
	//
	// @Contract(pure = true)
	// @NotNull
	// public static TextRange from(Int offset, Int length) {
	//   return create(offset, offset + length);
	// }
	// @Contract(pure = true)
	// @NotNull
	// public static TextRange create(Int startOffset, Int endOffset) {
	//   return new TextRange(startOffset, endOffset);
	// }
	//
	// @NotNull
	// public static TextRange create(@NotNull Segment segment) {
	//   return create(segment.getStartOffset(), segment.getEndOffset());
	// }
	//
	// public static boolean areSegmentsEqual(@NotNull Segment segment1, @NotNull Segment segment2) {
	//   return segment1.getStartOffset() == segment2.getStartOffset()
	//          && segment1.getEndOffset() == segment2.getEndOffset();
	// }
	//
	// @NotNull
	// public String replace(@NotNull String original, @NotNull String replacement) {
	//   String beginning = original.substring(0, getStartOffset());
	//   String ending = original.substring(getEndOffset());
	//   return beginning + replacement + ending;
	// }
	//
	// public boolean Intersects(@NotNull TextRange textRange) {
	//   return Intersects((Segment)textRange);
	// }
	//
	// public boolean Intersects(@NotNull Segment textRange) {
	//   return Intersects(textRange.getStartOffset(), textRange.getEndOffset());
	// }
	//
	// public boolean Intersects(Int startOffset, Int endOffset) {
	//   return Math.max(myStartOffset, startOffset) <= Math.min(myEndOffset, endOffset);
	// }
	//
	// public boolean IntersectsStrict(@NotNull TextRange textRange) {
	//   return IntersectsStrict(textRange.getStartOffset(), textRange.getEndOffset());
	// }
	//
	// public boolean IntersectsStrict(Int startOffset, Int endOffset) {
	//   return Math.max(myStartOffset, startOffset) < Math.min(myEndOffset, endOffset);
	// }
	//
	// public TextRange Intersection(@NotNull TextRange range) {
	//   if (equals(range)) {
	//     return this;
	//   }
	//   Int newStart = Math.max(myStartOffset, range.getStartOffset());
	//   Int newEnd = Math.min(myEndOffset, range.getEndOffset());
	//   return isProperRange(newStart, newEnd) ? new TextRange(newStart, newEnd) : null;
	// }
	//
	// public boolean isEmpty() {
	//   return myStartOffset >= myEndOffset;
	// }
	//
	// @NotNull
	// public TextRange union(@NotNull TextRange textRange) {
	//   if (equals(textRange)) {
	//     return this;
	//   }
	//   return new TextRange(Math.min(myStartOffset, textRange.getStartOffset()), Math.max(myEndOffset, textRange.getEndOffset()));
	// }
	//
	// public boolean equalsToRange(Int startOffset, Int endOffset) {
	//   return startOffset == myStartOffset && endOffset == myEndOffset;
	// }
	//
	// @NotNull
	// public static TextRange allOf(@NotNull String s) {
	//   return new TextRange(0, s.length());
	// }
	//
	// public static void assertProperRange(@NotNull Segment range) throws AssertionError {
	//   assertProperRange(range, "");
	// }
	//
	// public static void assertProperRange(@NotNull Segment range, @NotNull Object message) throws AssertionError {
	//   assertProperRange(range.getStartOffset(), range.getEndOffset(), message);
	// }
	//
	// public static void assertProperRange(Int startOffset, Int endOffset, @NotNull Object message) {
	//   if (!isProperRange(startOffset, endOffset)) {
	//     throw new IllegalArgumentException("Invalid range specified: (" + startOffset + ", " + endOffset + "); " + message);
	//   }
	// }
	//
	// public static boolean isProperRange(Int startOffset, Int endOffset) {
	//   return startOffset <= endOffset && startOffset >= 0;
	// }
}
