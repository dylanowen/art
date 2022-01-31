SHELL:=/bin/bash

# .DEFAULT_GOAL := default
.PHONY: run web release package clean

run:
	cargo run --features bevy/dynamic

web:
	wasm-pack build --target web --dev

release:
	wasm-pack build --target web --release

package: release
	mkdir -p dist
	rm -rf dist/*
	mkdir -p dist/pkg
	cp -r pkg/*.js pkg/*.wasm dist/pkg/
	cp -r index.html dist/

clean:
	# remove the pkg folders since leftover artifacts here can mess with wasm-opt
	rm -rf pkg
	rm -rf dist
	cargo clean