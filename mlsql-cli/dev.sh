ori=$(pwd)
TARGET=/Users/allwefantasy/projects/mlsql-desktop

make all

cp mlsql-darwin-amd64 $TARGET/mac/bin/byzer
cp mlsql-linux-amd64 $TARGET/linux/bin/byzer
cp mlsql-windows-amd64.exe $TARGET/win/bin/byzer
