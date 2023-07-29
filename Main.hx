/**
	Multi-line comments for documentation.
**/

import diff.comparison.MergeResolveUtil;

class Main {
	static public function main():Void {
		trace("Loaded haxe-ij-merge");
	}
}

@:expose
class API {
  static public function merge(left, middle, right): String {
    return MergeResolveUtil.tryResolve(left, middle, right);
  }

  static public function greedyMerge(left, middle, right): String {
    return MergeResolveUtil.tryResolve(left, middle, right);
  }
}
