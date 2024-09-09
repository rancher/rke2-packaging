COMBARCH ?= x86_64-amd64
ALL_ARCH = x86_64-amd64

CENTOS7_TARGETS := $(addprefix centos7-,$(shell ls rpm/centos7/scripts))
CENTOS8_TARGETS := $(addprefix centos8-,$(shell ls rpm/centos8/scripts))
CENTOS9_TARGETS := $(addprefix centos9-,$(shell ls rpm/centos9/scripts))
MICROOS_TARGETS := $(addprefix microos-,$(shell ls rpm/microos/scripts))
SLEMICRO_TARGETS := $(addprefix slemicro-,$(shell ls rpm/slemicro/scripts))

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

$(CENTOS9_TARGETS): .dapper
	COMBARCH=${COMBARCH} ./.dapper -f Dockerfile.centos9.dapper $(@:centos9-%=%)

$(MICROOS_TARGETS): .dapper
	COMBARCH=${COMBARCH} ./.dapper -f Dockerfile.microos.dapper $(@:microos-%=%)

$(SLEMICRO_TARGETS): .dapper
	COMBARCH=${COMBARCH} ./.dapper -f Dockerfile.slemicro.dapper $(@:slemicro-%=%)

all-centos7-build: $(addprefix sub-centos7-build-,$(ALL_ARCH))

sub-centos7-build-%:
	$(MAKE) COMBARCH=$* centos7-build

all-centos8-build: $(addprefix sub-centos8-build-,$(ALL_ARCH))

sub-centos8-build-%:
	$(MAKE) COMBARCH=$* centos8-build

all-centos9-build: $(addprefix sub-centos9-build-,$(ALL_ARCH))

sub-centos9-build-%:
	$(MAKE) COMBARCH=$* centos9-build

all-microos-build: $(addprefix sub-microos-build-,$(ALL_ARCH))

sub-microos-build-%:
	$(MAKE) COMBARCH=$* microos-build

all-slemicro-build: $(addprefix sub-slemicro-build-,$(ALL_ARCH))

sub-slemicro-build-%:
	$(MAKE) COMBARCH=$* slemicro-build

.PHONY: $(CENTOS7_TARGETS) $(CENTOS8_TARGETS) $(CENTOS9_TARGETS) $(MICROOS_TARGETS) $(SLEMICRO_TARGETS)
