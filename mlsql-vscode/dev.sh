MLSQL_LANG_HOME=/Users/allwefantasy/projects/mlsql-desktop

V=${1:-0.0.7}

if [[ "$V" == "app" ]]
then
   rm -rf ./src/mlsql-lang/*
   cp -r ${MLSQL_LANG_HOME}/mac/* ./src/mlsql-lang/
   rm -rf dist out
   mkdir dist out
   rm mlsql-${V}.vsix
   cp -r ./src/mlsql-lang dist/
   exit 0
fi

quoteVersion=$(cat package.json|grep '"version"' |awk -F':' '{print $2}'| awk -F',' '{print $1}' |xargs)

if [[ "${V}" != "${quoteVersion}" ]];then
   echo "version[${quoteVersion}] in package.json is not match with version[${V}] you specified"
   exit 1
fi

MLSQL_LANG_VERSION="amd64-2.3.0-preview"
LNAG_NAME="byzer"

# win mac linux
for os in mac
# for os in win linux mac
do
   echo "deploy vsix"
   rm -rf ./src/mlsql-lang/*
   cp -r ${MLSQL_LANG_HOME}/${os}/* ./src/mlsql-lang/
   rm -rf dist out
   mkdir dist out
   rm mlsql-${V}.vsix
   cp -r ./src/mlsql-lang dist/
   vsce package
   mv mlsql-${V}.vsix ${LNAG_NAME}-lang-${os}-${V}.vsix
   # scp ${LNAG_NAME}-lang-${os}-${V}.vsix mlsql:/data/mlsql/releases 
   # rm -rf ${LNAG_NAME}-lang-${os}-${V}.vsix 

   # echo "deploy mlsql-lang" 
   # cp -r src/mlsql-lang ${LNAG_NAME}-lang-${os}-${MLSQL_LANG_VERSION}
   # tar czvf ${LNAG_NAME}-lang-${os}-${MLSQL_LANG_VERSION}.tar.gz ${LNAG_NAME}-lang-${os}-${MLSQL_LANG_VERSION}
   # scp ${LNAG_NAME}-lang-${os}-${MLSQL_LANG_VERSION}.tar.gz mlsql:/data/mlsql/releases 
   # rm ${LNAG_NAME}-lang-${os}-${MLSQL_LANG_VERSION}.tar.gz
   # rm -rf ${LNAG_NAME}-lang-${os}-${MLSQL_LANG_VERSION}

done