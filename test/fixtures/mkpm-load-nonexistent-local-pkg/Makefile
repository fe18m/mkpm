## mkpm bootstrap
ifndef mkpm_included
ifeq ($(filter grouped-target,$(.FEATURES)),)
$(error mkpm requires GNU Make >= 4.3 (found $(MAKE_VERSION)). On macOS: brew install make, then use 'gmake')
endif
MKPM_REGISTRY := ghcr.io/codextremist
mkpm_dir := $(subst mkpm_dir=,,$(filter mkpm_dir=%,$(or $(file < .mkpmrc.local),$(file < .mkpmrc))))
ifneq ($(mkpm_dir),)
include $(if $(filter /%,$(mkpm_dir)),$(mkpm_dir),$(abspath $(mkpm_dir)))/Makefile
else
mkpm: REMOTE ?= https://raw.githubusercontent.com/codextremist/mkpm/refs/heads/master/Makefile
mkpm:
	@curl -fsSL $(REMOTE) -o $@ || { \
	  echo "Failed to download $@ from $(REMOTE)" >&2; \
	  exit 1; \
	}
include mkpm
endif
endif
## /mkpm bootstrap

# mock download method
define mkpm_download
$(info Downloading package $(1)$(if $(2),:$(2))...)
endef

$(call mkpm_load,pkg-not-found)