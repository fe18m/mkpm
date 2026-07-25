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

define @monorepo_submake
$(MAKE) -C ./$(1) $(2)
endef

FORCE:
.PHONY: FORCE

define @monorepo_set_dirs
$(if $(@monorepo_dirs),$(error @monorepo_dirs already set: @monorepo_dirs = $(@monorepo_dirs)))$(eval
@monorepo_dirs := $(strip $(1))
$$(addsuffix /%,$(strip $(1))): FORCE
	$(quiet)$$(call $$(@)_submake,$$(@D),$$(notdir $$@))
)
endef

# Global help hook
define help_hook
$(quiet)$(foreach dir,$(@monorepo_dirs),$(call @monorepo_submake,$(dir),help) &&) true
endef