// Copyright 2000-2019 JetBrains s.r.o. Use of this source code is governed by the Apache 2.0 license that can be found in the LICENSE file.
package diff.tools.util.text;

import diff.tools.util.base.HighlightPolicy;
import diff.tools.util.base.HighlightPolicy.HighlightPolicyEnum;
import config.IgnorePolicy;

// interface Runnable {
// 	function run():Void;
// }
class TextDiffProviderBase {
	// private final myIgnorePolicySettingAction:IgnorePolicySettingAction;
	// private final myHighlightPolicySettingAction:HighlightPolicySettingAction;
	public function new(/*settings:TextDiffSettings,*/ /*rediff:Runnable,*/ /*disposable:Disposable,*/ ignorePolicies:Array<IgnorePolicyEnum>,
			highlightPolicies:Array<HighlightPolicyEnum>) {
		// myIgnorePolicySettingAction = new MyIgnorePolicySettingAction(settings, ignorePolicies);
		// myHighlightPolicySettingAction = new MyHighlightPolicySettingAction(settings, highlightPolicies);
		// settings.addListener(new MyListener(rediff), disposable);
	}

	// public function getToolbarActions():Array<AnAction> {
	// 	return [myIgnorePolicySettingAction, myHighlightPolicySettingAction];
	// }
	//
	// public function getPopupActions():List<AnAction> {
	// 	return Arrays.asList(Separator.getInstance(), myIgnorePolicySettingAction.getActions(), Separator.getInstance(),
	// 		myHighlightPolicySettingAction.getActions(), Separator.getInstance());
	// }

	public function getIgnorePolicy():IgnorePolicy {
		// return myIgnorePolicySettingAction.getValue();
		return new IgnorePolicy(IgnorePolicyEnum.IGNORE_WHITESPACES);
	}

	public function getHighlightPolicy():HighlightPolicy{
		// return myHighlightPolicySettingAction.getValue();
		return new HighlightPolicy(HighlightPolicyEnum.BY_WORD_SPLIT);
	}

	public function isHighlightingDisabled():Bool {
		// return myHighlightPolicySettingAction.getValue() == HighlightPolicy.DO_NOT_HIGHLIGHT;
		return this.getHighlightPolicy().getHighlightPolicy() == HighlightPolicyEnum.DO_NOT_HIGHLIGHT;
	}

	private function getTextA(option:IgnorePolicyEnum):Null<String> {
		return null;
	}

	private function getTextB(option:HighlightPolicyEnum):Null<String> {
		return null;
	}
}
// class MyIgnorePolicySettingAction extends IgnorePolicySettingAction {
// class MyIgnorePolicySettingAction {
// 	public function new(settings:TextDiffSettings, ignorePolicies:Array<IgnorePolicy>) {
// 		super(settings, ignorePolicies);
// 	}
//
// 	private function getText(option:IgnorePolicy):String {
// 		var text:String = TextDiffProviderBase.getText(option);
// 		if (text != null)
// 			return text;
// 		return super.getText(option);
// 	}
// }
//
// // class MyHighlightPolicySettingAction extends HighlightPolicySettingAction {
// class MyHighlightPolicySettingAction {
// 	public function new(settings:TextDiffSettings, highlightPolicies:Array<HighlightPolicy>) {
// 		super(settings, highlightPolicies);
// 	}
//
// 	// private override function getText(option: HighlightPolicy ):String {
// 	private function getText(option:HighlightPolicy):String {
// 		var text:String = TextDiffProviderBase.getText(option);
// 		if (text != null)
// 			return text;
// 		return super.getText(option);
// 	}
// }
//
// class MyListener extends Listener {
// 	private final myRediff:Runnable;
//
// 	public override function highlightPolicyChanged():Void {
// 		myRediff.run();
// 	}
//
// 	public function ignorePolicyChanged():Void {
// 		myRediff.run();
// 	}
//
// 	public function new(myRediff:Dynamic) {
// 		this.myRediff = myRediff;
// 	}
// }
