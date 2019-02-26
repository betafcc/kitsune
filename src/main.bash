declare -A __ks_model=(
  [venv.key]='off'
  [sys.q]='' [sys.j]='' [sys.W]='' [sys.PWD]=''
  [tag.key]='/' [tag.untagged_levels]=0
  [path.key]=no_untagged
  [git.key]=not_repo [git.branch]=''
  [arrow.key]=ok
)

__ks_j='\j'
__ks_W='\W'

kitsune() {
  case "${1}" in
    ps[01234])
      case "${2:---static}" in
        -s|--static)
          set -- "$(echo "${1}" | tr a-z A-Z)"
          printf %b "${__ks_template[prompt.${1}]}"
          ;;

        -c|--current)
          set -- "$(kitsune "${1}" --static)"
          printf %b "${1@P}"
          ;;

        -r|--render)
          kitsune update
          kitsune "${1}" --current
          ;;
      esac
      ;;

    activate)
      if ! [[ ${PROMPT_COMMAND} =~ 'kitsune update;' ]]; then
        PROMPT_COMMAND="kitsune update;${PROMPT_COMMAND}"

        local name
        for name in $(printf '%s\n' "${!__ks_template[@]}" | sed -n 's/^prompt.//p'); do
          __ks_model[prompt.old.${name}]="${!name}"
          export "${name}"="$(kitsune "$(echo "${name}" | tr A-Z a-z)")"
        done

        # for venv module, don't mess with PS1 on venv activation
        VIRTUAL_ENV_DISABLE_PROMPT=true
      fi
      ;;

    deactivate)
      if [[ ${PROMPT_COMMAND} =~ 'kitsune update;' ]]; then
        PROMPT_COMMAND="${PROMPT_COMMAND/kitsune update;/}"

        local name
        for name in $(printf '%s\n' "${!__ks_model[@]}" | sed -n 's/^prompt.old.//p'); do
          export "${name}"="${__ks_model[prompt.old.${name}]}"
        done
      fi
      ;;

    update)
      case "${2:-all}" in
        all)
          # sys need to be first, otherwise, return code won't be right
          kitsune update sys

          kitsune update venv
          kitsune update tag
          kitsune update path
          kitsune update git
          kitsune update arrow
          ;;

        venv)
          if [ -n "$VIRTUAL_ENV" ]; then
            __ks_model[venv.key]=on
          else
            __ks_model[venv.key]=off
          fi
          ;;

        sys)
          __ks_model[sys.q]=$?
          __ks_model[sys.j]="${__ks_j@P}"
          __ks_model[sys.W]="${__ks_W@P}"
          __ks_model[sys.PWD]="${PWD}"
          ;;

        tag)
          local dir="${__ks_model[sys.PWD]}"
          local untagged_levels=0

          until [ ${__ks_template[tag.${dir}]+x} ] || [ -z "${dir}" ]; do
            ((++untagged_levels))
            dir="${dir%/*}"
          done

          __ks_model[tag.key]="${dir:-/}"
          __ks_model[tag.untagged_levels]="${untagged_levels}"
          ;;

        path)
          case "${__ks_model[tag.untagged_levels]}" in
            0) __ks_model[path.key]=no_untagged;;
            1) __ks_model[path.key]=single_untagged;;
            *) __ks_model[path.key]=multi_untagged;;
          esac
          ;;

        git)
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
          ;;

        arrow)
          case "${__ks_model[sys.q]},${__ks_model[sys.j]}" in
            0,0) __ks_model[arrow.key]=ok;;
            0,*) __ks_model[arrow.key]=has_jobs;;
            *,*) __ks_model[arrow.key]=erroed_last;;
          esac
          ;;
      esac
      ;;
  esac
}
