/*
 * Copyright 2000-2019 JetBrains s.r.o.
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

package ds;

/**
 * Simple value wrapper.
 *
 * @param <T> Value type.
 */
@:generic
class Ref<T> {
	private var myValue:T;

	public function new(?value:Null<T>) {
		if (value != null) {
			myValue = value;
		}
	}

	public function isNull():Bool {
		return myValue == null;
	}

	public function get():T {
		return myValue;
	}

	public function set(?value:Null<T>):Void {
		myValue = value;
	}

	public function setIfNull(?value:Null<T>):Bool {
		var result:Bool = myValue == null && value != null;
		if (result) {
			myValue = value;
		}
		return result;
	}
}

 // Haxe doesn't support generic statics
@:generic
function create<S>(value:Null<S>):Ref<S> {
  if (value != null) {
    return new Ref<S>(value);
  }
  return new Ref();
}

@:generic
function deref<S>(ref:Null<Ref<S>>):S {
  return ref == null ? null : ref.get();
}
