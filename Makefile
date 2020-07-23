COMBARCH ?= x86_64-amd64
ALL_ARCH = x86_64-amd64 aarch64-arm64

CENTOS7_TARGETS := $(addprefix centos7-,$(shell ls rpm/centos7/scripts))

.dapper:
	@echo Downloading dapper
	@curl -sL https://releases.rancher.com/dapper/latest/dapper-$$(uname -s)-$$(uname -m) > .dapper.tmp
	@@chmod +x .dapper.tmp
	@./.dapper.tmp -v
	@mv .dapper.tmp .dapper

$(CENTOS7_TARGETS): .dapper
	COMBARCH=${COMBARCH} ./.dapper -f Dockerfile.centos7.dapper $(@:centos7-%=%)

all-centos7-build: $(addprefix sub-centos7-build-,$(ALL_ARCH))

sub-centos7-build-%:
	$(MAKE) COMBARCH=$* build

.PHONY: $(CENTOS7_TARGETS)