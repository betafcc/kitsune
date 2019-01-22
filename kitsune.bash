#!/usr/bin/env bash
case $- in
  *i*) :;;
  *) +strict;;
esac

# ❯❱▐
# -- EXPORTS
kitsune_ps1='$(kitsune_ps1)'
kitsune_ps3='\[\e[31m\]● \[\e[m\]'
kitsune_ps2='\[\e[31m\]▐ \[\e[m\]'
kitsune_ps4='▐ \[\e[1;33m\]${FUNCNAME[0]}:${LINENO}:\[\e[0m\]q '

# -- CONFIGURATION
declare -a kitsune_ps1_sections=(
  'path'
  'git'
  'arrow'
)

declare -a kistune_env_providers=(
  'git'
)

# -- TEMPLATES
declare -A kitsune_template_path_tag=(
  [${HOME}/Desktop]='<bold + white:【<cyan:今>】>'
  [${HOME}]='<bold + white:【<yellow:家>】>'
  [/]='<bold + white:【<red:本>】>'
)

declare -A kitsune_template_path=(
  [no_untagged]='$tag'
  [single_untagged]='$tag<bold:$W >'
  [multiple_untagged]='$tag<bold:$(yes ❯ | head -n $(($n_untagged-1)) | paste -sd "") $W >'
)

declare -A kitsune_template_git=(
  [modified]='<bold+red:❪${branch}❫ >'
  [staged]='<bold+red:❪${branch}❫ >'
  [untracked]='<bold+red:❪${branch}❫ >'
  [behind_ahead]='<bold+yellow:❪${branch}❫ >'
  [ok]='<bold+cyan:❪${branch}❫ >'
  [not_repo]=''
)

declare -A kitsune_template_arrow=(
  [erroed_last]='<bold+red:❱ >'
  [has_jobs]='<bold+yellow:❱ >'
  [ok]='<bold:❱ >'
)

# for exansion with @P
kitsune_j='\j'
kitsune_w='\w'
kitsune_W='\W'

kitsune_ps1() {

  local -A env=(
    [q]=$?
    [j]="${kitsune_j@P}"
    [w]="${kitsune_w@P}"
    [W]="${kitsune_W@P}"
    [PWD]="${PWD}"
  )
  local env_provider

  # NOTE: how to share memory from subshells? Needed for parallelization
  for env_provider in "${kistune_env_providers[@]}"; do
    "kitsune_env_${env_provider}"
  done

  for section in "${kitsune_ps1_sections[@]}"; do
    "kitsune_section_${section}"
  done
}

# -- ENV PROVIDERS
kitsune_env_git() {
  env[git_branch]=$(git rev-parse --abbrev-ref HEAD 2> /dev/null)

  if [ -n "${env[git_branch]}" ]; then
    if [ ! "$(git diff --name-only --diff-filter=M 2> /dev/null | wc -l )" -eq "0" ]; then
       env[git_state]=modified
    elif [ ! "$(git diff --staged --name-only --diff-filter=AM 2> /dev/null | wc -l)" -eq "0" ]; then
      env[git_state]=staged
    elif [ ! "$(git ls-files --other --exclude-standard | wc -l)"  -eq "0" ]; then
      env[git_state]=untracked
    else
      local number_behind_ahead="$(git rev-list --count --left-right '@{upstream}...HEAD' 2>/dev/null)"
      if [ ! "0${number_behind_ahead#*	}" -eq 0 -o ! "0${number_behind_ahead%	*}" -eq 0 ]; then
        env[git_state]=behind_ahead
      else
        env[git_state]=ok
      fi
    fi
  else
    env[git_state]=not_repo
  fi
}

# -- RENDERERS
kitsune_section_path() (
  set +u
  declare tag dir="${env[PWD]}" n_untagged=0
  while [ ! "${tag:=${kitsune_template_path_tag[${dir}]}}" ]; do
    dir="$(dirname "${dir}")"
    n_untagged=$((n_untagged + 1))
  done
  set -u

  case "${n_untagged}" in
    0) path_case=no_untagged;;
    1) path_case=single_untagged;;
    *) path_case=multiple_untagged;;
  esac

  export W="${env[W]}" n_untagged tag
  result=$(envsubst <<< "${kitsune_template_path[${path_case}]}")
  printf '%b' "${result@P}"
)

kitsune_section_git() (
  export branch="${env[git_branch]}"
  set +u
  printf '%b' "$(envsubst <<< "${kitsune_template_git[${env[git_state]}]}")"
)

kitsune_section_arrow() (
  case "${env[q]},${env[j]}" in
    0,0) state=ok;;
    0,*) state=has_jobs;;
    *) state=erroed_last;;
  esac

  printf '%b' "${kitsune_template_arrow[${state}]}"
)

kitsune_preprocess() {
  local template_name key

  for template_name in "${@}"; do
    local -n template_table="${template_name}"

    for key in "${!template_table[@]}"; do
      template_table[${key}]="$(,clc --escape "${template_table[${key}]}")"
    done
  done
}



if [[ "${BASH_SOURCE[0]}" = "${0}" ]]; then
  kitsune_ps1 | ,clc
else
  kitsune_preprocess "${!kitsune_template_@}"

  kitsune_prompt_command() {
    PS1="$(kitsune_ps1)"
  }

  PROMPT_COMMAND="kitsune_prompt_command ; ${PROMPT_COMMAND}"
fi
