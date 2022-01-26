SHELL:=/bin/bash

# .DEFAULT_GOAL := default
.PHONY: check fix format lint pre-check dev release web-dev web-release package publish clean

# "This will essentially compile the packages without performing the final step of code generation, which is faster than running cargo build."
check:
	cargo check
	cargo check --target wasm32-unknown-unknown

fix:
	cargo fix --allow-staged

format:
	cargo fmt

lint:
	cargo clippy --all-targets --all-features -- -D warnings
	-cargo audit

# run all of our formatting / lints / fixes and check our various compile targets
pre-check: fix format lint check

dev:
	cargo run --features bevy/dynamic

web-dev:
	wasm-pack build --target web --dev

web-release:
	wasm-pack build --target web --release

package: web-release
	mkdir -p dist
	rm -rf dist/*
	mkdir -p dist/pkg
	cp -r pkg/*.js pkg/*.wasm dist/pkg/
	cp -r index.html assets dist/


publish: pre-check package
	@echo "====> deploying to github"
	# checkout the existing gh-pages
	rm -rf /tmp/gh-pages
	git worktree add -f /tmp/gh-pages gh-pages
	rm -rf /tmp/gh-pages/*
	# copy the web files to the gh-pages folder
	cp -r dist/* /tmp/gh-pages/
	# push our new gh-pages
	cd /tmp/gh-pages && \
		git add -A && \
		git commit -m "deployed on $(shell date) by ${USER}" && \
		git push origin gh-pages
	git worktree remove /tmp/gh-pages

clean:
	# remove the pkg folders since leftover artifacts here can mess with wasm-opt
	rm -rf pkg
	rm -rf dist
	cargo clean