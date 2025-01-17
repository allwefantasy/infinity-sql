#!/bin/bash

# Byzer-Lang 全量打包脚本
# 支持平台： 
#   - darwin-amd64 (Intel Mac)
#   - darwin-arm64 (Apple Silicon Mac)
#   - linux-amd64 (Linux x86_64)
#   - windows-amd64 (Windows x86_64)
#
# 生成目录结构：
# byzer-lang-all-in-one-{os}-{arch}-{spark_version}-{byzer_version}/
# ├── bin/               # 可执行文件目录
# ├── conf/              # 配置文件目录
# ├── jdk8/              # JDK 8 运行环境
# ├── libs/              # 依赖库目录
# ├── logs/              # 日志目录
# ├── main/              # 主程序jar包目录
# ├── plugin/            # 插件目录
# ├── spark/             # Spark 运行环境
#
# 主要功能：
# 1. 自动下载并配置 JDK 8 运行环境
# 2. 自动下载并配置 Spark 运行环境
# 3. 构建并打包 Byzer-Lang 主程序
# 4. 构建并打包扩展插件
# 5. 生成各平台的 CLI 工具
# 6. 创建最终的发布包
#
# 环境要求：
# - Bash 4.0+
# - curl
# - tar
# - unzip (Windows)
# - Maven (用于构建扩展插件)

set -e

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

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

SPARK_VERSION="3.3.0"
SHORT_SPARK_VERSION="3.3"

# Get version from Maven project
BYZER_LANG_VERSION=$(cd ${ROOT_DIR} && mvn help:evaluate -Dexpression=project.version -q -DforceStdout)
# Check if current directory is project root
CURRENT_DIR="$(pwd)"
if [ "$CURRENT_DIR" != "$ROOT_DIR" ]; then
    echo "Error: This script must be run from the project root directory: $ROOT_DIR"
    echo "Current directory is: $CURRENT_DIR"
    exit 1
fi

log_section "Starting Byzer-Lang release process"
log "Spark Version: ${SPARK_VERSION}"
log "Byzer-Lang Version: ${BYZER_LANG_VERSION}"

TEMP_DIR="${ROOT_DIR}/tmp/byzer_setup"
log "Creating temporary directory at ${TEMP_DIR}"
mkdir -p "$TEMP_DIR"


download_jdk8() {
    local os_type=$1
    local target_dir=$2
    local arch=""
    
    if [ "$os_type" = "darwin" ]; then
        arch=$(uname -m)
        if [ "$arch" = "x86_64" ]; then
            arch="amd64"
        elif [ "$arch" = "arm64" ]; then
            arch="aarch64"
        else
            echo "Unsupported architecture: $arch"
            exit 1
        fi
    fi
    
    case "$os_type" in
        "darwin-arm64")
            local jdk_filename="jdk8-darwin-arm64.tar.gz"
            if [ ! -f "$TEMP_DIR/$jdk_filename" ]; then
                curl -L "https://corretto.aws/downloads/latest/amazon-corretto-8-aarch64-macos-jdk.tar.gz" -o "$TEMP_DIR/$jdk_filename"
            else
                echo "Using existing JDK8 download from $TEMP_DIR/$jdk_filename"
            fi
            tar -xzf "$TEMP_DIR/$jdk_filename" -C "$TEMP_DIR"
            mv "$TEMP_DIR"/amazon-corretto-8.jdk "$target_dir/jdk8"
            ;;
        "darwin-amd64")
            local jdk_filename="jdk8-darwin-amd64.tar.gz"
            if [ ! -f "$TEMP_DIR/$jdk_filename" ]; then
                curl -L "https://corretto.aws/downloads/latest/amazon-corretto-8-x64-macos-jdk.tar.gz" -o "$TEMP_DIR/$jdk_filename"
            else
                echo "Using existing JDK8 download from $TEMP_DIR/$jdk_filename"
            fi
            tar -xzf "$TEMP_DIR/$jdk_filename" -C "$TEMP_DIR"
            mv "$TEMP_DIR"/amazon-corretto-8.jdk "$target_dir/jdk8"
            ;;
        "linux")
            if [ ! -f "$TEMP_DIR/jdk8-linux.tar.gz" ]; then
                curl -L "https://corretto.aws/downloads/latest/amazon-corretto-8-x64-linux-jdk.tar.gz" -o "$TEMP_DIR/jdk8-linux.tar.gz"
            else
                echo "Using existing JDK8 download from $TEMP_DIR/jdk8-linux.tar.gz"
            fi
            tar -xzf "$TEMP_DIR/jdk8-linux.tar.gz" -C "$TEMP_DIR"
            mv "$TEMP_DIR"/amazon-corretto-8* "$target_dir/jdk8"
            ;;
        "windows")
            if [ ! -f "$TEMP_DIR/jdk8-windows.zip" ]; then
                curl -L "https://corretto.aws/downloads/latest/amazon-corretto-8-x64-windows-jdk.zip" -o "$TEMP_DIR/jdk8-windows.zip"
            else
                echo "Using existing JDK8 download from $TEMP_DIR/jdk8-windows.zip"
            fi
            unzip -q "$TEMP_DIR/jdk8-windows.zip" -d "$TEMP_DIR"
            # Windows JDK has a different directory structure, need to handle it differently
            if [ -d "$TEMP_DIR/jdk1.8.0_432" ]; then
                mv "$TEMP_DIR/jdk1.8.0_432" "$target_dir/jdk8"
            else
                # Handle case where directory name might be different
                mv "$TEMP_DIR"/jdk* "$target_dir/jdk8"
            fi
            ;;
        *)
            echo "Unsupported OS type: $os_type"
            exit 1
            ;;
    esac
}

