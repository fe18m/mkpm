assert_eq = $(if $(subst x$1,,x$2)$(subst x$2,,x$1),\
  $(error ASSERT $3: expected [$2] got [$1]))

# ---------------------------------------------------------------------------
# Introspection hooks. Three different jobs:
#
#   print-FOO   -> FOO's fully-expanded value (plain variables, and the
#                  SIDE EFFECTS of a template after $(eval $(call ...))).
#
#   value-FOO   -> FOO's RAW body, unexpanded: $1/$2 and $$ left intact.
#                  Use on a define to eyeball the template itself.
#
#   expand-FOO  -> what $(call FOO,a,b,...) PRODUCES — the makefile text that
#                  eval would parse. Arguments come from A1..A6 because call
#                  splits on commas syntactically; passing them as separate
#                  variables means a comma *inside* an argument is safe too.
#                    make expand-add_module A1=net A2=modules/net
#
# value-/expand- print via $(info ...) so the function output is never run
# through the shell (no quoting hazards) and embedded newlines survive.
# ---------------------------------------------------------------------------
print-%: ; @printf '%s' '$* = $($*)'
value-%:  ; @true $(info $(value $*))
expand-%: ; @printf '%s' '$(call $*,$(a1),$(a2),$(a3),$(a4),$(a5),$(a6))'