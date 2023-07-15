// Copyright 2000-2021 JetBrains s.r.o. and contributors. Use of this source code is governed by the Apache 2.0 license.
class FairDiffIterableWrapper extends FairDiffIterable {
  private final myIterable: DiffIterable ;

  public function new (
  iterable:DiffIterable) {
    myIterable = iterable;
  }

  public function getLength1(): Int {
    return myIterable.getLength1();
  }

  public function getLength2(): Int {
    return myIterable.getLength2();
  }

	public function changes():Iterator<Range> {
    return myIterable.changes();
  }

	public function unchanged():Iterator<Range> {
    return myIterable.unchanged();
  }
}

