## mkpm bootstrap
ifndef mkpm_included
ifeq ($(filter grouped-target,$(.FEATURES)),)
$(error mkpm requires GNU Make >= 4.3 (found $(MAKE_VERSION)). On macOS: brew install make, then use 'gmake')
endif
mkpm_dir := $(subst mkpm_dir=,,$(filter mkpm_dir=%,$(or $(file < .mkpmrc.local),$(file < .mkpmrc))))
ifneq ($(mkpm_dir),)
include $(if $(filter /%,$(mkpm_dir)),$(mkpm_dir),$(abspath $(mkpm_dir)))/Makefile
else
mkpm: REMOTE ?= https://mkpm.io/Makefile
mkpm:
	@curl -fsSL $(REMOTE) -o $@ || { echo "Failed to download $@ from $(REMOTE)" >&2; exit 1; }
include mkpm
endif
endif
## /mkpm bootstrap

define @docker_call
docker $(1) $(strip $(2))
endef

define @docker_run_call
$(call @docker_call,run --rm $(strip $(2)))
endef

$(call mkpm_help,docker-network-create,Create docker network)
docker-network-create:
	$(call @docker_call,network create $(ARGS))

$(call mkpm_help,docker-network-rm,Remove docker network)
docker-network-rm:
	$(call @docker_call,network rm $(ARGS))