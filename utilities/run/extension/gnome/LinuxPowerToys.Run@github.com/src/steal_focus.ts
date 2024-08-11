import Meta from 'gi://Meta';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';

import { LINUX_POWER_TOYS_RUN_APPLICATION_ID } from './settings';

export class RunStealFocus {

    onWindowDemandsAttentionId: number = -1

    enable(): void {
        this.onWindowDemandsAttentionId = global.display.connect(
            'window-demands-attention',
            this.onWindowDemandsAttention,
        );
    }

    onWindowDemandsAttention(_display: Meta.Display, window: Meta.Window) {
        if (window.get_gtk_application_id() != LINUX_POWER_TOYS_RUN_APPLICATION_ID) return;

        Main.activateWindow(window);
    }

    disable(): void {
        global.display.disconnect(this.onWindowDemandsAttentionId);
    }
}
