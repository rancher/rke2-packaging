COMBARCH ?= x86_64-amd64
ALL_ARCH = x86_64-amd64

CENTOS7_TARGETS := $(addprefix centos7-,$(shell ls rpm/centos7/scripts))
CENTOS8_TARGETS := $(addprefix centos8-,$(shell ls rpm/centos8/scripts))
MICROOS_TARGETS := $(addprefix microos-,$(shell ls rpm/microos/scripts))

.dapper:
	@echo Downloading dapper
	@curl -sL https://releases.rancher.com/dapper/latest/dapper-$$(uname -s)-$$(uname -m) > .dapper.tmp
	@@chmod +x .dapper.tmp
	@./.dapper.tmp -v
	@mv .dapper.tmp .dapper

$(CENTOS7_TARGETS): .dapper
	COMBARCH=${COMBARCH} ./.dapper -f Dockerfile.centos7.dapper $(@:centos7-%=%)

$(CENTOS8_TARGETS): .dapper
	COMBARCH=${COMBARCH} ./.dapper -f Dockerfile.centos8.dapper $(@:centos8-%=%)

$(MICROOS_TARGETS): .dapper
	COMBARCH=${COMBARCH} ./.dapper -f Dockerfile.microos.dapper $(@:microos-%=%)

all-centos7-build: $(addprefix sub-centos7-build-,$(ALL_ARCH))

sub-centos7-build-%:
	$(MAKE) COMBARCH=$* centos7-build

all-centos8-build: $(addprefix sub-centos8-build-,$(ALL_ARCH))

sub-centos8-build-%:
	$(MAKE) COMBARCH=$* centos8-build

all-microos-build: $(addprefix sub-microos-build-,$(ALL_ARCH))

sub-microos-build-%:
	$(MAKE) COMBARCH=$* microos-build

.PHONY: $(CENTOS7_TARGETS) $(CENTOS8_TARGETS) $(MICROOS_TARGETS)
