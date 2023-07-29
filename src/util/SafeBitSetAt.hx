package util;

import thx.BitSet;

@:generic
class SafeBitSetAt {
  static public function safeAt(bs: BitSet, index  : Int) : Bool {
    if (index < 0 || index >= bs.length) {
      return false;
    }

    return bs.at(index);
  }
}
