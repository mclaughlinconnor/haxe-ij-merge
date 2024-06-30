package diff.util;

enum TextDiffType {
  INSERTED;
  DELETED ;
  MODIFIED;
  CONFLICT;
  //
  // @NotNull
  // String getName();
  //
  // @NotNull
  // Color getColor(@Nullable Editor editor);
  //
  // @NotNull
  // Color getIgnoredColor(@Nullable Editor editor);
  //
  // @Nullable
  // Color getMarkerColor(@Nullable Editor editor);
}

