+strict

kitsune_prompt() {
  local exit_code=$?
  local job_count=$(jobs -p | wc -l)
  local pwd="${PWD}"

  export exit_code job_count pwd
  for section in "${kitsune_ps1_sections[@]}"; do
    "kitsune_${section}"
  done
}

kitsune_dump() {
  local key
  local -n arr="${1}"

  printf '"%s": {\n' "${1}"
  for key in "${!arr[@]}"; do
    printf '    '
    echo "\"${key}\": \"${arr[${key}]}\""
  done
  printf '}\n'
}

kitsune_preprocess() {
  local key
  local -n arr="${1}"

  for key in "${!arr[@]}"; do
    arr[${key}]="$(printf '%b' "${arr[${key}]}" | ,clc)"
  done
}

kitsune_preprocess_all() {
  local key
  for key in path_tags path_templates git_templates arrow_templates; do
    kitsune_preprocess "kitsune_${key}"
  done
}

kitsune_path() {
  kitsune_path_section "${pwd}"
}

kitsune_path_section() (
  w="${1}"
  W="$(basename "${w}")"

  set +u
  dir="${w}"
  n_untagged=0
  while [ ! "${tag:=${kitsune_path_tags[${dir}]}}" ]; do
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
  result=$(envsubst <<< "${kitsune_path_templates[${path_case}]}")
  printf '%b' "${result@P}"
)

kitsune_git() {
  local state
  local branch=$(git rev-parse --abbrev-ref HEAD 2> /dev/null)

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

    kitsune_git_section "${branch}" "${state}"
  fi
}

kitsune_git_section() (
  branch="${1}"
  state="${2}"

  export branch
  set +u
  printf '%b' "$(envsubst <<< "${kitsune_git_templates[${state}]}")"
)

kitsune_arrow() {
  kitsune_arrow_section "${exit_code}" "${job_count}"
}

kitsune_arrow_section() (
  exit_code="${1}"
  job_count="${2}"

  case "${exit_code},${job_count}" in
    0,0) state=ok;;
    0,*) state=has_jobs;;
    *) state=erroed_last;;
  esac

  printf '%b' "${kitsune_arrow_templates[${state}]}"
)

declare -A kitsune_path_tags=(
  [${HOME}/Desktop]='<bold + white:【<cyan:今>】>'
  [${HOME}]='<bold + white:【<yellow:家>】>'
  [/]='<bold + white:【<red:本>】>'
)

declare -A kitsune_path_templates=(
  [no_untagged]='${tag}'
  [single_untagged]='${tag}<bold:$W >'
  [multiple_untagged]='${tag}<bold:$(yes ❯ | head -n $((${n_untagged}-1)) | paste -sd "") $W >'
)

declare -A kitsune_git_templates=(
  [modified]='<bold+red:❪${branch}❫ >'
  [staged]='<bold+red:❪${branch}❫ >'
  [untracked]='<bold+red:❪${branch}❫ >'
  [behind_ahead]='<bold+yellow:❪${branch}❫ >'
  [ok]='<bold+cyan:❪${branch}❫ >'
)

declare -A kitsune_arrow_templates=(
  [erroed_last]='<bold+red:❱ >'
  [has_jobs]='<bold+yellow:❱ >'
  [ok]='<bold:❱ >'
)

declare -a kitsune_ps1_sections=(
  'path'
  'git'
  'arrow'
)

# ❯❱▐

# kitsune_preprocess_all
# kitsune_prompt
