/*
 * Copyright 2000-2017 JetBrains s.r.o.
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

import diff.util.ThreeSide;
import ds.TextRange;

class MergeInnerDifferences {
  private final myLeft: Array<TextRange> ;
  private final myBase: Array<TextRange> ;
  private final myRight: Array<TextRange> ;

  public function new(
       left: Array<TextRange>,  base: Array<TextRange>,  right: Array<TextRange>) {
    myLeft = left;
    myBase = base;
    myRight = right;
  }

  /**
   * NB: ranges might overlap and might be not in order
   */
  public function get(side: ThreeSide ): Array<TextRange>  {
    return side.selectA(myLeft, myBase, myRight);
  }
}

