COMBARCH ?= x86_64-amd64
ALL_ARCH = x86_64-amd64

CENTOS10_TARGETS := $(addprefix centos10-,$(shell ls rpm/centos10/scripts))
CENTOS8_TARGETS := $(addprefix centos8-,$(shell ls rpm/centos8/scripts))
CENTOS9_TARGETS := $(addprefix centos9-,$(shell ls rpm/centos9/scripts))
MICROOS_TARGETS := $(addprefix microos-,$(shell ls rpm/microos/scripts))
SLEMICRO_TARGETS := $(addprefix slemicro-,$(shell ls rpm/slemicro/scripts))

CURDIR := $(shell pwd)

CENTOS10_IMAGE = centos10-build-image
CENTOS9_IMAGE = centos9-build-image
CENTOS8_IMAGE = centos8-build-image
MICROOS_IMAGE = microos-build-image
SLEMICRO_IMAGE = slemicro-build-image

centos10-image:
	docker buildx build -f Dockerfile.centos10 -t $(CENTOS10_IMAGE) .

centos9-image:
	docker buildx build -f Dockerfile.centos9 -t $(CENTOS9_IMAGE) .

centos8-image:
	docker buildx build -f Dockerfile.centos8 -t $(CENTOS8_IMAGE) .

microos-image:
	docker buildx build -f Dockerfile.microos -t $(MICROOS_IMAGE) .

slemicro-image:
	docker buildx build -f Dockerfile.slemicro -t $(SLEMICRO_IMAGE) .

$(CENTOS8_TARGETS): centos8-image
	docker run --rm \
      -e COMBARCH=$(COMBARCH) \
      -e TAG=$(TAG) \
      -v "$(PWD)/dist:/source/dist" \
      -w /source \
      $(CENTOS8_IMAGE) $(@:centos8-%=%)

$(CENTOS9_TARGETS): centos9-image
	docker run --rm \
      -e COMBARCH=$(COMBARCH) \
      -e TAG=$(TAG) \
      -v "$(PWD)/dist:/source/dist" \
      -w /source \
      $(CENTOS9_IMAGE) $(@:centos9-%=%)

$(CENTOS10_TARGETS): centos10-image
	docker run --rm \
      -e COMBARCH=$(COMBARCH) \
      -e TAG=$(TAG) \
      -v "$(PWD)/dist:/source/dist" \
      -w /source \
      $(CENTOS10_IMAGE) $(@:centos10-%=%)

$(MICROOS_TARGETS): microos-image
	docker run --rm \
      -e COMBARCH=$(COMBARCH) \
      -e TAG=$(TAG) \
      -v "$(PWD)/dist:/source/dist" \
      -w /source \
      $(MICROOS_IMAGE) $(@:microos-%=%)

$(SLEMICRO_TARGETS): slemicro-image
	docker run --rm \
      -e COMBARCH=$(COMBARCH) \
      -e TAG=$(TAG) \
      -v "$(PWD)/dist:/source/dist" \
      -w /source \
      $(SLEMICRO_IMAGE) $(@:slemicro-%=%)


all-centos8-build: $(addprefix sub-centos8-build-,$(ALL_ARCH))

sub-centos8-build-%:
	$(MAKE) COMBARCH=$* centos8-build

all-centos9-build: $(addprefix sub-centos9-build-,$(ALL_ARCH))

sub-centos9-build-%:
	$(MAKE) COMBARCH=$* centos9-build

all-centos10-build: $(addprefix sub-centos10-build-,$(ALL_ARCH))

sub-centos10-build-%:
	$(MAKE) COMBARCH=$* centos10-build

all-microos-build: $(addprefix sub-microos-build-,$(ALL_ARCH))

sub-microos-build-%:
	$(MAKE) COMBARCH=$* microos-build

all-slemicro-build: $(addprefix sub-slemicro-build-,$(ALL_ARCH))

sub-slemicro-build-%:
	$(MAKE) COMBARCH=$* slemicro-build

.PHONY: centos8-image centos9-image centos10-image microos-image slemicro-image
.PHONY: $(CENTOS10_TARGETS) $(CENTOS8_TARGETS) $(CENTOS9_TARGETS) $(MICROOS_TARGETS) $(SLEMICRO_TARGETS)
