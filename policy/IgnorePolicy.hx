package policies;

import diff.comparison.ComparisonPolicy;

enum IgnorePolicyEnum {
	DEFAULT;
	TRIM_WHITESPACES;
	IGNORE_WHITESPACES;
	IGNORE_WHITESPACES_CHUNKS;
	FORMATTING;
}

class IgnorePolicy {
	private var myTextKey:String;

	// @NotNull @PropertyKey(resourceBundle = DiffBundle.BUNDLE) String textKey
	public function IgnorePolicy(textKey:String) {
		this.myTextKey = textKey;
	}

	public function getText():String {
		return DiffBundle.message(myTextKey);
	}

	public function getComparisonPolicy(ignorePolicy:IgnorePolicyEnum):ComparisonPolicy {
		var policy:ComparisonPolicy;
		switch (ignorePolicy) {
			case IgnorePolicyEnum.FORMATTING:
				policy = ComparisonPolicy.DEFAULT;
			case TRIM_WHITESPACES:
				policy = ComparisonPolicy.TRIM_WHITESPACES;
			case IGNORE_WHITESPACES | IGNORE_WHITESPACES_CHUNKS:
				policy = ComparisonPolicy.IGNORE_WHITESPACES;
			default:
				policy = ComparisonPolicy.DEFAULT;
		};

		return policy;
	}

	public function isShouldTrimChunks(ignorePolicy:IgnorePolicyEnum):Bool {
		return ignorePolicy == IgnorePolicyEnum.IGNORE_WHITESPACES_CHUNKS;
	}
}