download_spark() {
    local target_dir=$1
  
    
    if [ ! -f "$TEMP_DIR/spark.tgz" ]; then
        curl -L "https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop3.tgz" -o "$TEMP_DIR/spark.tgz"
    else
        echo "Using existing Spark download from $TEMP_DIR/spark.tgz"
    fi
    
    cd $TEMP_DIR
    if [ ! -d "$TEMP_DIR/spark-${SPARK_VERSION}-bin-hadoop3" ]; then      
        tar -xf "$TEMP_DIR/spark.tgz"
        echo "Extracted Spark archive"
    else
        echo "Using existing Spark directory"
    fi
    
    cp -r "spark-${SPARK_VERSION}-bin-hadoop3" "$target_dir/spark"
}

setup_environment() {
    local os_type=$1
    local target_dir=$2
    
    log "Setting up environment for ${os_type}"
    
    # Create necessary directories
    log "Creating directory structure in ${target_dir}"
    mkdir -p "$target_dir"/{bin,conf,libs,logs,main,plugin}
    
    # Download and setup JDK
    log "Downloading JDK for ${os_type}"
    download_jdk8 "$os_type" "$target_dir"
    
    # Download and setup Spark
    log "Downloading Spark ${SPARK_VERSION}"
    download_spark "$target_dir"
    
    log "Environment setup completed for ${os_type}"
}


build_main_jar() {
  local tar_file="${ROOT_DIR}/byzer-lang-${SPARK_VERSION}-${BYZER_LANG_VERSION}.tar.gz"
  
  if [ ! -f "$tar_file" ]; then
    log "Building main jar package..."
    bash ${ROOT_DIR}/dev/make-distribution.sh
    log "Main jar package built: $tar_file"
  else
    log "Using existing main jar package: $tar_file"
  fi
  
  echo "$tar_file"
}


