.PHONY: clean format run-debug appimage

run-debug:
	flutter run -d linux

release:
	flutter build linux --release

appimage: release
	docker run --rm -t -d --name appimage-builder appimagecrafters/appimage-builder:latest
	docker cp ./ appimage-builder:./
	docker exec -it appimage-builder bash -c "appimage-builder --recipe ./AppImageBuilder.yml --skip-test"
	docker cp appimage-builder:./LinuxPowerToys-latest-x86_64.AppImage .
	docker rm -f appimage-builder

format:
	dart format .

clean:
	rm -rf pubspec.lock
	flutter clean
