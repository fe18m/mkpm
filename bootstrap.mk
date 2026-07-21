define mkpm_bootstrap_tpl
## mkpm bootstrap
ifndef mkpm_included
ifeq ($$(filter grouped-target,$$(.FEATURES)),)
$$(error mkpm requires GNU Make >= 4.3 (found $$(MAKE_VERSION)). On macOS: brew install make, then use 'gmake')
endif
mkpm_dir := $$(subst mkpm_dir=,,$$(filter mkpm_dir=%,$$(or $$(file < .mkpmrc.local),$$(file < .mkpmrc))))
ifneq ($$(mkpm_dir),)
include $$(if $$(filter /%,$$(mkpm_dir)),$$(mkpm_dir),$$(abspath $$(mkpm_dir)))/Makefile
else
mkpm: REMOTE ?= https://raw.githubusercontent.com/codextremist/mkpm/refs/heads/master/Makefile
mkpm:
	@curl -fsSL $$(REMOTE) -o $$@ || { \
	  echo "Failed to download $$@ from $$(REMOTE)" >&2; \
	  exit 1; \
	}
include mkpm
endif
endif
## /mkpm bootstrap

# Using local packages 
# 
# To use local packages, configure the workspace 
# directory in your `.mkpmrc.local` file: 
# 
# ws=/path/to/my/packages 
# 
# MKPM will search this directory when resolving local package dependencies. 
# 
# Loading packages 
# 
# Load the latest available version: 
# $$(call mkpm_load,<package_name>) 
# 
# Load a specific version: 
# $$(call mkpm_load,<package_name>@<version>)
endef

export mkpm_bootstrap_tpl

registry ?=
force    ?=
export registry force

define mkpm_install_sh
set -eu

# Probe /dev/tty in a subshell first: a failing `exec` redirection kills a
# POSIX shell outright, even inside an `if`.
tty_ok=0
if ( exec 3<>/dev/tty ) 2>/dev/null; then
  exec 3<>/dev/tty
  tty_ok=1
fi

say() { [ "$$tty_ok" = 1 ] || return 0; printf "$$@" >&3; }

ask() {
  printf '%s' "$$1" >&3
  read -r _a <&3 || _a=''
  printf '%s' "$$_a"
}

reg="$${registry:-}"

if [ -z "$$reg" ]; then
  [ "$$tty_ok" = 1 ] || { echo "no terminal; pass registry=<address>" >&2; exit 1; }

  say '\n  \033[95mMKPM Setup\033[0m\n\n  Where should packages be pulled from?\n\n'
  say '    1) GitHub Container Registry (ghcr.io)\n'
  say '    2) Another ORAS-compliant registry\n\n'

  while :; do
    case "$$(ask '  Select [1]: ')" in
      ''|1|ghcr|github)
        while :; do
          owner="$$(ask ' Type GitHub username or organization name: ')"
          owner="$$(printf '%s' "$$owner" | tr '[:upper:]' '[:lower:]')"
          case "$$owner" in
            '')           say '  \033[91m!\033[0m required\n'; continue ;;
            -*|*-)        say '  \033[91m!\033[0m cannot start or end with a hyphen\n'; continue ;;
            *[!a-z0-9-]*) say '  \033[91m!\033[0m letters, digits and hyphens only\n'; continue ;;
          esac
          [ "$${#owner}" -le 39 ] || { say '  \033[91m!\033[0m 39 characters maximum\n'; continue; }
          break
        done
        reg="ghcr.io/$$owner"
        break ;;
      2|oras|other)
        while :; do
          addr="$$(ask '  Registry address (e.g. registry.example.com/team): ')"
          addr="$${addr#https://}"; addr="$${addr#http://}"; addr="$${addr%/}"
          case "$$addr" in
            '')            say '  \033[91m!\033[0m required\n'; continue ;;
            *[[:space:]]*) say '  \033[91m!\033[0m no whitespace allowed\n'; continue ;;
            /*|*//*)       say '  \033[91m!\033[0m not a valid registry path\n'; continue ;;
          esac
          break
        done
        reg="$$addr"
        break ;;
      *) say '  \033[91m!\033[0m enter 1 or 2\n' ;;
    esac
  done
fi

case "$$reg" in
  '')            echo "registry is required" >&2; exit 1 ;;
  *[[:space:]]*) echo "registry must not contain whitespace" >&2; exit 1 ;;
esac

case "$$reg" in
  [Gg][Hh][Cc][Rr].[Ii][Oo]/*) reg="$$(printf '%s' "$$reg" | tr '[:upper:]' '[:lower:]')" ;;
esac

[ ! -e Makefile ] || [ "$$force" = 1 ] || {
  echo "Makefile already exists (pass force=1 to overwrite)" >&2; exit 1; }

printf 'reg=%s\n' "$$reg" > .mkpmrc
printf '%s\n' "$$mkpm_bootstrap_tpl" > Makefile
grep -qxF '.mkpmrc.local' .gitignore 2>/dev/null \
  || printf '%s\n' '.mkpmrc.local' >> .gitignore

say '\n  \033[92mSetup complete\033[0m  registry: %s\n\n' "$$reg"
say '\n  Next: create a GitHub Personal Access Token (PAT) (read:packages write:packages scope) at\n  https://github.com/settings/tokens\n\n  Then run \033[96mmake mkpm-plugin-oras-login\033[0m and use the token as\n  your password, or set reg_token=<pat> in .mkpmrc.local\n\n'
endef
export mkpm_install_sh

.PHONY: install
install:
	@sh -c "$$mkpm_install_sh"