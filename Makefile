COMBARCH ?= x86_64-amd64
RPM_REPOSITORY ?= community
ALL_ARCH = x86_64-amd64
.RECIPEPREFIX := >

RPM_SCRIPTS := build build-common build-server build-agent sign-and-upload version entry
CENTOS10_TARGETS := $(addprefix centos10-,$(RPM_SCRIPTS))
CENTOS8_TARGETS := $(addprefix centos8-,$(RPM_SCRIPTS))
CENTOS9_TARGETS := $(addprefix centos9-,$(RPM_SCRIPTS))
MICROOS_TARGETS := $(addprefix microos-,$(RPM_SCRIPTS))
SLEMICRO_TARGETS := $(addprefix slemicro-,$(RPM_SCRIPTS))
SLE_TARGETS := $(addprefix sle-,$(RPM_SCRIPTS))

CURDIR := $(shell pwd)

$(CENTOS10_TARGETS):
>docker buildx build \
      --target result --output=. \
      --build-arg "COMBARCH=$(COMBARCH)" \
      --build-arg "TAG=$(TAG)" \
      --build-arg "SCRIPT=$(@:centos10-%=%)" \
      --build-arg "RPM_REPOSITORY=$(RPM_REPOSITORY)" \
      -f Dockerfile.centos10 .

$(CENTOS9_TARGETS):
>docker buildx build \
      --target result --output=. \
      --build-arg "COMBARCH=$(COMBARCH)" \
      --build-arg "TAG=$(TAG)" \
      --build-arg "SCRIPT=$(@:centos9-%=%)" \
      --build-arg "RPM_REPOSITORY=$(RPM_REPOSITORY)" \
      -f Dockerfile.centos9 .

$(CENTOS8_TARGETS):
>docker buildx build \
      --target result --output=. \
      --build-arg "COMBARCH=$(COMBARCH)" \
      --build-arg "TAG=$(TAG)" \
      --build-arg "SCRIPT=$(@:centos8-%=%)" \
      --build-arg "RPM_REPOSITORY=$(RPM_REPOSITORY)" \
      -f Dockerfile.centos8 .

$(MICROOS_TARGETS):
>docker buildx build \
      --target result --output=. \
      --build-arg "COMBARCH=$(COMBARCH)" \
      --build-arg "TAG=$(TAG)" \
      --build-arg "SCRIPT=$(@:microos-%=%)" \
      --build-arg "RPM_REPOSITORY=$(RPM_REPOSITORY)" \
      -f Dockerfile.microos .

$(SLEMICRO_TARGETS):
>docker buildx build \
      --target result --output=. \
      --build-arg "COMBARCH=$(COMBARCH)" \
      --build-arg "TAG=$(TAG)" \
      --build-arg "SCRIPT=$(@:slemicro-%=%)" \
      --build-arg "RPM_REPOSITORY=$(RPM_REPOSITORY)" \
      -f Dockerfile.slemicro .

$(SLE_TARGETS):
>docker buildx build \
      --target result --output=. \
      --build-arg "COMBARCH=$(COMBARCH)" \
      --build-arg "TAG=$(TAG)" \
      --build-arg "SCRIPT=$(@:sle-%=%)" \
      --build-arg "RPM_REPOSITORY=$(RPM_REPOSITORY)" \
      -f Dockerfile.sle .

all-centos8-build: $(addprefix sub-centos8-build-,$(ALL_ARCH))

sub-centos8-build-%:
>$(MAKE) COMBARCH=$* centos8-build

all-centos9-build: $(addprefix sub-centos9-build-,$(ALL_ARCH))

sub-centos9-build-%:
>$(MAKE) COMBARCH=$* centos9-build

all-centos10-build: $(addprefix sub-centos10-build-,$(ALL_ARCH))

sub-centos10-build-%:
>$(MAKE) COMBARCH=$* centos10-build

all-microos-build: $(addprefix sub-microos-build-,$(ALL_ARCH))

sub-microos-build-%:
>$(MAKE) COMBARCH=$* microos-build

all-slemicro-build: $(addprefix sub-slemicro-build-,$(ALL_ARCH))

sub-slemicro-build-%:
>$(MAKE) COMBARCH=$* slemicro-build

all-sle-build: $(addprefix sub-sle-build-,$(ALL_ARCH))

sub-sle-build-%:
>$(MAKE) COMBARCH=$* sle-build

.PHONY: $(CENTOS10_TARGETS) $(CENTOS8_TARGETS) $(CENTOS9_TARGETS) $(MICROOS_TARGETS) $(SLEMICRO_TARGETS) $(SLE_TARGETS)
