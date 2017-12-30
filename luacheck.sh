
if test -f '/usr/bin/luacheck' || test -f '/usr/local/bin/luacheck'; then
	luacheck lua_src/* --no-max-string-line-length --no-max-comment-line-length --no-max-line-length || exit 1
else
	echo 'No luacheck found, nothing to test.'
	exit 0
fi
