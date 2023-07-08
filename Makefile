.PHONY: clean format run-debug help

run-debug:
	GSETTINGS_SCHEMA_DIR=\$GSETTINGS_SCHEMA_DIR:~/.local/share/gnome-shell/extensions/gSnap@micahosborne/schemas/:~/.local/share/gnome-shell/extensions/caffeine@patapon.info/schemas/ \
	flutter run -d linux

release:
	flutter build linux --release

format:
	dart format .

clean:
	rm -rf pubspec.lock
	flutter clean