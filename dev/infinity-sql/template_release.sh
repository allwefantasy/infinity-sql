#!/bin/bash

# Byzer-Lang 基于模板的打包脚本
# 
# 逻辑流程：
# 1. 拷贝整个 base-template 为特定版本目录 (如：infinity-sql-all-in-one-darwin-amd64-3.3.0-1.0.0)
# 2. 重新编译整个项目，获取最新的 main 包和 extension 插件
# 3. 把编译得到的 main 和 extension 拷贝覆盖到对应的 main/plugin 目录
# 4. 使用 jdks 目录下的 JDK 替换对应平台的 jdk8 目录
#
# 支持平台： 
#   - darwin-amd64 (Intel Mac)
#   - darwin-arm64 (Apple Silicon Mac)
#   - linux-amd64 (Linux x86_64)
#   - windows-amd64 (Windows x86_64)
#
# 使用方法：
# ./template_release.sh [--os=darwin-arm64] [--output-dir=./release] [--skip-build]
#
# 参数说明：
# --os: 目标操作系统，默认为 darwin-arm64
# --output-dir: 输出目录，默认为 ./release
# --skip-build: 跳过项目编译，使用现有的构建产物

set -e

# 定义日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log_section() {
    echo ""
    echo "===================================================================="
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "===================================================================="
    echo ""
}

# 获取脚本目录和项目根目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
TEMPLATE_DIR="${SCRIPT_DIR}/release_template/base-template"
JDKS_DIR="${SCRIPT_DIR}/jdks"

# 默认参数
TARGET_OS="darwin-amd64"
OUTPUT_DIR="${ROOT_DIR}/release"
SKIP_BUILD=false
SPARK_VERSION="3.3.0"
SHORT_SPARK_VERSION="3.3"

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        --os=*)
            TARGET_OS="${1#*=}"
            shift
            ;;
        --output-dir=*)
            OUTPUT_DIR="${1#*=}"
            shift
            ;;
        --skip-build)
            SKIP_BUILD=true
            shift
            ;;
        -h|--help)
            echo "使用方法: $0 [选项]"
            echo ""
            echo "选项:"
            echo "  --os=OS              目标操作系统 (darwin-amd64, darwin-arm64, linux, windows)"
            echo "  --output-dir=DIR     输出目录"
            echo "  --skip-build         跳过项目编译，使用现有构建产物"
            echo "  -h, --help           显示此帮助信息"
            echo ""
            echo "示例:"
            echo "  $0 --os=darwin-arm64"
            echo "  $0 --os=linux --output-dir=./dist"
            echo "  $0 --os=windows --skip-build"
            exit 0
            ;;
        *)
            echo "未知参数: $1"
            echo "使用 -h 或 --help 查看帮助"
            exit 1
            ;;
    esac
done

# 获取 Byzer 版本
BYZER_LANG_VERSION=$(cd ${ROOT_DIR} && mvn help:evaluate -Dexpression=project.version -q -DforceStdout)

# 检查必要的目录是否存在
if [ ! -d "$TEMPLATE_DIR" ]; then
    echo "错误: 模板目录不存在: $TEMPLATE_DIR"
    exit 1
fi

if [ ! -d "$JDKS_DIR" ]; then
    echo "错误: JDKs 目录不存在: $JDKS_DIR"
    exit 1
fi

log_section "基于模板的 Byzer-Lang 发布流程开始"
log "项目根目录: ${ROOT_DIR}"
log "模板目录: ${TEMPLATE_DIR}"
log "JDKs 目录: ${JDKS_DIR}"
log "目标操作系统: ${TARGET_OS}"
log "Spark 版本: ${SPARK_VERSION}"
log "Byzer-Lang 版本: ${BYZER_LANG_VERSION}"
log "跳过编译: ${SKIP_BUILD}"
log "输出目录: ${OUTPUT_DIR}"

# 创建输出目录
mkdir -p "$OUTPUT_DIR"

# 定义包名和目录
if [[ "$TARGET_OS" == darwin-* ]]; then
    PACKAGE_NAME="infinity-sql-all-in-one-${TARGET_OS}-${SPARK_VERSION}-${BYZER_LANG_VERSION}"
else
    PACKAGE_NAME="infinity-sql-all-in-one-${TARGET_OS}-amd64-${SPARK_VERSION}-${BYZER_LANG_VERSION}"
fi

