import diff.merge.MergeThreesideViewer;
import diff.util.ThreeSide;
import config.DiffConfig;
import MergeDriver;

class Main {
	static public function main():Void {
		#if sys
		Sys.exit(parseArgs(Sys.args()));
		#end
	}

	#if sys
	static private function parseArgs(args:Array<String>):Int {
		if (args.length < 4) {
			trace("Invalid arg count");
			return -1;
		}

		var command = args[0];
		switch command {
			case "mergedriver":
				try {
					return MergeDriver.mergeFiles(args[1], args[2], args[3]) ? 0 : 1;
				} catch (e) {
					trace(e.message);
					// https://git-scm.com/docs/gitattributes#_defining_a_custom_merge_driver
					return 129;
				}
			case "mergestrings":
				var result = MergeDriver.mergeStrings(args[1], args[2], args[3], Std.parseInt(args[4]));
				Sys.print(result.diff);
				return result.noConflicts ? 0 : 1;
			case "mergeatcursor":
				var result = MergeDriver.mergeStringsAtBaseLine(args[1], args[2], args[3], Std.parseInt(args[4]), Std.parseInt(args[5]));
				Sys.print(result.buffer);
				return result.resolved ? 0 : 1;
			case "getSide":
				var result = MergeDriver.getSide(args[1], args[2], Std.parseInt(args[5]));
				Sys.print(result);
				return 0;
			default:
				trace("Invalid command");
				return -1;
		}
	}
	#end
}

@:expose
class API {
	static public function resolve(left, middle, right, applyNonConflicted = false, greedy = false, patience = false, conflicts = false):Array<String> {
		DiffConfig.AUTO_APPLY_NON_CONFLICTED_CHANGES = applyNonConflicted;
		DiffConfig.USE_GREEDY_MERGE_MAGIC_RESOLVE = greedy;
		DiffConfig.USE_PATIENCE_ALG = patience;

		var viewer = new MergeThreesideViewer([left, middle, right], middle);
		viewer.rediff(false);

		if (conflicts) {
			viewer.applyResolvableConflictedChanges();
		}

		var finalMergedText = viewer.myModel.getDocument();

		var diff = new HtmlDiff(viewer.myAllMergeChanges);

		var formattedLeft = diff.formatSide(left, ThreeSideEnum.LEFT);
		var formattedMiddle = diff.formatSide(finalMergedText, ThreeSideEnum.BASE);
		var formattedRight = diff.formatSide(right, ThreeSideEnum.RIGHT);

		return [finalMergedText, formattedLeft, formattedMiddle, formattedRight];
	}

	#if js
	static public function decorate():Void {
		DiffDecorations.decorate();
	}
	#end

