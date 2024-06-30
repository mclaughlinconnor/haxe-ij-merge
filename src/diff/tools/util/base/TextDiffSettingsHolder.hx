// Copyright 2000-2021 JetBrains s.r.o. and contributors. Use of this source code is governed by the Apache 2.0 license that can be found in the LICENSE file.
package diff.tools.util.base;

import diff.tools.util.base.HighlightingLevel.HighlightingLevelEnum;
import config.IgnorePolicy.IgnorePolicyEnum;
import diff.tools.util.base.HighlightPolicy.HighlightPolicyEnum;
import util.PersistentStateComponent;

// interface Disposable {
// 	function dispose():Void;
// }
//
// // @State(name = "TextDiffSettings", storages = [(Storage(value = DiffUtil.DIFF_CONFIG))], category = SettingsCategory.CODE)
// class TextDiffSettingsHolder extends PersistentStateComponent<State> {
// 	public function getSettings(place:Null<String>):TextDiffSettings {
// 		var placeKey:DiffPlaces = place != null ? place : DiffPlaces.DEFAULT;
// 		// var placeSettings = myState.PLACES_MAP.getOrPut(placeKey) { defaultPlaceSettings(placeKey) }
// 		return TextDiffSettings(myState.SHARED_SETTINGS, placeSettings, placeKey);
// 	}
//
// 	private function copyStateWithoutDefaults():State {
// 		var result = new State();
// 		result.SHARED_SETTINGS = myState.SHARED_SETTINGS;
// 		// result.PLACES_MAP = DiffUtil.trimDefaultValues(myState.PLACES_MAP) { defaultPlaceSettings(it) }
// 		return result;
// 	}
//
// 	private function defaultPlaceSettings(place:String):PlaceSettings {
// 		var settings = new PlaceSettings();
// 		if (place == DiffPlaces.CHANGES_VIEW) {
// 			settings.EXPAND_BY_DEFAULT = false;
// 			settings.SHOW_LINE_NUMBERS = false;
// 		}
// 		if (place == DiffPlaces.COMMIT_DIALOG) {
// 			settings.EXPAND_BY_DEFAULT = false;
// 		}
// 		if (place == DiffPlaces.VCS_LOG_VIEW) {
// 			settings.EXPAND_BY_DEFAULT = false;
// 		}
// 		if (place == DiffPlaces.VCS_FILE_HISTORY_VIEW) {
// 			settings.EXPAND_BY_DEFAULT = false;
// 		}
// 		return settings;
// 	}
//
// 	private var myState:State = new State();
//
// 	public override function getState():State {
// 		return copyStateWithoutDefaults();
// 	}
//
// 	override function loadState(state:State) {
// 		myState = state;
// 	}
// }

class SharedSettings {
	// Fragments settings
	var CONTEXT_RANGE:Int = 4;

	var MERGE_AUTO_APPLY_NON_CONFLICTED_CHANGES:Bool = false;
	var MERGE_AUTO_RESOLVE_IMPORT_CONFLICTS:Bool = false;
	var MERGE_LST_GUTTER_MARKERS:Bool = true;
	var ENABLE_ALIGNING_CHANGES_MODE:Bool = false;
	// var eventDispatcher:EventDispatcher<TextDiffSettings.Listener> = EventDispatcher.create(TextDiffSettings.Listener);

  public function new() {}
}

class PlaceSettings {
	// Diff settings
	public var HIGHLIGHT_POLICY:HighlightPolicyEnum = HighlightPolicyEnum.BY_WORD;
	public var IGNORE_POLICY:IgnorePolicyEnum = IgnorePolicyEnum.DEFAULT;

	// Editor settings
	var SHOW_WHITESPACES:Bool = false;
	var SHOW_LINE_NUMBERS:Bool = true;
	var SHOW_INDENT_LINES:Bool = false;
	var USE_SOFT_WRAPS:Bool = false;
	var HIGHLIGHTING_LEVEL:HighlightingLevelEnum = HighlightingLevelEnum.INSPECTIONS;
	var READ_ONLY_LOCK:Bool = true;

	// var BREADCRUMBS_PLACEMENT:BreadcrumbsPlacement = BreadcrumbsPlacement.HIDDEN;
	// Fragments settings
	var EXPAND_BY_DEFAULT:Bool = true;

	var ENABLE_SYNC_SCROLL:Bool = true;

	// var eventDispatcher:EventDispatcher<TextDiffSettings.Listener> = EventDispatcher.create(TextDiffSettings.Listener);

	public function new() {}
}

class TextDiffSettings {
	var PLACE_SETTINGS = new PlaceSettings();

  public function new() {
    this.highlightPolicy = PLACE_SETTINGS.HIGHLIGHT_POLICY;
  }

	// public function addListener(listener:Listener, disposable:Disposable) {
	// 	SHARED_SETTINGS.eventDispatcher.addListener(listener, disposable);
	// 	PLACE_SETTINGS.eventDispatcher.addListener(listener, disposable);
	// }
	// Presentation settings
	// var isEnableSyncScroll: Bool by placeDelegate(PlaceSettings::ENABLE_SYNC_SCROLL) { scrollingChanged() }
	// var isEnableAligningChangesMode: Bool by sharedDelegate(SharedSettings::ENABLE_ALIGNING_CHANGES_MODE) { alignModeChanged() }
	// Diff settings
	@:isVar public var highlightPolicy(default, set):HighlightPolicyEnum;

