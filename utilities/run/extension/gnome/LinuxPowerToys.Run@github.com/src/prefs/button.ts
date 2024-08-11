/**
 * [ShortcutSettingButton] is copied from https://github.com/domferr/tilingshell/blob/main/src/prefs.ts (03.08.2024)
 */

import Adw from 'gi://Adw';
import Gtk from 'gi://Gtk';
import Gdk from 'gi://Gdk';
import GObject from 'gi://GObject';

// eslint-disable-next-line no-unused-vars
export const ShortcutSettingButton = class extends Gtk.Button {
    static {
        GObject.registerClass(
            {
                Properties: {
                    shortcut: GObject.ParamSpec.string(
                        'shortcut',
                        'shortcut',
                        'The shortcut',
                        GObject.ParamFlags.READWRITE,
                        '',
                    ),
                },
                Signals: {
                    changed: { param_types: [GObject.TYPE_STRING] },
                },
            },
            this,
        );
    }

    private _editor: Adw.Window | null;
    private _label: Gtk.ShortcutLabel;
    private shortcut: string;

    constructor(value: string) {
        super({
            halign: Gtk.Align.CENTER,
            hexpand: false,
            vexpand: false,
            has_frame: false,
        });

        this._editor = null;
        this._label = new Gtk.ShortcutLabel({
            disabled_text: 'New accelerator…',
            valign: Gtk.Align.CENTER,
            hexpand: false,
            vexpand: false,
        });

        this.set_child(this._label);

        // Bind signals
        this.connect('clicked', this._onActivated.bind(this));
        this.shortcut = value;
        this._label.set_accelerator(this.shortcut);
        this.bind_property(
            'shortcut',
            this._label,
            'accelerator',
            GObject.BindingFlags.DEFAULT,
        );
    }

    _onActivated(widget: Gtk.Widget) {
        const ctl = new Gtk.EventControllerKey();

        const content = new Adw.StatusPage({
            title: 'New accelerator…',
            // description: this._description,
            icon_name: 'preferences-desktop-keyboard-shortcuts-symbolic',
        });

        this._editor = new Adw.Window({
            modal: true,
            hide_on_close: true,
            // @ts-expect-error "widget has get_root function"
            transient_for: widget.get_root(),
            width_request: 480,
            height_request: 320,
            content,
        });

        this._editor.add_controller(ctl);
        ctl.connect('key-pressed', this._onKeyPressed.bind(this));
        this._editor.present();
    }

    _onKeyPressed(
        _widget: Gtk.Widget,
        keyval: number,
        keycode: number,
        state: number,
    ) {
        let mask = state & Gtk.accelerator_get_default_mod_mask();
        mask &= ~Gdk.ModifierType.LOCK_MASK;

        if (!mask && keyval === Gdk.KEY_Escape) {
            this._editor?.close();
            return Gdk.EVENT_STOP;
        }

        if (
            !this.isValidBinding(mask, keycode, keyval) ||
            !this.isValidAccel(mask, keyval)
        )
            return Gdk.EVENT_STOP;

        if (!keyval && !keycode) {
            this._editor?.destroy();
            return Gdk.EVENT_STOP;
        } else {
            this.shortcut = Gtk.accelerator_name_with_keycode(
                null,
                keyval,
                keycode,
                mask,
            );
            this._label.set_accelerator(this.shortcut);
            this.emit('changed', this.shortcut);
        }

        this._editor?.destroy();
        return Gdk.EVENT_STOP;
    }

    // Functions from https://gitlab.gnome.org/GNOME/gnome-control-center/-/blob/main/panels/keyboard/keyboard-shortcuts.c
    keyvalIsForbidden(keyval: number) {
        return [
            // Navigation keys
            Gdk.KEY_Home,
            Gdk.KEY_Left,
            Gdk.KEY_Up,
            Gdk.KEY_Right,
            Gdk.KEY_Down,
            Gdk.KEY_Page_Up,
            Gdk.KEY_Page_Down,
            Gdk.KEY_End,
            Gdk.KEY_Tab,

            // Return
            Gdk.KEY_KP_Enter,
            Gdk.KEY_Return,

            Gdk.KEY_Mode_switch,
        ].includes(keyval);
    }

    isValidBinding(mask: number, keycode: number, keyval: number) {
        return !(
            mask === 0 ||
            // @ts-expect-error "Gdk has SHIFT_MASK"
            (mask === Gdk.SHIFT_MASK &&
                keycode !== 0 &&
                ((keyval >= Gdk.KEY_a && keyval <= Gdk.KEY_z) ||
                    (keyval >= Gdk.KEY_A && keyval <= Gdk.KEY_Z) ||
                    (keyval >= Gdk.KEY_0 && keyval <= Gdk.KEY_9) ||
                    (keyval >= Gdk.KEY_kana_fullstop &&
                        keyval <= Gdk.KEY_semivoicedsound) ||
                    (keyval >= Gdk.KEY_Arabic_comma &&
                        keyval <= Gdk.KEY_Arabic_sukun) ||
                    (keyval >= Gdk.KEY_Serbian_dje &&
                        keyval <= Gdk.KEY_Cyrillic_HARDSIGN) ||
                    (keyval >= Gdk.KEY_Greek_ALPHAaccent &&
                        keyval <= Gdk.KEY_Greek_omega) ||
                    (keyval >= Gdk.KEY_hebrew_doublelowline &&
                        keyval <= Gdk.KEY_hebrew_taf) ||
                    (keyval >= Gdk.KEY_Thai_kokai &&
                        keyval <= Gdk.KEY_Thai_lekkao) ||
                    (keyval >= Gdk.KEY_Hangul_Kiyeog &&
                        keyval <= Gdk.KEY_Hangul_J_YeorinHieuh) ||
                    (keyval === Gdk.KEY_space && mask === 0) ||
                    this.keyvalIsForbidden(keyval)))
        );
    }

    isValidAccel(mask: number, keyval: number) {
        return (
            Gtk.accelerator_valid(keyval, mask) ||
            (keyval === Gdk.KEY_Tab && mask !== 0)
        );
    }
};
