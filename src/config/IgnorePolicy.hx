package config;

import diff.comparison.ComparisonPolicy;

enum IgnorePolicyEnum {
	DEFAULT;
	TRIM_WHITESPACES;
	IGNORE_WHITESPACES;
	IGNORE_WHITESPACES_CHUNKS;
	FORMATTING;
}

class IgnorePolicy {
	private var myKey:IgnorePolicyEnum;

	// @NotNull @PropertyKey(resourceBundle = DiffBundle.BUNDLE) String textKey
	public function new(key:IgnorePolicyEnum) {
		this.myKey = key;
	}

	// public function getText():String {
	// 	return DiffBundle.message(myTextKey);
	// }

	public function getComparisonPolicyA():ComparisonPolicy {
    return IgnorePolicy.getComparisonPolicyB(myKey);
	}

	public static function getComparisonPolicyB(ignorePolicy:IgnorePolicyEnum):ComparisonPolicy {
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