	function set_highlightPolicy(value:HighlightPolicyEnum) {
    var val: HighlightPolicyEnum;
		if (this.PLACE_SETTINGS.HIGHLIGHT_POLICY != value) {
			val = value;
			if (value != HighlightPolicyEnum.DO_NOT_HIGHLIGHT) { // do not persist confusing value as new default
				val = value;
			}
			// PLACE_SETTINGS.eventDispatcher.multicaster.highlightPolicyChanged();
		}

    return val;
	}

	// var ignorePolicy: IgnorePolicy by placeDelegate(PlaceSettings::IGNORE_POLICY) { ignorePolicyChanged() }
	//
	// Merge
	//
	// var isAutoApplyNonConflictedChanges: Bool by sharedDelegate(SharedSettings::MERGE_AUTO_APPLY_NON_CONFLICTED_CHANGES)
	//
	// var isAutoResolveImportConflicts: Bool by sharedDelegate(SharedSettings::MERGE_AUTO_RESOLVE_IMPORT_CONFLICTS) { resolveConflictsInImportsChanged() }
	//
	// var isEnableLstGutterMarkersInMerge: Bool by sharedDelegate(SharedSettings::MERGE_LST_GUTTER_MARKERS)
	// Editor settings
	// var isShowLineNumbers: Bool by placeDelegate(PlaceSettings::SHOW_LINE_NUMBERS)
	//
	// var isShowWhitespaces: Bool by placeDelegate(PlaceSettings::SHOW_WHITESPACES)
	//
	// var isShowIndentLines: Bool by placeDelegate(PlaceSettings::SHOW_INDENT_LINES)
	//
	// var isUseSoftWraps: Bool by placeDelegate(PlaceSettings::USE_SOFT_WRAPS)
	//
	// var highlightingLevel: HighlightingLevel by placeDelegate(PlaceSettings::HIGHLIGHTING_LEVEL)
	//
	// var contextRange: Int by sharedDelegate(SharedSettings::CONTEXT_RANGE) { foldingChanged() }
	//
	// var isExpandByDefault: Bool by placeDelegate(PlaceSettings::EXPAND_BY_DEFAULT) { foldingChanged() }
	//
	// var isReadOnlyLock: Bool by placeDelegate(PlaceSettings::READ_ONLY_LOCK)
	//
	// var breadcrumbsPlacement: BreadcrumbsPlacement by placeDelegate(PlaceSettings::BREADCRUMBS_PLACEMENT) { breadcrumbsPlacementChanged() }
	//
	// Impl
	//
	//   @:generic
	//   private function  sharedDelegate<T>(accessor: KMutableProperty1<SharedSettings, T>,
	//                                  onChange: Listener.() -> Unit = {}): ReadWriteProperty<Any?, T> {
	//     return object : ReadWriteProperty<Any?, T> {
	//       override fun getValue(thisRef: Any?, property: KProperty<*>): T {
	//         return accessor.get(SHARED_SETTINGS)
	//       }
	//
	//       override fun setValue(thisRef: Any?, property: KProperty<*>, value: T) {
	//         if (value == accessor.get(SHARED_SETTINGS)) return
	//         accessor.set(SHARED_SETTINGS, value)
	//         onChange(SHARED_SETTINGS.eventDispatcher.multicaster)
	//       }
	//     }
	//   }
	//
	//   private fun <T> placeDelegate(accessor: KMutableProperty1<PlaceSettings, T>,
	//                                 onChange: Listener.() -> Unit = {}): ReadWriteProperty<Any?, T> {
	//     return object : ReadWriteProperty<Any?, T> {
	//       override fun getValue(thisRef: Any?, property: KProperty<*>): T {
	//         return accessor.get(PLACE_SETTINGS)
	//       }
	//
	//       override fun setValue(thisRef: Any?, property: KProperty<*>, value: T) {
	//         if (value == accessor.get(PLACE_SETTINGS)) return
	//         accessor.set(PLACE_SETTINGS, value)
	//         onChange(PLACE_SETTINGS.eventDispatcher.multicaster)
	//       }
	//     }
	//   }
	//
	//
	//   companion object {
	//     @JvmField val KEY: Key<TextDiffSettings> = Key.create("TextDiffSettings")
	//
	//     @JvmStatic fun getSettings(): TextDiffSettings = getSettings(null)
	//     @JvmStatic fun getSettings(place: String?): TextDiffSettings = service<TextDiffSettingsHolder>().getSettings(place)
	//     internal fun getDefaultSettings(place: String): TextDiffSettings =
	//       TextDiffSettings(SharedSettings(), service<TextDiffSettingsHolder>().defaultPlaceSettings(place), place)
	//   }
	//
	// }
	//
	//
}

abstract class Listener {
	function highlightPolicyChanged() {}

	function ignorePolicyChanged() {}

	function resolveConflictsInImportsChanged() {}

	function breadcrumbsPlacementChanged() {}

	function foldingChanged() {}

	function scrollingChanged() {}

	function alignModeChanged() {}

	var Adapter:Listener;
}

class State {
	public var PLACES_MAP:Map<String, PlaceSettings> = [];
	public var SHARED_SETTINGS:SharedSettings = new SharedSettings();

	public function new() {}
}
