package diff.util;

enum ThreeSideDiffColors {
	/**
	 * Default value, for merge conflict: "Left <- Base -> Right"
	 * "A - B - C" is Conflict
	 * "AB - B - AB" is Addition
	 * "B - B - AB" is Addition
	 * "AB - B - B" is Addition
	 * "B - AB - AB" is Deletion
	 */
	MERGE_CONFLICT;

	/**
	 * For result of a past merge: "Left -> Merged <- Right". Same as MERGE_CONFLICT, with inverted "Insertions" and "Deletions".
	 * "A - B - C" is Conflict
	 * "AB - B - AB" is Deletion
	 * "B - B - AB" is Deletion
	 * "AB - B - B" is Deletion
	 * "B - AB - AB" is Addition
	 */
	MERGE_RESULT;

	/**
	 * For intermediate state: "Head -> Staged -> Local"
	 * "A - B - C" is Modification
	 * "AB - B - AB" is Modification
	 * "B - B - AB" is Addition
	 * "AB - B - B" is Deletion
	 * "B - AB - AB" is Addition
	 */
	LEFT_TO_RIGHT;
}
