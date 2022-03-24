# Most likely want to override these when calling `make image`
IMAGE_REG ?= ghcr.io
IMAGE_REPO ?= benc-uk/keycloak
IMAGE_TAG ?= latest
IMAGE_PREFIX := $(IMAGE_REG)/$(IMAGE_REPO)
DOCKERFILE ?= build/Dockerfile.mssql

.PHONY: help image push
.DEFAULT_GOAL := help

help: ## 💬 This help message :)
	@figlet $@ || true
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

image: ## 📦 Build container image from Dockerfile
	@figlet $@ || true
	docker build --file ./$(DOCKERFILE) \
	--tag $(IMAGE_PREFIX):$(IMAGE_TAG) .

push: ## 📤 Push container image to registry
	@figlet $@ || true
	docker push $(IMAGE_PREFIX):$(IMAGE_TAG)


## ==========================================================================
## ADDED

SHELL := $(shell which bash)
.SHELLFLAGS := -eo pipefail -c

REPO_URL := https://flypenguin.github.io/kc-spike/


_lint:
	helm lint keycloak
.PHONY: _lint

_minor: _lint
	bumpversion minor
.PHONY: _minor

_major: _lint
	bumpversion major
.PHONY: _major

_patch: _lint
	bumpversion patch
.PHONY: _patch

_package:
	helm package -d ./docs keycloak
	helm repo index --url ${REPO_URL} ./docs
.PHONY: _package

_commit:
	@if ! git diff --quiet docs/ ; then \
	  git add docs/ ; \
	  git commit -m "add new version binary" ; \
	fi ; \
	echo "Execute 'make upload' for pushing."
.PHONY: _commit


minor: _minor _package _commit
.PHONY: minor

major: _major _package _commit
.PHONY: major

patch: _patch _package _commit
.PHONY: patch

chart: _chart _commit
.PHONY: chart

package: _package
.PHONY: package

commit: _commit
.PHONY: commit

upload:
	@git diff --quiet || (echo "Please commit before uploading, working dir is dirty." && false)
	git push && git push --tags
.PHONY: upload
