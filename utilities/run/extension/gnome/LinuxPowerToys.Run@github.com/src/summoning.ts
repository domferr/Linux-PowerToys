import Gio from 'gi://Gio';
import Meta from 'gi://Meta';
import Shell from 'gi://Shell';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';

import { SUMMONING_KEY_NAME } from './settings';

const LINUX_POWER_TOYS_RUN_D_BUS_BUS_NAME = "com.github.LinuxPowerToys.run";
const LINUX_POWER_TOYS_RUN_D_BUS_INTERFACE = "com.github.LinuxPowerToys.run";

export class RunSummoning {
    settings: Gio.Settings;

    constructor(settings: Gio.Settings) {
        this.settings = settings
    }

    enable(): void {
        Main.wm.addKeybinding(SUMMONING_KEY_NAME, this.settings, Meta.KeyBindingFlags.NONE,
            Shell.ActionMode.NORMAL, this.summonHandler);
    }

    async summonHandler() {
        try {
            Gio.DBus.session.call(
                LINUX_POWER_TOYS_RUN_D_BUS_BUS_NAME, "/", LINUX_POWER_TOYS_RUN_D_BUS_INTERFACE, "toggleVisibility",
                null, null, Gio.DBusCallFlags.NONE, -1, null,
            )
        } catch (e) {
            console.warn(e)
        }
    }

    disable(): void {
        Main.wm.removeKeybinding(SUMMONING_KEY_NAME);
    }
}
