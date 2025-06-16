# Byzer-lang 启动器

这是一个用于启动 Byzer-lang 的跨平台命令行工具，使用 Go 语言开发。

## 功能特性

- ✅ 跨平台支持（Windows、macOS、Linux）
- ✅ macOS 支持 amd64 和 arm64 架构
- ✅ 自动读取配置文件
- ✅ 配置文件覆盖机制
- ✅ 自动构建 Java 启动命令
- ✅ macOS 特殊环境变量支持

## 安装和使用

### 编译

```bash
# 安装依赖
make deps

# 编译当前平台版本
make build

# 编译所有支持的平台版本
make build-all

# 只编译 macOS 版本
make build-macos
```

### 使用方法

1. 将编译后的可执行文件放置在 Byzer-lang 发布包的 `bin` 目录下
2. 在 `conf` 目录下创建配置文件
3. 运行启动器

```bash
# 使用默认配置路径
./byzer

# 指定配置文件路径
./byzer -c /path/to/config
```

## 配置文件

### 主配置文件 (byzer.properties)

位于 `conf/byzer.properties`，包含所有的基础配置：

```properties
# Java环境配置
java.home=/Library/Java/JavaVirtualMachines/jdk1.8.0_151.jdk/Contents/Home

# JVM内存配置
jvm.xmx=6g
byzer.server.runtime.driver-memory=6g

# 服务配置
streaming.driver.port=9004
streaming.name=Byzer-lang-desktop

# 更多配置...
```

### 覆盖配置文件 (byzer.properties.overwrite)

位于 `conf/byzer.properties.overwrite`，用于覆盖主配置文件中的设置：

```properties
# 开发环境配置覆盖
streaming.driver.port=9005
jvm.xmx=4g
```

## 支持的配置参数

| 参数名 | 默认值 | 说明 |
|--------|--------|------|
| `java.home` | $JAVA_HOME | Java安装路径 |
| `jvm.xmx` | 6g | JVM最大内存 |
| `byzer.server.runtime.driver-memory` | 6g | Driver内存 |
| `streaming.driver.port` | 9004 | 服务端口 |
| `streaming.name` | Byzer-lang-desktop | 应用名称 |
| `streaming.datalake.path` | ./data/ | 数据湖路径 |
| ... | ... | 更多参数请参考示例配置 |

## 目录结构

启动器期望的目录结构：

```
byzer-lang-release/
├── bin/
│   └── byzer                    # 启动器可执行文件
├── conf/
│   ├── byzer.properties         # 主配置文件
│   └── byzer.properties.overwrite # 覆盖配置文件（可选）
├── main/
│   └── byzer-lang-3.3.0-2.12-2.4.0.jar
├── spark/
│   └── *.jar
├── libs/
│   └── *.jar
└── plugin/
    └── *.jar
```

## 开发

### 项目结构

```
mlsql-starter/
├── cmd/byzer/           # 主程序入口
├── example/             # 示例配置文件
├── Makefile             # 构建脚本
├── go.mod               # Go模块文件
└── README.md            # 项目文档
```

### 可用的 Make 命令

- `make build` - 编译当前平台版本
- `make build-all` - 编译所有支持的平台版本
- `make build-macos` - 只编译macOS版本
- `make build-linux` - 只编译Linux版本
- `make build-windows` - 只编译Windows版本
- `make clean` - 清理构建文件
- `make deps` - 安装依赖
- `make test` - 运行测试
- `make fmt` - 代码格式化
- `make vet` - 代码检查
- `make release` - 创建发布包
- `make help` - 显示帮助信息

## 支持的平台

- **Linux**: amd64, arm64
- **macOS**: amd64, arm64 (Apple Silicon)
- **Windows**: amd64, arm64

## 许可证

本项目采用与 Byzer-lang 相同的开源许可证。 