copy_main_contents() {
    local package_dir="$1"
    local os_type="$2"

    log "Copying main contents to ${package_dir}"
    
    # Create directories for bin, conf, and main
    log "Creating directory structure in ${package_dir}"
    mkdir -p "$package_dir/bin" "$package_dir/conf" "$package_dir/main"
    
    # Create temp directory for extension jar extraction
    local temp_dir=$(mktemp -d)
    
    build_main_jar
    local main_jar="${ROOT_DIR}/byzer-lang-${SPARK_VERSION}-${BYZER_LANG_VERSION}.tar.gz"
    
    log "Extracting main jar package: ${main_jar}"
    tar -xf "${main_jar}" -C "$temp_dir"
    
    # Copy contents to respective directories using loop
    for dir in bin conf main; do
        log "Copying ${dir} directory contents"
        cp -r "$temp_dir/byzer-lang-${SPARK_VERSION}-${BYZER_LANG_VERSION}/${dir}/"* "$package_dir/${dir}/"
    done
    
    log "Cleaning up temporary directory"
    rm -rf "$temp_dir"
    
    # Handle darwin specific scripts
    if [[ "$os_type" == darwin* ]]; then
        log "Processing darwin specific scripts"
        rm -f "$package_dir/bin/byzer.sh"
        mv "$package_dir/bin/byzer-darwin.sh" "$package_dir/bin/byzer.sh"        
    fi

    # Set executable permissions for all files in bin directory
    find "$package_dir/bin" -type f -exec chmod +x {} +
    log "Main contents copied successfully"
}

copy_extension_jars() {
    local package_dir="$1"
    
    extension_version="0.1.0"

    mkdir -p "$package_dir/plugin"

    cd ${ROOT_DIR}/mlsql-extensions
    local extensions=(
      "byzer-llm"
      "mlsql-excel"
    )
    
    log "Checking and building extension jars..."
    for extension in "${extensions[@]}"; do
      local jar_path="${ROOT_DIR}/mlsql-extensions/${extension}/target/${extension}-${SHORT_SPARK_VERSION}_2.12-${extension_version}.jar"
      
      if [ -f "$jar_path" ]; then
        log "Extension ${extension} jar already exists at ${jar_path}, skipping build"
      else
        log "Building ${extension}..."
        bash new_install.sh -module ${extension} -version ${extension_version} -spark ${SHORT_SPARK_VERSION}
        log "Extension built: ${jar_path}"
      fi
      log "Copying ${extension} jar to plugin directory"
      cp "$jar_path" "$package_dir/plugin/"
    done       
    log "Extension jars copied successfully"
}

copy_mlsql_cli() {
    local os="$1"
    local package_dir="$2"
    
    local cli_name
    local target_name
    
    case "$os" in
        "darwin-amd64")
            cli_name="mlsql-darwin-amd64"
            target_name="byzer"
            ;;
        "darwin-arm64")
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
    
    cp "${ROOT_DIR}/mlsql-cli/${cli_name}" "${package_dir}/bin/${target_name}"
    chmod +x "${package_dir}/bin/${target_name}"
}

create_release_packages() {    
    local base_dir="$ROOT_DIR/release/$version"
    
    # Create release directory
    mkdir -p "$base_dir"
    
    # Create packages for each OS
    for os in darwin-amd64 darwin-arm64 linux windows; do
        local package_name
        if [[ "$os" == darwin-* ]]; then
            package_name="byzer-lang-all-in-one-${os}-${SPARK_VERSION}-${BYZER_LANG_VERSION}"
        else
            package_name="byzer-lang-all-in-one-${os}-amd64-${SPARK_VERSION}-${BYZER_LANG_VERSION}"
        fi
        local package_dir="$base_dir/$package_name"
        
        # Create fresh directory
        rm -rf "$package_dir"
        mkdir -p "$package_dir"
        
        # Setup the environment for this OS
        setup_environment "$os" "$package_dir"        
        
        # Extract and copy extension contents
        copy_main_contents "$package_dir" "$os"

        # Copy extension jars to plugin directory
        copy_extension_jars "$package_dir"

        # Copy mlsql-cli binary
        copy_mlsql_cli "$os" "$package_dir"
        
        # Copy libs
        cp -r "$ROOT_DIR"/lib/* "$package_dir/libs"
      
        
        # Create tar.gz archive
        cd "$base_dir"
        tar -czf "${package_name}.tar.gz" "$package_name"
        echo "Created package for $os: ${package_name}.tar.gz"
        cd - > /dev/null
    done
}



# Call the new function to create all packages
create_release_packages