PACKAGE_DIR="${OUTPUT_DIR}/${PACKAGE_NAME}"
TEMP_DIR="${ROOT_DIR}/tmp/template_release"

# 创建临时目录
mkdir -p "$TEMP_DIR"

# 步骤1: 拷贝模板结构
log_section "步骤1: 拷贝模板结构"
if [ -d "$PACKAGE_DIR" ]; then
    log "删除现有目录: $PACKAGE_DIR"
    rm -rf "$PACKAGE_DIR"
fi

log "拷贝模板到: $PACKAGE_DIR"
cp -r "$TEMPLATE_DIR" "$PACKAGE_DIR"
log "模板拷贝完成"

# 步骤2: 编译项目（如果需要）
if [ "$SKIP_BUILD" = false ]; then
    log_section "步骤2: 编译项目"
    
    # 编译主包
    log "编译 Byzer-Lang 主包..."
    cd ${ROOT_DIR}
    bash dev/make-distribution.sh
    cd - > /dev/null
    log "主包编译完成"
    
    # 编译扩展插件
    log "编译扩展插件..."
    cd ${ROOT_DIR}/mlsql-extensions
    
    extension_version="0.1.0"
    extensions=("byzer-llm")
    
    for extension in "${extensions[@]}"; do
        log "编译 ${extension}..."
        bash new_install.sh -module ${extension} -version ${extension_version} -spark ${SHORT_SPARK_VERSION}
    done
    
    cd - > /dev/null
    log "扩展插件编译完成"
else
    log_section "步骤2: 跳过编译 (使用现有构建产物)"
fi

# 步骤3: 替换 main 目录
log_section "步骤3: 替换 main 目录"

main_tar="${ROOT_DIR}/byzer-lang-${SPARK_VERSION}-${BYZER_LANG_VERSION}.tar.gz"
if [ ! -f "$main_tar" ]; then
    echo "错误: 主包文件不存在: $main_tar"
    echo "请先运行编译或者移除 --skip-build 参数"
    exit 1
fi

log "解压主包: $main_tar"
temp_extract_dir=$(mktemp -d)
tar -xf "${main_tar}" -C "$temp_extract_dir"

