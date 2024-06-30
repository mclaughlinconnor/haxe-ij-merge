package diff.tools.util.base;

import diff.comparison.InnerFragmentsPolicy;

enum HighlightPolicyEnum {
	BY_LINE;
	BY_WORD;
	BY_WORD_SPLIT;
	BY_CHAR;
	DO_NOT_HIGHLIGHT;
}

class HighlightPolicy {
	private final myKey:HighlightPolicyEnum;

	public function new(key:HighlightPolicyEnum) {
		myKey = key;
	}

	// public function getText(): String  {
	//   return DiffBundle.message(myTextKey);
	// }

	public function isShouldCompare():Bool {
		return this.myKey != DO_NOT_HIGHLIGHT;
	}

	public function isFineFragments():Bool {
		return getFragmentsPolicy() != InnerFragmentsPolicy.NONE;
	}

	public function isShouldSquash():Bool {
		return this.myKey != BY_WORD_SPLIT;
	}

	public function getHighlightPolicy():HighlightPolicyEnum {
    return myKey;
  }

	public function getFragmentsPolicy():InnerFragmentsPolicy {
		switch (myKey) {
			case BY_WORD:
				return InnerFragmentsPolicy.WORDS;
			case BY_WORD_SPLIT:
				return InnerFragmentsPolicy.WORDS;
			case BY_CHAR:
				return InnerFragmentsPolicy.CHARS;
			case BY_LINE:
				return InnerFragmentsPolicy.NONE;
			case DO_NOT_HIGHLIGHT:
				return InnerFragmentsPolicy.NONE;
		};
	}
}
