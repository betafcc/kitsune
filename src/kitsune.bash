# -- VIEW
kitsune_view() {
  printf %b \
         "${kitsune_view_tag[${kitsune_model_tag[key]}]}" \
         "${kitsune_view_path[${kitsune_model_path[key]}]}" \
         "${kitsune_view_git[${kitsune_model_git[key]}]}" \
         "${kitsune_view_arrow[${kitsune_model_arrow[key]}]}"
}

declare -A kitsune_view_tag=(
  [${HOME}/Desktop]='<bold+white:【<cyan:今>】>'
  [${HOME}]='<bold+white:【<yellow:家>】>'
  [/]='<bold+white:【<red:本>】>'
)

declare -A kitsune_view_path=(
  [no_untagged]=''
  [single_untagged]='<bold:${kitsune_model_sys[W]} >'
  [multi_untagged]='<bold:${kitsune_model_path[arrows]} ${kitsune_model_sys[W]} >'
)

declare -A kitsune_view_git=(
  [modified]='<bold+red:❪${kitsune_model_git[branch]}❫ >'
  [staged]='<bold+red:❪${kitsune_model_git[branch]}❫ >'
  [untracked]='<bold+red:❪${kitsune_model_git[branch]}❫ >'
  [behind_ahead]='<bold+yellow:❪${kitsune_model_git[branch]}❫ >'
  [ok]='<bold+cyan:❪${kitsune_model_git[branch]}❫ >'
  [not_repo]=''
)

declare -A kitsune_view_arrow=(
  [erroed_last]='<bold+red:❱ >'
  [has_jobs]='<bold+yellow:❱ >'
  [ok]='<bold:❱ >'
)


# -- MODEL
declare -A kitsune_model_sys=(
  [q]=''
  [j]=''
  [W]=''
  [PWD]=''
)

declare -A kitsune_model_tag=(
  [key]='/'
  [levels]=0
)

declare -A kitsune_model_path=(
  [key]=no_untagged
  [arrows]=''
)

declare -A kitsune_model_git=(
  [key]=not_repo
  [branch]=''
)

declare -A kitsune_model_arrow=(
  [key]=ok
)

# -- UPDATE
kitsune_update() {
  kitsune_update_sys
  kitsune_update_tag
  kitsune_update_path
  kitsune_update_git
  kitsune_update_arrow
}

kitsune_j='\j'
kitsune_W='\W'
kitsune_update_sys() {
    kitsune_model_sys[q]=$?
    kitsune_model_sys[j]="${kitsune_j@P}"
    kitsune_model_sys[W]="${kitsune_W@P}"
    kitsune_model_sys[PWD]="${PWD}"
}

kitsune_update_tag() {
  local dir="${kitsune_model_sys[PWD]}"
  local levels=0

  until [ ${kitsune_view_tag[${dir}]+x} ]; do
    dir="${dir%/*}"
    ((++levels))
  done

  kitsune_model_tag[key]="${dir}"
  kitsune_model_tag[levels]="${levels}"
}

kitsune_update_path() {
  case "${kitsune_model_tag[levels]}" in
    0) kitsune_model_path[key]=no_untagged;;
    1) kitsune_model_path[key]=single_untagged;;
    *)
      kitsune_model_path[key]=multi_untagged
      kitsune_model_path[arrows]=$(for _ in $(seq ${kitsune_model_tag[levels]}); do printf ❯; done)
      ;;
  esac
}

kitsune_update_git() {
  kitsune_model_git[branch]=$(git rev-parse --abbrev-ref HEAD 2> /dev/null)

  if [ -n "${kitsune_model_git[branch]}" ]; then
    if [ ! "$(git diff --name-only --diff-filter=M 2> /dev/null | wc -l )" -eq "0" ]; then
       kitsune_model_git[key]=modified
    elif [ ! "$(git diff --staged --name-only --diff-filter=AM 2> /dev/null | wc -l)" -eq "0" ]; then
      kitsune_model_git[key]=staged
    elif [ ! "$(git ls-files --other --exclude-standard | wc -l)"  -eq "0" ]; then
      kitsune_model_git[key]=untracked
    else
      local number_behind_ahead
      number_behind_ahead="$(git rev-list --count --left-right '@{upstream}...HEAD' 2>/dev/null)"
      if [ ! "0${number_behind_ahead#*	}" -eq 0 -o ! "0${number_behind_ahead%	*}" -eq 0 ]; then
        kitsune_model_git[key]=behind_ahead
      else
        kitsune_model_git[key]=ok
      fi
    fi
  else
    kitsune_model_git[key]=not_repo
  fi
}

kitsune_update_arrow() {
  case "${kitsune_model_sys[q]},${kitsune_model_sys[j]}" in
    0,0) kitsune_model_arrow[key]=ok;;
    0,*) kitsune_model_arrow[key]=has_jobs;;
    *,*) kitsune_model_arrow[key]=erroed_last;;
  esac
}
