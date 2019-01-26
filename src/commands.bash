# kitsune_clc
# kitsune_dir

kitsune() {
  "kitsune_${1}" "${@:2}"
}

kitsune_activate() {
  if [ "${kitsune_sourced}" != true ]; then
    kitsune_preprocess
  fi

  if [[ ${PROMPT_COMMAND} =~ 'kitsune_prompt_command;' ]]; then
    PROMPT_COMMAND="kitsune_prompt_command;${PROMPT_COMMAND}"
  fi
}

kitsune_prompt_command() {
  kitsune_update
  PS1="$(kitsune_view)"
}

kitsune_deactivate() {
  PROMPT_COMMAND="${PROMPT_COMMAND/kitsune_update_command;/}"
}

kitsune_preprocess() {
  source "${kitsune_dir}/config.bash"
  kitsune_sourced=true

  local key view_name

  for view_name in "${!kitsune_view_@}"; do
    local -n view="${view_name}"

    for key in "${!view[@]}"; do
      view[${key}]="$("${kitsune_clc}" --escape "${view[${key}]}")"
    done
  done
}
