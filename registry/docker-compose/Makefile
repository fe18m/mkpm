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

define @docker_compose_call
docker compose $(1) $(strip $(2))
endef

$(call mkpm_help,up,Start <$(call _mkpm_target_ns)> stack)
up:
	$(call @docker_compose_call,up)

$(call mkpm_help,down,Stop <$(call _mkpm_target_ns)> stack)
down:
	$(call @docker_compose_call,down)

$(call mkpm_help,down-v,Stop <$(call _mkpm_target_ns)> stack and remove volumes)
down-v: opts ?=
down-v:
	$(call @docker_compose_call,down,-v$(opts))

$(call mkpm_help,images,List <$(call _mkpm_target_ns)> images)
images: opts ?=
images:
	$(call @docker_compose_call,images,$(opts))

$(call mkpm_help,image-push,Push <$(call _mkpm_target_ns)> images)
image-push: opts ?=
image-push:
	$(call @docker_compose_call,push,$(opts))

$(call mkpm_help,image-push-include-deps,Push <$(call _mkpm_target_ns)> images with --include-deps)
image-push-include-deps: opts ?= --include-deps
image-push-include-deps: 
	$(call @docker_compose_call,push,$(opts))

$(call mkpm_help,image-pull,Pull <$(call _mkpm_target_ns)> images)
image-pull: opts ?=
image-pull:
	$(call @docker_compose_call,pull,$(opts))

$(call mkpm_help,image-pull-include-deps,Pull <$(call _mkpm_target_ns)> images with --include-deps)
image-pull-include-deps: opts ?= 
image-pull-include-deps: 
	$(call @docker_compose_call,pull,--include-deps $(opts))

ps: opts ?=
ps:
	$(call @docker_compose_call,ps,$(opts))

ps-all: opts ?=
ps-all:
	$(call @docker_compose_call,ps,--all $(opts))

ps-filter: opts ?=
ps-filter:
	$(call @docker_compose_call,ps,--filter $(opts))

$(call h,logs,Check container logs)
logs: opts ?=
logs:
	$(call @docker_compose_call,logs,$(opts))

$(call h,logs-f,Check container logs with -f)
logs-f: opts ?=
logs-f:
	$(call @docker_compose_call,logs,-f,$(opts))

$(call h,logs-until,Check container logs with --until)
logs-until: args ?= 
logs-until: opts ?= 
logs-until:
	$(call @docker_compose_call,logs,--until=$(until_args)$(opts))

inspect: opts ?=
inspect:
	$(call @docker_compose_call,up,inspect)