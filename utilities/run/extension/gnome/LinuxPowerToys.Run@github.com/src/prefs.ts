import Gtk from 'gi://Gtk';
import Adw from 'gi://Adw';
import Gio from 'gi://Gio';

import { ExtensionPreferences, gettext as _ } from 'resource:///org/gnome/Shell/Extensions/js/extensions/prefs.js';
import { ShortcutSettingButton } from './prefs/button';
import { get_summon_key_name, set_summon_key_name } from './settings';

export default class GnomeRectanglePreferences extends ExtensionPreferences {
    _settings?: Gio.Settings

    fillPreferencesWindow(window: Adw.PreferencesWindow) {
        this._settings = this.getSettings();

        const prefsPage = new Adw.PreferencesPage({
            name: 'general',
            title: 'General',
            iconName: 'dialog-information-symbolic',
        });
        window.add(prefsPage);


        // Keybindings section
        const keybindingsGroup = new Adw.PreferencesGroup({
            title: 'Keybindings',
            description: 'Use hotkeys to summon the Linux PowerToys run utility',
        });
        prefsPage.add(keybindingsGroup);

        const moveRightKB = this._buildShortcutButtonRow(
            get_summon_key_name(this._settings),
            'Summon run utility',
            'Key used for toggling the visibility of the run utility',
            (_: unknown, value: string) => set_summon_key_name(this._settings, value),
        );
        keybindingsGroup.add(moveRightKB);


        // footer
        const footerGroup = new Adw.PreferencesGroup();
        prefsPage.add(footerGroup);
        if (this.metadata['version-name']) {
            footerGroup.add(
                new Gtk.Label({
                    label: `· Linux PowerToys Run v${this.metadata['version-name']} ·`,
                }),
            );
        }

        window.searchEnabled = false;
    }

    _buildShortcutButtonRow(
        shortcut: string,
        title: string,
        subtitle: string,
        onChange: (_: unknown, value: string) => void,
        styleClass?: string,
    ) {
        const btn = new ShortcutSettingButton(shortcut);
        if (styleClass) btn.add_css_class(styleClass);
        btn.set_vexpand(false);
        btn.set_valign(Gtk.Align.CENTER);
        const adwRow = new Adw.ActionRow({
            title,
            subtitle,
            activatableWidget: btn,
        });
        adwRow.add_suffix(btn);

        btn.connect('changed', onChange);

        return adwRow;
    }
}


