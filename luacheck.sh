
if test -f '/usr/bin/luacheck' || test -f '/usr/local/bin/luacheck'; then
	luacheck lua_src/* || exit 1
else
	echo 'No luacheck found, nothing to test.'
	exit 0
fi
