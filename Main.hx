/**
	Multi-line comments for documentation.
**/

import diff.comparison.MergeResolveUtil;

class Main {
	static public function main():Void {
		// Single line comment
		trace("Hello World");

    var merge = MergeResolveUtil.tryResolve('Hello', 'hello', 'hello world');
    if (merge != null) {
      trace(merge);
    }
	}
}