log "清空并替换 main 目录"
rm -rf "${PACKAGE_DIR}/main"/*
cp -r "$temp_extract_dir/byzer-lang-${SPARK_VERSION}-${BYZER_LANG_VERSION}/main/"* "${PACKAGE_DIR}/main/"

# 清理临时解压目录
rm -rf "$temp_extract_dir"
log "main 目录替换完成"

# 步骤4: 替换 plugin 目录
log_section "步骤4: 替换 plugin 目录"

extension_version="0.1.0"
extensions=("byzer-llm")

log "删除旧的特定插件 jar 包"
# 只删除 byzer-llm 和 mlsql-excel 开头的 jar 包
for extension in "${extensions[@]}"; do
    find "${PACKAGE_DIR}/plugin" -name "${extension}*.jar" -delete 2>/dev/null || true
    log "删除旧的 ${extension} jar 包"
done

for extension in "${extensions[@]}"; do
    jar_path="${ROOT_DIR}/mlsql-extensions/${extension}/target/${extension}-${SHORT_SPARK_VERSION}_2.12-${extension_version}.jar"
    
    if [ ! -f "$jar_path" ]; then
        echo "错误: 扩展插件不存在: $jar_path"
        echo "请先运行编译或者移除 --skip-build 参数"
        exit 1
    fi
    
    log "拷贝 ${extension} 到 plugin 目录"
    cp "$jar_path" "${PACKAGE_DIR}/plugin/"
done

log "plugin 目录替换完成"

# 步骤5: 替换 JDK8 目录
log_section "步骤5: 替换 JDK8"

replace_jdk8() {
    local os_type=$1
    local target_dir=$2
    
    local jdk_file=""
    case "$os_type" in
        "darwin-arm64")
            jdk_file="${JDKS_DIR}/jdk8-darwin-arm64.tar.gz"
            ;;
        "darwin-amd64")
            jdk_file="${JDKS_DIR}/jdk8-darwin-amd64.tar.gz"
            ;;
        "linux")
            jdk_file="${JDKS_DIR}/jdk8-linux.tar.gz"
            ;;
        "windows")
            jdk_file="${JDKS_DIR}/jdk8-windows.zip"
            ;;
        *)
            echo "错误: 不支持的操作系统类型: $os_type"
            exit 1
            ;;
    esac
    
    if [ ! -f "$jdk_file" ]; then
        echo "错误: JDK 文件不存在: $jdk_file"
        exit 1
    fi
    
    log "使用 JDK 文件: $jdk_file"
    log "替换目标目录: $target_dir"
    
    # 删除现有的 jdk8 目录
    rm -rf "$target_dir"
    
    # 解压 JDK
    if [[ "$jdk_file" == *.zip ]]; then
        # Windows 平台使用 zip
        unzip -q "$jdk_file" -d "$TEMP_DIR"
        if [ -d "$TEMP_DIR/jdk1.8.0_432" ]; then
            mv "$TEMP_DIR/jdk1.8.0_432" "$target_dir"
        else
            # 处理可能的其他目录名
            mv "$TEMP_DIR"/jdk* "$target_dir"
        fi
    else
        # Unix 平台使用 tar.gz
        tar -xzf "$jdk_file" -C "$TEMP_DIR"
        if [[ "$os_type" == darwin* ]]; then
            mv "$TEMP_DIR"/amazon-corretto-8.jdk "$target_dir"
        else
            mv "$TEMP_DIR"/amazon-corretto-8* "$target_dir"
        fi
    fi
    
    log "JDK8 替换完成"
}

replace_jdk8 "$TARGET_OS" "${PACKAGE_DIR}/jdk8"

# 步骤6: 更新二进制文件和脚本
log_section "步骤6: 更新二进制文件"

update_binaries() {
    local os_type=$1
    
    # 确定 CLI 二进制文件名
    local cli_name
    local target_name
    
    case "$os_type" in
        "darwin-amd64"|"darwin-arm64")
            cli_name="mlsql-darwin-amd64"
            target_name="byzer"
            ;;
        "linux")
            cli_name="mlsql-linux-amd64"
            target_name="byzer"
            ;;
        "windows")
            cli_name="mlsql-windows-amd64.exe"
            target_name="byzer.exe"
            ;;
    esac
    
    # 更新 CLI 二进制文件
    local cli_path="${ROOT_DIR}/mlsql-cli/${cli_name}"
    if [ -f "$cli_path" ]; then
        log "更新 CLI 二进制文件: ${cli_name} -> ${target_name}"
        cp "$cli_path" "${PACKAGE_DIR}/bin/${target_name}"
        chmod +x "${PACKAGE_DIR}/bin/${target_name}"
    else
        log "警告: CLI 二进制文件不存在: $cli_path"
    fi
    
    # 处理 Darwin 平台的特殊脚本
    if [[ "$os_type" == darwin* ]]; then
        if [ -f "${PACKAGE_DIR}/bin/byzer-darwin.sh" ]; then
            log "更新 Darwin 平台启动脚本"
            rm -f "${PACKAGE_DIR}/bin/byzer.sh"
            mv "${PACKAGE_DIR}/bin/byzer-darwin.sh" "${PACKAGE_DIR}/bin/byzer.sh"
        fi
    fi
    
    # 设置 bin 目录下所有文件的可执行权限
    log "设置 bin 目录文件可执行权限"
    find "${PACKAGE_DIR}/bin" -type f -exec chmod +x {} +
}

update_binaries "$TARGET_OS"

# 步骤7: 创建最终打包文件
log_section "步骤7: 创建最终打包文件"

cd "$OUTPUT_DIR"
log "创建压缩包: ${PACKAGE_NAME}.tar.gz"
tar -czf "${PACKAGE_NAME}.tar.gz" "$PACKAGE_NAME"

# 计算文件大小
package_size=$(du -h "${PACKAGE_NAME}.tar.gz" | cut -f1)
log "打包完成，文件大小: ${package_size}"

# 步骤8: 清理临时文件
log_section "步骤8: 清理临时文件"
if [ -d "$TEMP_DIR" ]; then
    rm -rf "$TEMP_DIR"
    log "临时目录已清理"
fi

# 完成
log_section "发布流程完成"
log "生成的包文件: ${OUTPUT_DIR}/${PACKAGE_NAME}.tar.gz"
log "解压后目录: ${PACKAGE_DIR}"
log ""
log "使用方法:"
log "1. 解压: tar -xzf ${PACKAGE_NAME}.tar.gz"
log "2. 进入目录: cd ${PACKAGE_NAME}"
log "3. 启动服务: ./bin/byzer.sh start" 