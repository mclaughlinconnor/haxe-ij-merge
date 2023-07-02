class IgnorePolicy {
	private var myTextKey:String;

	static public var DEFAULT:String = "option.ignore.policy.none";
	static public var TRIM_WHITESPACES:String = "option.ignore.policy.trim";
	static public var IGNORE_WHITESPACES:String = "option.ignore.policy.whitespaces";
	static public var IGNORE_WHITESPACES_CHUNKS:String = "option.ignore.policy.whitespaces.empty.lines";
	static public var FORMATTING:String = "option.ignore.policy.formatting";

	// @NotNull @PropertyKey(resourceBundle = DiffBundle.BUNDLE) String textKey
	public function IgnorePolicy(textKey:String) {
		this.myTextKey = textKey;
	}

	public function getText():String {
		return DiffBundle.message(myTextKey);
	}

	public function getComparisonPolicy(ignorePolicy:IgnorePolicy):ComparisonPolicy {
		var policy = ComparisonPolicy.DEFAULT;
		switch (IgnorePolicy) {
			case FORMATTING:
				policy = ComparisonPolicy.DEFAULT;
			case TRIM_WHITESPACES:
				policy = ComparisonPolicy.TRIM_WHITESPACES;
			case IGNORE_WHITESPACES | IGNORE_WHITESPACES_CHUNKS:
				policy = ComparisonPolicy.IGNORE_WHITESPACES;
		};
	}

	public function isShouldTrimChunks(ignorePolicy:IgnorePolicy):Bool {
		return ignorePolicy == this.IGNORE_WHITESPACES_CHUNKS;
	}
}
