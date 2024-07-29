/*
 * Copyright 2000-2015 JetBrains s.r.o.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package diff.tools.util.text;

class LineRange {
  // private static final Logger LOG = Logger.getInstance(LineRange.class);

  public final start: Int ;
  public final end: Int ;

  public function new(start: Int , end: Int ) {
    this.start = start;
    this.end = end;

    // if (start > end) {
    //   LOG.error("LineRange is invalid: " + toString());
    // }
  }

  public function contains(start: Int , end: Int ): Bool {
    return this.start <= start && this.end >= end;
  }

	// public function equals(o:InlineChunk):Bool {
	// 	if (this == o) {
	// 		return true;
	// 	}
	//
	// 	if (o == null || Type.getClassName(Type.getClass(o)) != Type.getClassName(Type.getClass(this))) {
	// 		return false;
	// 	}
	//
	// 	return true;
	// }

  public function equals(o:LineRange): Bool {
    if (this == o){ return true;
    }
    if (o == null || Type.getClassName(Type.getClass(o)) != Type.getClassName(Type.getClass(this))) {
      return false;
    }

    if (start != o.start) return false;
    if (end != o.end) return false;

    return true;
  }

  public function hashCode(): Int {
    var result: Int  = start;
    result = 31 * result + end;
    return result;
  }

  public function toString(): String {
    return "[" + start + ", " + end + ")";
  }

  public function isEmpty(): Bool {
    return start == end;
  }
}

