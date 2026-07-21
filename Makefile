.DELETE_ON_ERROR:
.DEFAULT_GOAL := help

# When $(CURDIR) != $(PWD) it means that -C was set
ifneq ($(CURDIR),$(PWD))
# special target namespace variable
_mkpm_target_ns = $(notdir $(CURDIR))
endif

_mkpm_this := $(lastword $(dir $(abspath $(MAKEFILE_LIST))))
_mkpm_version := 0.0.1
_mkpm_os := $(shell uname -s | tr '[:upper:]' '[:lower:]')
_mkpm_arch := $(patsubst x86_64,amd64,$(patsubst aarch64,arm64,$(shell uname -m)))

$(if $(filter-out linux darwin,$(_mkpm_os)),$(error unsupported OS: $(_mkpm_os)))
$(if $(filter-out amd64 arm64,$(_mkpm_arch)),$(error unsupported arch: $(_mkpm_arch)))

quiet ?= @

MAKEFLAGS += $(file < .makeflags)

define newline


endef

empty :=
space := $(empty) $(empty)
comma := ,

_mkpm_help_text :=

define mkpm_help
$(eval _mkpm_help_text := $(_mkpm_help_text)$(if $(_mkpm_target_ns),$(_mkpm_target_ns)/)$(strip $(1))|$(strip $(2))@@)
endef

_mkpm_pkgs_dir := .mkpkgs
_mkpm_pkgs_loaded :=

define _mkpm_write_config_file
$(file > $(1),$(subst $(space),$(newline),$(strip $(2))))
endef

define _mkpm_sanitize_config_contents
$(subst =$(space),=,$(subst $(space)=,=,$(strip $(1))))
endef

#$(call _mkpm_get,contents,key)
define _mkpm_get
$(subst $(2)=,,$(filter $(2)=%,$(call _mkpm_sanitize_config_contents,$(1))))
endef

#$(call _mkpm_get,key,mkpkg_file = $(file < mkpkg))
define _mkpm_mkpkg_get
$(call _mkpm_get,$(file < $(or $(2),$(CURDIR))/mkpkg),$(1))
endef

#$(call _mkpm_mkpkg_set,key,val,mkpkg_file = mkpkg)
define _mkpm_mkpkg_set
$(call _mkpm_write_config_file,$(or $(3),mkpkg),$(subst $(1)=$(call _mkpm_mkpkg_get,$(1),$(3)),$(1)=$(2),$(file < $(or $(3),mkpkg))))
endef

define _mkpm_pkg_name
$(call _mkpm_mkpkg_get,name,$(1))
endef

define _mkpm_pkg_version
$(or $(call _mkpm_mkpkg_get,version,$(1)),latest)
endef

define _mkpm_pkg_assets
$(subst $(comma), ,$(call _mkpm_mkpkg_get,assets,$(1)))
endef

define _mkpm_pkg_main
$(or $(call _mkpm_mkpkg_get,main,$(1)),Makefile)
endef

#$(call _mkpmrc_get,key,mkpmrc_file = $(file < .mkpmrc))
define _mkpm_mkpmrc_get
$(call _mkpm_get,$(or $(2),$(filter $(1)=%,$(file < .mkpmrc.local)),$(filter $(1)=%,$(file < .mkpmrc))),$(1))
endef

define _mkpm_is_rel_dir
$(if $(filter /%,$(strip $(1))),,t)
endef

define mkpm_dir ?=
$(if $(call _mkpm_mkpmrc_get,mkpm_dir),$(if $(filter /%,$(call _mkpm_mkpmrc_get,mkpm_dir)),$(call _mkpm_mkpmrc_get,mkpm_dir),$(abspath $(call _mkpm_mkpmrc_get,mkpm_dir))))
endef

define _mkpm_ws
$(call _mkpm_mkpmrc_get,ws)
endef

define _mkpm_ws_dir
$(if $(_mkpm_ws),$(if $(call _mkpm_is_rel_dir,$(_mkpm_ws)),$(abspath $(_mkpm_ws)),$(_mkpm_ws)))
endef

define _mkpm_plugins
$(or $(call _mkpm_mkpmrc_get,plugins),+mkpm-oras)
endef

define _mkpm_pkg
$(call _mkpm_pkg_name)@$(call _mkpm_pkg_version)
endef

