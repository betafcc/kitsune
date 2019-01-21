#!/usr/bin/env bash
case $- in
  *i*) :;;
  *) +strict;;
esac

# ❯❱▐
# -- EXPORTS
kitsune_ps1='$(kitsune_run_ps1)'
kitsune_ps3='\[\e[31m\]● \[\e[m\]'
kitsune_ps2='\[\e[31m\]▐ \[\e[m\]'
kitsune_ps4='▐ \[\e[1;33m\]${FUNCNAME[0]}:${LINENO}:\[\e[0m\]q '

# -- CONFIGURATION
declare -a kitsune_ps1_modules=(
  'path'
  'git'
  'arrow'
)

declare -A kitsune_template_path_tag=(
  [${HOME}/Desktop]='<bold + white:【<cyan:今>】>'
  [${HOME}]='<bold + white:【<yellow:家>】>'
  [/]='<bold + white:【<red:本>】>'
)

declare -A kitsune_template_path=(
  [no_untagged]='${tag}'
  [single_untagged]='${tag}<bold:$W >'
  [multiple_untagged]='${tag}<bold:$(yes ❯ | head -n $((${n_untagged}-1)) | paste -sd "") $W >'
)

declare -A kitsune_template_git=(
  [modified]='<bold+red:❪${branch}❫ >'
  [staged]='<bold+red:❪${branch}❫ >'
  [untracked]='<bold+red:❪${branch}❫ >'
  [behind_ahead]='<bold+yellow:❪${branch}❫ >'
  [ok]='<bold+cyan:❪${branch}❫ >'
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

kitsune_run_ps1() {
  q=$? \
   j="${kitsune_j@P}" \
   w="${kitsune_w@P}" \
   W="${kitsune_W@P}" \
   PWD_="${PWD}" \
   kitsune_run_modules kitsune_ps1_modules
}

kitsune_run_modules() {
  local -n modules="${1}"
  for module in "${modules[@]}"; do
    "kitsune_${module}"
  done
}

# -- RUNNERS
kitsune_run_path() {
  kitsune_render_path "${PWD_}" "${W}"
}

kitsune_run_arrow() {
  kitsune_render_arrow "${q}" "${j}"
}

kitsune_run_git() {
  local branch state
  branch=$(git rev-parse --abbrev-ref HEAD 2> /dev/null)

  if [ -n "${branch}" ]; then
    if [ ! "$(git diff --name-only --diff-filter=M 2> /dev/null | wc -l )" -eq "0" ]; then
       state=modified
    elif [ ! "$(git diff --staged --name-only --diff-filter=AM 2> /dev/null | wc -l)" -eq "0" ]; then
      state=staged
    elif [ ! "$(git ls-files --other --exclude-standard | wc -l)"  -eq "0" ]; then
      state=untracked
    else
      local number_behind_ahead="$(git rev-list --count --left-right '@{upstream}...HEAD' 2>/dev/null)"
      if [ ! "0${number_behind_ahead#*	}" -eq 0 -o ! "0${number_behind_ahead%	*}" -eq 0 ]; then
        state=behind_ahead
      else
        state=ok
      fi
    fi

    kitsune_render_git "${branch}" "${state}"
  fi
}

# -- RENDERERS
kitsune_render_path() (
  PWD_="${1}"
  W="${2}"

  set +u
  dir="${PWD_}"
  n_untagged=0
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

  export W n_untagged tag
  result=$(envsubst <<< "${kitsune_template_path[${path_case}]}")
  printf '%b' "${result@P}"
)

kitsune_render_git() (
  branch="${1}"
  state="${2}"

  export branch
  set +u
  printf '%b' "$(envsubst <<< "${kitsune_template_git[${state}]}")"
)

kitsune_render_arrow() (
  q="${1}"
  j="${2}"

  case "${q},${j}" in
    0,0) state=ok;;
    0,*) state=has_jobs;;
    *) state=erroed_last;;
  esac

  printf '%b' "${kitsune_template_arrow[${state}]}"
)

# kitsune_preprocess_all
# kitsune_prompt
