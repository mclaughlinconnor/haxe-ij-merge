// Copyright 2000-2021 JetBrains s.r.o. and contributors. Use of this source code is governed by the Apache 2.0 license.
interface LCSBuilder {
	public function addEqual(length:Int):Void;
	public function addChange(first:Int, second:Int):Void;
}
