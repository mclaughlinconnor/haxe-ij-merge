// Copyright 2000-2022 JetBrains s.r.o. and contributors. Use of this source code is governed by the Apache 2.0 license.
package config;

class DiffConfig {
	public static var USE_PATIENCE_ALG:Bool = false;
	public static var USE_GREEDY_MERGE_MAGIC_RESOLVE:Bool = true;
	public static var DELTA_THRESHOLD_SIZE:Int = 20000;
	public static var MAX_BAD_LINES:Int = 3; // Do not try to compare lines by-word after that many prior failures.
	public static var UNIMPORTANT_LINE_CHAR_COUNT:Int = 3; // Deprioritize short lines
	public static var AUTO_APPLY_NON_CONFLICTED_CHANGES:Bool = false;
}