	static public function mergeTest():Void {
		var base = "import type {OnChanges, SimpleChanges} from '@angular/core';\nimport {ChangeDetectionStrategy, Component, forwardRef, Input} from '@angular/core';\nimport type {UntypedFormGroup} from '@angular/forms';\nimport {NG_VALUE_ACCESSOR, ReactiveFormsModule} from '@angular/forms';\nimport {pick} from 'lodash-es';\nimport type {Nullable} from '../../../../../../definitions/Nullable';\nimport {GlobalModule} from '../../../../global.module';\nimport {AutoIdModule} from '../../../../layout/auto-id.directive';\nimport {DEFAULT_NAMESPACE} from '../../../../translate/DEFAULT_NAMESPACE.token';\nimport type {EventBookingInfoFrontend, EventWorkshopFrontend} from '../../../resource/event.resource';\nimport {EventResourceResponse} from '../../../resource/event.resource';\nimport type {EventTicketResponse} from '../../../resource/refs/event-ticket.vref';\nimport {AbstractBookingModalSection} from '../abstract-booking-modal-section';\nimport {BookingModalWorkshopsComponent} from '../workshops/booking-modal-workshops.component';\n\ntype Output = Partial<Nullable<Pick<EventBookingInfoFrontend, 'attendance_type' | 'dietary' | 'special_needs' | 'workshops'>>>;\n\n@Component({\n  changeDetection: ChangeDetectionStrategy.OnPush,\n  imports: [\n    GlobalModule,\n    AutoIdModule,\n    ReactiveFormsModule,\n    BookingModalWorkshopsComponent,\n  ],\n  providers: [{\n    multi: true,\n    provide: NG_VALUE_ACCESSOR,\n    useExisting: forwardRef(() => BookingModalCommonUserInfoComponent),\n  }],\n  selector: 'tg-booking-modal-common-user-info',\n  standalone: true,\n  styleUrls: ['../../../../_common-styles/host-display-block.scss'],\n  templateUrl: './booking-modal-common-user-info.component.pug',\n  viewProviders: [\n    {\n      provide: DEFAULT_NAMESPACE,\n      useValue: 'events',\n    },\n  ],\n})\nexport class BookingModalCommonUserInfoComponent\n  extends AbstractBookingModalSection<Output> implements OnChanges {\n\n  @Input()\n  public event: EventResourceResponse;\n\n  @Input()\n  public ticket: Pick<EventTicketResponse, 'workshops'>;\n\n  public workshops: EventWorkshopFrontend[] = [];\n\n  private workshopKeys: string[] = [];\n\n  public buildWorkshops(): void {\n    this.workshops = this.event.workshopsForTicket(this.ticket);\n    this.workshopKeys = this.workshops?.map(w => w.id) || [];\n  }\n\n  /** @inheritDoc */\n  public ngOnChanges(changes: SimpleChanges): void {\n    if ('event' in changes || 'ticket' in changes) {\n      this.buildWorkshops();\n      this.ctrl = this.formSvc.createCommonUserInfo(true, this.ctrl?.getRawValue(), this.ticket.workshops);\n    }\n  }\n\n  /** @inheritDoc */\n  public override writeValue(obj: Output | null | undefined): void {\n    super.writeValue(\n      obj?.workshops\n        ? {\n          ...obj,\n          workshops: {...this.defaultValue.workshops, ...pick(obj.workshops, this.workshopKeys) as any},\n        }\n        : obj\n    );\n  }\n\n  /** @inheritDoc */\n  protected createCtrl(): UntypedFormGroup {\n    return this.formSvc.createCommonUserInfo(true, undefined, this.workshops);\n  }\n}\n\nexport {Output as CommonUserInfoOutput};";
		var current = "import {distinctUntilDeepChanged} from '@aloreljs/rxutils/operators';\nimport type {OnDestroy, OnInit} from '@angular/core';\nimport {ChangeDetectionStrategy, Component, EventEmitter, Output, ViewChild} from '@angular/core';\nimport type {FormGroup} from '@angular/forms';\nimport {ReactiveFormsModule} from '@angular/forms';\nimport {debounceTime, last, map, pairwise, startWith, takeUntil} from 'rxjs/operators';\nimport {GlobalModule} from '../../../../global.module';\nimport {AutoIdModule} from '../../../../layout/auto-id.directive';\nimport {FormGroupModule} from '../../../../layout/form-group/form-group.module';\nimport type {BlurIfChangedEvent} from '../../../../layout/on-blur-if-changed';\nimport {OnBlurIfChangedDirective} from '../../../../layout/on-blur-if-changed';\nimport {DEFAULT_NAMESPACE} from '../../../../translate/DEFAULT_NAMESPACE.token';\nimport type {FormGroupRawValueOf} from '../../../../util/typed-form';\nimport {AbstractBookingModalSection} from '../abstract-booking-modal-section';\nimport type {UserInfoModalFormService} from '../state-management/user-info-modal-form.service';\nimport {BookingModalWorkshopsComponent} from '../workshops/booking-modal-workshops.component';\n\ntype TForm = UserInfoModalFormService.CommonUserInfoForm;\n\nexport interface UserInfoDraftSaveEvent<K extends keyof TForm = keyof TForm>\n  extends BlurIfChangedEvent<FormGroupRawValueOf<TForm[K]>> {\n  field: K;\n}\n\n@Component({\n  changeDetection: ChangeDetectionStrategy.OnPush,\n  imports: [\n    GlobalModule,\n    FormGroupModule,\n    AutoIdModule,\n    OnBlurIfChangedDirective,\n    ReactiveFormsModule,\n    BookingModalWorkshopsComponent,\n  ],\n  selector: 'tg-booking-modal-common-user-info',\n  standalone: true,\n  styleUrls: ['../../../../_common-styles/host-display-block.scss'],\n  templateUrl: './booking-modal-common-user-info.component.pug',\n  viewProviders: [\n    {provide: DEFAULT_NAMESPACE, useValue: 'events'},\n  ],\n})\nexport class BookingModalCommonUserInfoComponent extends AbstractBookingModalSection<FormGroup<TForm>>\n  implements OnInit, OnDestroy {\n\n  @Output()\n  public readonly saveDraft = new EventEmitter<UserInfoDraftSaveEvent>();\n\n  @ViewChild(BookingModalWorkshopsComponent)\n  public workshops: BookingModalWorkshopsComponent;\n\n  public forwardDraft<K extends keyof TForm>(\n    field: K,\n    origEvent: BlurIfChangedEvent<FormGroupRawValueOf<TForm[K]>>\n  ): void {\n    this.saveDraft.emit({field, ...origEvent});\n  }\n\n  public ngOnDestroy(): void {\n    this.saveDraft.complete();\n  }\n\n  public ngOnInit(): void {\n    const workshops = this.ctrl.controls.workshops;\n    if (!workshops) {\n      return;\n    }\n\n    /*\n     * Not `blur`-based like other draft saves, but can't find a better way that doesn't involve changing a bunch of\n     * custom forms code.\n     */\n    const destroyed$ = this.saveDraft.pipe(last(null, null));\n    workshops.valueChanges\n      .pipe(\n        debounceTime(1000),\n        map(() => workshops.getRawValue()),\n        startWith(workshops.getRawValue()),\n        distinctUntilDeepChanged(),\n        pairwise(),\n        takeUntil(destroyed$)\n      )\n      .subscribe(([from, to]) => {\n        this.forwardDraft('workshops', {from, to});\n      });\n  }\n\n}";
		var other = "import type {OnChanges, SimpleChanges} from '@angular/core';\nimport {ChangeDetectionStrategy, Component, forwardRef, Input} from '@angular/core';\nimport type {UntypedFormGroup} from '@angular/forms';\nimport {NG_VALUE_ACCESSOR, ReactiveFormsModule} from '@angular/forms';\nimport {pick} from 'lodash-es';\nimport type {Nullable} from '../../../../../../definitions/Nullable';\nimport {GlobalModule} from '../../../../global.module';\nimport {AutoIdModule} from '../../../../layout/auto-id.directive';\nimport {DEFAULT_NAMESPACE} from '../../../../translate/DEFAULT_NAMESPACE.token';\nimport type {EventBookingInfoFrontend, EventWorkshopFrontend} from '../../../resource/event.resource';\nimport {EventResourceResponse} from '../../../resource/event.resource';\nimport type {EventTicketResponse} from '../../../resource/refs/event-ticket.vref';\nimport {AbstractBookingModalSection} from '../abstract-booking-modal-section';\nimport {BookingModalWorkshopsComponent} from '../workshops/booking-modal-workshops.component';\n\n// Bespoke: new further details field on Event Page #15169\ntype Output = Partial<Nullable<Pick<EventBookingInfoFrontend, 'attendance_type' | 'dietary' | 'further_details' | 'special_needs'\n  | 'workshops'>>>;\n\n@Component({\n  changeDetection: ChangeDetectionStrategy.OnPush,\n  imports: [\n    GlobalModule,\n    AutoIdModule,\n    ReactiveFormsModule,\n    BookingModalWorkshopsComponent,\n  ],\n  providers: [{\n    multi: true,\n    provide: NG_VALUE_ACCESSOR,\n    useExisting: forwardRef(() => BookingModalCommonUserInfoComponent),\n  }],\n  selector: 'tg-booking-modal-common-user-info',\n  standalone: true,\n  styleUrls: ['../../../../_common-styles/host-display-block.scss'],\n  templateUrl: './booking-modal-common-user-info.component.pug',\n  viewProviders: [\n    {\n      provide: DEFAULT_NAMESPACE,\n      useValue: 'events',\n    },\n  ],\n})\nexport class BookingModalCommonUserInfoComponent\n  extends AbstractBookingModalSection<Output> implements OnChanges {\n\n  @Input()\n  public event: EventResourceResponse;\n\n  @Input()\n  public ticket: Pick<EventTicketResponse, 'workshops'>;\n\n  public workshops: EventWorkshopFrontend[] = [];\n\n  private workshopKeys: string[] = [];\n\n  public buildWorkshops(): void {\n    this.workshops = this.event.workshopsForTicket(this.ticket);\n    this.workshopKeys = this.workshops?.map(w => w.id) || [];\n  }\n\n  /** @inheritDoc */\n  public ngOnChanges(changes: SimpleChanges): void {\n    if ('event' in changes || 'ticket' in changes) {\n      this.buildWorkshops();\n      this.ctrl = this.formSvc.createCommonUserInfo(true, this.ctrl?.getRawValue(), this.ticket.workshops);\n    }\n  }\n\n  /** @inheritDoc */\n  public override writeValue(obj: Output | null | undefined): void {\n    super.writeValue(\n      obj?.workshops\n        ? {\n          ...obj,\n          workshops: {...this.defaultValue.workshops, ...pick(obj.workshops, this.workshopKeys) as any},\n        }\n        : obj\n    );\n  }\n\n  /** @inheritDoc */\n  protected createCtrl(): UntypedFormGroup {\n    return this.formSvc.createCommonUserInfo(true, undefined, this.workshops);\n  }\n}\n\nexport {Output as CommonUserInfoOutput};";

		var result = MergeDriver.mergeStrings(base, current, other, 15);
		trace(result);
	}
}
