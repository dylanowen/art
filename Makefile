SHELL:=/bin/bash

PROJECTS := fractal origami
PROJECT_PACKAGES := $(foreach project,$(PROJECTS),$(project)-package)
PROJECT_TARGETS := $(foreach \
	target, \
	run web release, \
	$(foreach project,$(PROJECTS),$(project)-$(target))\
) $(PROJECT_PACKAGES)

$(info $$PROJECT_TARGETS is [${PROJECT_TARGETS}])

.PHONY: check fix format lint pre-check $(PROJECTS) $(PROJECT_TARGETS) package publish clean

# "This will essentially compile the packages without performing the final step of code generation, which is faster than running cargo build."
check:
	cargo check
	cargo check --target wasm32-unknown-unknown

fix:
	cargo fix --allow-staged

fmt:
	cargo fmt

lint:
	cargo clippy --all-targets --all-features -- -D warnings
	-cargo audit

# run all of our formatting / lints / fixes and check our various compile targets
pre-check: fix format lint check

$(PROJECTS):
	$(MAKE) -C $@ run

$(PROJECT_TARGETS):
	project=$$(cut -f 1 -d- <<<"$@"); \
	target=$$(cut -f 2 -d- <<<"$@"); \
	$(MAKE) -C $${project} $${target}

package: $(PROJECT_PACKAGES)
	mkdir -p dist
	rm -rf dist/*
	for project in $(PROJECTS) ; do \
  		cp -r $${project}/dist dist/$${project} ; \
  	done
	cp -r index.html dist/


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
	rm -rf dist
	for project in $(PROJECTS) ; do \
		$(MAKE) -C $${project} clean ; \
	done
	cargo clean