# Deps
define _mkpm_split
$(subst $(or $(2),@), ,$(1))
endef

# <name>@<version>
define _mkpm_dep_name
$(if $(strip $(word 2,$(call _mkpm_split,$(1)))),$(word 1,$(call _mkpm_split,$(1))),$(1))
endef

define _mkpm_dep_version
$(word 2,$(subst @, ,$(1)))
endef

define _mkpm_dep
$(call _mkpm_dep_name,$(1))$(if $(call _mkpm_dep_version,$(1)),@$(call _mkpm_dep_version,$(1)),)
endef

define _mkpm_pack_files
tar -czf $(call _mkpm_pkg).tgz -C $(CURDIR) $(strip $(call _mkpm_pkg_main) $(call _mkpm_pkg_assets))
endef

define _mkpm_unpack_files
tar -xf $(1).tgz -C $(or $(2),$(_mkpm_pkgs_dir))/$(1)
endef

define _mkpm_semver_major
$(word 1,$(subst ., ,$(call _mkpm_pkg_version)))
endef

define _mkpm_semver_minor
$(word 2,$(subst ., ,$(call _mkpm_pkg_version)))
endef

define _mkpm_semver_patch
$(word 3,$(subst ., ,$(call _mkpm_pkg_version)))
endef

define _mkpm_copy_local_pkg_assets
$(if $(strip $(2)),$(shell for f in $(2); do \
  if [ ! -e "$(CURDIR)/$$f" ]; then \
    mkdir -p "$(CURDIR)/$$(dirname "$$f")"; \
    cp "$(1)/$$f" "$(CURDIR)/$$f"; \
  fi; \
done))
endef

define _mkpm_computed_local_pkg_dir
$(join $(_mkpm_ws_dir),/$(call _mkpm_dep_name,$(1)))
endef

#$(if $(call mkpm_pkg_assets),cp $(call mkpm_pkg_assets) $(CURDIR))
# define _mkpm_load_local_pkg
# $(eval include $(call _mkpm_computed_local_pkg_dir,$(1))/Makefile)
# _mkpm_loaded_pkgs += $(call _mkpm_dep_name,$(1))
# $(eval $(call _mkpm_dep_name,$(1))_ns := $(_ns))
# $(call _mkpm_copy_local_pkg_assets,$(call _mkpm_computed_local_pkg_dir,$(1)),$(call _mkpm_pkg_assets,$(call _mkpm_computed_local_pkg_dir,$(1))))
# endef
define _mkpm_load_local_pkg
$(eval include $(call _mkpm_computed_local_pkg_dir,$(1))/Makefile)
_mkpm_loaded_pkgs += $(call _mkpm_dep_name,$(1))
$(eval @$(call _mkpm_dep_name,$(1)) := $(@))
$(eval undefine $(@))
$(call _mkpm_copy_local_pkg_assets,$(call _mkpm_computed_local_pkg_dir,$(1)),$(call _mkpm_pkg_assets,$(call _mkpm_computed_local_pkg_dir,$(1))))
endef

define _mkpm_load_remote_pkg
include $(_mkpm_pkgs_dir)/$(1)/Makefile
_mkpm_loaded_pkgs += $(1)
$(_mkpm_pkgs_dir)/$(1)/Makefile:
	$(quiet)set -e
	$(quiet)$$(call mkpm_download,$(1))
	$(quiet)mkdir -p $(_mkpm_pkgs_dir)/$(1)
	$(quiet)$$(call _mkpm_unpack_files,$(1))
	$(quiet)rm -f $(1).tgz
endef

define _mkpm_is_pkg_loaded
$(filter $(call _mkpm_dep_name,$(1)),$(_mkpm_loaded_pkgs))
endef

define _mkpm_is_pkg_in_ws
$(and $(_mkpm_ws),$(wildcard $(_mkpm_ws_dir)/$(call _mkpm_dep_name,$(1))))
endef

#$(call mkpm_load,pkg)
define mkpm_load
$(if $(call _mkpm_is_pkg_loaded,$(1)),,$(eval $(if $(call _mkpm_is_pkg_in_ws,$(1)),$(call _mkpm_load_local_pkg,$(1)),$(call _mkpm_load_remote_pkg,$(1)))))
endef

