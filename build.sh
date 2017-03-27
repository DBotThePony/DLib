echo 'Moving'
mv lua lua_old || { exit 1; }
mkdir lua || { exit 1; }
echo 'Compiling'
moonc -t lua moon/* || { exit 1; }
echo 'Cleaning up'
rm lua_old -R