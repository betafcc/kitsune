declare -A __ks_template=(
  [tag]='<bold+white:【${__ks_tag[${__ks_model[tag.tagged_part]}]@P}】>'

  [path.no_untagged]=''
  [path.single_untagged]='<bold:${__ks_model[sys.W]} >'
  [path.multi_untagged]='<bold:$(for _ in $(seq $((${__ks_model[tag.untagged_levels]} - 1))); do
    printf ❯
  done) ${__ks_model[sys.W]} >'

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