## Registry Plugin
## mkpm_publish and mkpm_download must be implemented by a publishing plugin
# $(1) = pack file, $(2) = pkg name,  $(3) = pkg version
define mkpm_registry
$(or $(call _mkpm_mkpmrc_get,reg),$(MKPM_REGISTRY),$(error $(0) is not implemented.$(newline)$(space)$(space)1. Enable a plugin in .mkpmrc: plugins=mkpm-oras$(space)2. Or define $(0) yourself))
endef

define mkpm_registry_token
$(or $(call _mkpm_mkpmrc_get,reg_token),$(MKPM_REGISTRY_TOKEN),$(error $(0) is not implemented.$(newline)$(space)$(space)1. Enable a plugin in .mkpmrc: plugins=mkpm-oras$(space)2. Or define $(0) yourself))
endef

define mkpm_registry_user
$(or $(call _mkpm_mkpmrc_get,reg_user),$(MKPM_REGISTRY_USER),github,$(error $(0) is not implemented.$(newline)$(space)$(space)1. Enable a plugin in .mkpmrc: plugins=mkpm-oras$(space)2. Or define $(0) yourself))
endef

define mkpm_publish
$(error mkpm_publish is not implemented.$(newline)$(space)$(space)1. Enable a plugin in .mkpmrc: plugins=mkpm-oras$(space)or$(space)plugins=+default$(newline)$(space)$(space)2. Or define mkpm_publish yourself (args: $$(1)=pack file, $$(2)=name, $$(3)=version))
endef

define mkpm_download
$(error mkpm_download is not implemented.$(newline)$(space)$(space)1. Enable a plugin in .mkpmrc: plugins=mkpm-oras$(space)or$(space)plugins=+default$(newline)$(space)$(space)2. Or define mkpm_download yourself (args: $$(1)=pkg name, $$(2)=version))
endef
##

define mkpm_mkpkg
$(file < $(or $(2),mkpkg),name=$(1)$(newline)version=0.0.1$(newline)main=Makefile)
endef

define mkpm_mkpmrc
$(file < $(or $(2),.mkpmrc),reg=ghcr.io/<gh_username>$(newline)plugins=+mkpm-oras)
endef

define _mkpm_default_plugins
$(subst +,$(if $(mkpm_dir),$(mkpm_dir)/plugins/,.mkpm_plugins/),$(filter +%,$(call _mkpm_plugins)))
endef

define _mkpm_custom_plugins 
$(addprefix .mkpm_plugins/,$(filter-out +%,$(call _mkpm_plugins)))
endef

-include $(_mkpm_default_plugins)
-include $(_mkpm_custom_plugins)

ifneq ($(strip $(mkpm_dir)),)
$(mkpm_dir)/plugins/%:
	$(error mkpm plugin '$*' not found in $(mkpm_dir))
endif

.mkpm_plugins/%: REMOTE ?= https://raw.githubusercontent.com/codextremist/mkpm/refs/heads/master/plugins/$*
.mkpm_plugins/%:
	@mkdir -p $(@D)
	@curl -fsSL $(REMOTE) -o $@ || { \
	  echo "mkpm: failed to download plugin '$*' from $(REMOTE)" >&2; \
	  exit 1; \
	}

help:
	@printf '\033[95m📁%s\033[0m\n' '$(if $(_mkpm_target_ns),$(call _mkpm_target_ns),$(lastword $(subst /, ,$(CURDIR))))'
	@printf '%s' '$(_mkpm_help_text)' | awk '{n=split($$0,a,"@@"); for(i=1;i<=n;i++) if(split(a[i],b,"|")==2) {sub(/^[ \t]+/,"",b[1]); sub(/^[ \t]+/,"",b[2]); printf " \033[90m└\033[0m\033[36m%-40s\033[0m %s\n", b[1], b[2]}}'
	$(call help_hook)

ifneq ($(file < mkpkg),)
.PHONY: mkpm-pack
$(call mkpm_help,mkpm-pack,Pack <$(call _mkpm_pkg_name)@$(call _mkpm_pkg_version)> into a .tgz distribution file)
mkpm-pack:
	$(quiet)$(call _mkpm_pack_files)
	@echo Pack $(call _mkpm_pkg).tgz created

