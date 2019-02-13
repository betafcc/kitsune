KITSUNE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
KITSUNE_CLC="${KITSUNE_DIR}/lib/clc/clc"
: "${KITSUNE_CONFIG:=${KITSUNE_DIR}/config.bash}"
__ks_did_preprocess=false


kitsune() {
  case "${1}" in
    preprocess)
      if ! "${__ks_did_preprocess}"; then
        local name key
        for name in template tag; do
          local -n arr="__ks_${name}"
          for key in "${!arr[@]}"; do
            arr[${key}]=$("${KITSUNE_CLC}" --escape "${arr[${key}]}")
          done
        done

        __ks_did_preprocess=true
      fi
    ;;

    activate)
      kitsune preprocess

      if ! [[ ${PROMPT_COMMAND} =~ '__ks_prompt_command;' ]]; then
        PROMPT_COMMAND="__ks_prompt_command;${PROMPT_COMMAND}"
        __ks_old_PS1="${PS1}"
      fi
    ;;

    deactivate)
      if [[ ${PROMPT_COMMAND} =~ '__ks_prompt_command;' ]]; then
        PROMPT_COMMAND="${PROMPT_COMMAND/__ks_prompt_command;/}"
        PS1="${__ks_old_PS1}"
      fi
    ;;
  esac
}

__ks_prompt_command() {
  __ks_update
  PS1="${__ks_PS1@P}"
}

# -- MODEL
declare -A __ks_model=(
  [sys.q]='' [sys.j]='' [sys.W]='' [sys.PWD]=''
  [tag.key]='all' [tag.tagged_part]='/' [tag.untagged_levels]=0
  [path.key]=no_untagged
  [git.key]=not_repo [git.branch]=''
  [arrow.key]=ok
)

# -- VIEW
__ks_PS1=$(for name in tag path git arrow; do
  printf '${__ks_template[%s.${__ks_model[%s.key]}]}' "${name}" "${name}"
done)

declare -A __ks_tag=(
  [${HOME}/Desktop]='<cyan:今>'
  [${HOME}]='<yellow:家>'
  [/]='<red:本>'
)

declare -A __ks_template=(
  [tag.all]='<bold+white:【${__ks_tag[${__ks_model[tag.tagged_part]}]@P}】>'

  [path.no_untagged]=''
  [path.single_untagged]='<bold:${__ks_model[sys.W]} >'
  [path.multi_untagged]='<bold:$(__ks_repeat $((${__ks_model[tag.untagged_levels]} - 1)) ❯) ${__ks_model[sys.W]} >'

  [git.modified]='<bold+red:❪${__ks_model[git.branch]}❫ >'
  [git.staged]='<bold+red:❪${__ks_model[git.branch]}❫ >'
  [git.untracked]='<bold+red:❪${__ks_model[git.branch]}❫ >'
  [git.behind_ahead]='<bold+yellow:❪${__ks_model[git.branch]}❫ >'
  [git.ok]='<bold+cyan:❪${__ks_model[git.branch]}❫ >'
  [git.not_repo]=''

  [arrow.erroed_last]='<bold+red:❱ >'
  [arrow.has_jobs]='<bold+yellow:❱ >'
  [arrow.ok]='<bold:❱ >'
)

__ks_repeat() {
  for _ in $(seq ${1}); do
    printf '%b' "${2}"
  done
}

# -- UPDATE
__ks_update() {
  __ks_update_sys
  __ks_update_tag
  __ks_update_path
  __ks_update_git
  __ks_update_arrow
}

__ks_j='\j'
__ks_W='\W'
__ks_update_sys() {
    __ks_model[sys.q]=$?
    __ks_model[sys.j]="${__ks_j@P}"
    __ks_model[sys.W]="${__ks_W@P}"
    __ks_model[sys.PWD]="${PWD}"
}

__ks_update_tag() {
  local dir="${__ks_model[sys.PWD]}"
  local untagged_levels=0

  until [ ${__ks_tag[${dir}]+x} ]; do
    dir="${dir%/*}"
    if [ -z ${dir} ]; then
      dir=/
      break
    fi
    ((++untagged_levels))
  done

  __ks_model[tag.tagged_part]="${dir}"
  __ks_model[tag.untagged_levels]="${untagged_levels}"
}

__ks_update_path() {
  case "${__ks_model[tag.untagged_levels]}" in
    0) __ks_model[path.key]=no_untagged;;
    1) __ks_model[path.key]=single_untagged;;
    *) __ks_model[path.key]=multi_untagged;;
  esac
}

__ks_update_git() {
  __ks_model[git.branch]=$(git rev-parse --abbrev-ref HEAD 2> /dev/null)

  if [ -n "${__ks_model[git.branch]}" ]; then
    if [ ! "$(git diff --name-only --diff-filter=M 2> /dev/null | wc -l )" -eq "0" ]; then
       __ks_model[git.key]=modified
    elif [ ! "$(git diff --staged --name-only --diff-filter=AM 2> /dev/null | wc -l)" -eq "0" ]; then
      __ks_model[git.key]=staged
    elif [ ! "$(git ls-files --other --exclude-standard | wc -l)"  -eq "0" ]; then
      __ks_model[git.key]=untracked
    else
      local number_behind_ahead
      number_behind_ahead="$(git rev-list --count --left-right '@{upstream}...HEAD' 2>/dev/null)"
      if [ ! "0${number_behind_ahead#*	}" -eq 0 -o ! "0${number_behind_ahead%	*}" -eq 0 ]; then
        __ks_model[git.key]=behind_ahead
      else
        __ks_model[git.key]=ok
      fi
    fi
  else
    __ks_model[git.key]=not_repo
  fi
}

__ks_update_arrow() {
  case "${__ks_model[sys.q]},${__ks_model[sys.j]}" in
    0,0) __ks_model[arrow.key]=ok;;
    0,*) __ks_model[arrow.key]=has_jobs;;
    *,*) __ks_model[arrow.key]=erroed_last;;
  esac
}


if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
  case "${1}" in
    a|activate) kitsune activate;;
    v|view)
      kitsune preprocess
      __ks_prompt_command
      printf %b "${PS1}"
    ;;
  esac
fi
