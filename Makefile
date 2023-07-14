.PHONY: clean format run-debug help

run-debug:
	flutter run -d linux

release:
	flutter build linux --release

format:
	dart format .

clean:
	rm -rf pubspec.lock
	flutter clean