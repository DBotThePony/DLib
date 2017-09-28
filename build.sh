
rm -rf lua
mkdir lua
moonc -t lua moon/*
cp lua_src/* lua/ -Rv
