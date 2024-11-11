function gpo
git push -u origin "$(git rev-parse --abbrev-ref HEAD)" || return 1
end
