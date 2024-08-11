import Meta from 'gi://Meta';
import Shell from 'gi://Shell';

import { LINUX_POWER_TOYS_RUN_APPLICATION_ID } from './settings';


export class WindowPositioner {
    window: Meta.Window | undefined;
    connectId: number = -1;

    constructor() {
        this.window = undefined;
    }

    enable(): void {
        this.connectId = Shell.WindowTracker.get_default().connect("tracked-windows-changed", () => this._findRunWindow());
    }

    _findRunWindow(): void {
        var windowCandidates = global.display.get_tab_list(Meta.TabList.NORMAL_ALL, null)
            .filter((window) => window.gtk_application_id === LINUX_POWER_TOYS_RUN_APPLICATION_ID);

        if (windowCandidates.length != 1) {
            this.window = undefined;
            return;
        }

        this.window = windowCandidates[0];
        this._positionWindow();
    }

    _positionWindow(): void {
        if (this.window === undefined)
            return;

        let window = this.window;

        let act = this.window.get_compositor_private();
        let id = act.connect('first-frame', _ => {
            const window_width = 700;
            const window_height = 500;

            var size = global.display.get_size();
            var width = size[0];
            var height = size[1];


            var x = (width - window_width) / 2;
            var y = (height - window_height) / 2;

            window.move_resize_frame(false, x, y, window_width, window_height);
            act.disconnect(id);
        })

    }

    disable(): void {
        if (this.connectId >= 0)
            Shell.WindowTracker.get_default().disconnect(this.connectId);
    }
}