$(call mkpm_help,mkpm-pack-rm,Delete any local <$(call _mkpm_pkg_name)@*.tgz> distribution files)
.PHONY: mkpm-pack-rm
mkpm-pack-rm:
	$(quiet)rm -f $(call _mkpm_pkg_name)@*.tgz

$(call mkpm_help,mkpm-publish,Pack and publish <$(call _mkpm_pkg_name)@$(call _mkpm_pkg_version)> to the registry)
.PHONY: mkpm-publish
mkpm-publish: mkpm-pack
	$(quiet)$(call mkpm_publish,$(call _mkpm_pkg).tgz,$(call _mkpm_pkg_name),$(call _mkpm_pkg_version))

$(call mkpm_help,mkpm-semver-bump,Set the package version explicitly. Usage: make mkpm-semver-bump ver=<version>)
.PHONY: mkpm-semver-bump
mkpm-semver-bump: ver ?=
mkpm-semver-bump:
	$(if $(ver),,$(error Missing version. Usage: mkpm-semver-bump ver=1.5.4))
	$(call _mkpm_mkpkg_set,version,$(ver))
	@echo New version $(call _mkpm_mkpkg_get,version)

$(call mkpm_help,mkpm-semver-major,Bump <$(call _mkpm_pkg_name)> major version (X.y.z -> X+1.0.0))
.PHONY: mkpm-semver-major
mkpm-semver-major:
	$(call _mkpm_mkpkg_set,version,$(shell echo $$(($(call _mkpm_semver_major) + 1))).$(call _mkpm_semver_minor).$(call _mkpm_semver_patch))
	@echo New version $(call _mkpm_mkpkg_get,version)

$(call mkpm_help,mkpm-semver-minor,Bump <$(call _mkpm_pkg_name)> minor version (x.Y.z -> x.Y+1.0))
.PHONY: mkpm-semver-minor
mkpm-semver-minor:
	$(call _mkpm_mkpkg_set,version,$(call _mkpm_semver_major).$(shell echo $$(($(call _mkpm_semver_minor) + 1))).$(call _mkpm_semver_patch))
	@echo New version $(call _mkpm_mkpkg_get,version)

$(call mkpm_help,mkpm-semver-patch,Bump <$(call _mkpm_pkg_name)> patch version (x.y.Z -> x.y.Z+1))
.PHONY: mkpm-semver-patch
mkpm-semver-patch:
	$(call _mkpm_mkpkg_set,version,$(call _mkpm_semver_major).$(call _mkpm_semver_minor).$(shell echo $$(($(call mkpm_semver_patch) + 1))))
	@echo New version $(call _mkpm_mkpkg_get,version)
else
mkpm-pack mkpm-publish mkpm-semver-bump mkpm-semver-major mkpm-semver-minor mkpm-semver-patch mkpm-pack-rm:
	$(error Missing mkpkg file)
endif

ifneq ($(wildcard .mkpm_plugins),)
$(call mkpm_help,mkpm-plugins-rm,Delete .mkpm_plugins folder)
.PHONY: mkpm-plugins-rm
mkpm-plugins-rm:
	rm -rf ./mkpm_plugins
endif

$(call mkpm_help,mkpm-init,Initialize a new package (optional: name=<pkg>) in this directory)
.PHONY: mkpm-init
mkpm-init: name ?=
mkpm-init:
	$(quiet)pkg="$(name)"; \
	if [ -z "$$pkg" ]; then \
	  printf "New package name: "; \
	  read -r pkg; \
	fi; \
	case "$$pkg" in \
	  '') echo "mkpm: package name required" >&2; exit 1 ;; \
	  *[!a-zA-Z0-9_-]*) \
	    echo "mkpm: invalid package name '$$pkg'" >&2; \
	    echo "mkpm: only letters, digits, '-' and '_' are allowed" >&2; \
	    exit 1 ;; \
	esac; \
	printf 'name=%s\nversion=0.0.1\nmain=Makefile\n' "$$pkg" > mkpkg; \
	for entry in .mkpmrc.local .mkpm_plugins .mkpkgs *.tgz; do \
	  grep -qxF "$$entry" .gitignore 2>/dev/null || echo "$$entry" >> .gitignore; \
	done; \
	echo "Initialized package '$$pkg'"

-include $(_mkpm_this)/introspect.mk

mkpm_included := true