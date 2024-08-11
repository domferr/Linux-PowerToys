import { Extension } from 'resource:///org/gnome/shell/extensions/extension.js';
import { RunSummoning } from './summoning';
import { WindowPositioner } from './positioning';
import { RunStealFocus } from './steal_focus';

export default class MyExtension extends Extension {
    summoning: RunSummoning = new RunSummoning(this.getSettings());
    positioner: WindowPositioner = new WindowPositioner();
    focusSteal: RunStealFocus = new RunStealFocus();

    enable(): void {
        this.summoning.enable();
        this.positioner.enable();
        this.focusSteal.enable();
        console.log("linux power toys run gnome extension enabled");
    }

    disable(): void {
        this.summoning.disable();
        this.positioner.disable();
        this.focusSteal.disable();
        console.log("linux power toys run gnome extension disabled");
    }
}