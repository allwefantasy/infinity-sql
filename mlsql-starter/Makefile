# Go项目编译配置
BINARY_NAME=byzer-starter
MAIN_PATH=./cmd/byzer
VERSION?=1.0.0
BUILD_TIME=$(shell date -u '+%Y-%m-%d_%H:%M:%S')
GIT_COMMIT=$(shell git rev-parse --short HEAD)

# 编译标志
LDFLAGS=-X main.version=$(VERSION) -X main.buildTime=$(BUILD_TIME) -X main.gitCommit=$(GIT_COMMIT)

# 默认编译当前平台
.PHONY: build
build:
	go build -ldflags "$(LDFLAGS)" -o bin/$(BINARY_NAME) $(MAIN_PATH)

# 清理构建文件
.PHONY: clean
clean:
	rm -rf bin/
	rm -rf dist/

# 安装依赖
.PHONY: deps
deps:
	go mod tidy
	go mod download

# 编译所有支持的平台
.PHONY: build-all
build-all: clean
	@echo "编译所有支持的平台..."
	
	# Linux AMD64
	@echo "编译 Linux AMD64..."
	GOOS=linux GOARCH=amd64 go build -ldflags "$(LDFLAGS)" -o dist/$(BINARY_NAME)-linux-amd64 $(MAIN_PATH)
	
	# Linux ARM64  
	@echo "编译 Linux ARM64..."
	GOOS=linux GOARCH=arm64 go build -ldflags "$(LDFLAGS)" -o dist/$(BINARY_NAME)-linux-arm64 $(MAIN_PATH)
	
	# Windows AMD64
	@echo "编译 Windows AMD64..."
	GOOS=windows GOARCH=amd64 go build -ldflags "$(LDFLAGS)" -o dist/$(BINARY_NAME)-windows-amd64.exe $(MAIN_PATH)
	
	# Windows ARM64
	@echo "编译 Windows ARM64..."
	GOOS=windows GOARCH=arm64 go build -ldflags "$(LDFLAGS)" -o dist/$(BINARY_NAME)-windows-arm64.exe $(MAIN_PATH)
	
	# macOS AMD64
	@echo "编译 macOS AMD64..."
	GOOS=darwin GOARCH=amd64 go build -ldflags "$(LDFLAGS)" -o dist/$(BINARY_NAME)-darwin-amd64 $(MAIN_PATH)
	
	# macOS ARM64 (Apple Silicon)
	@echo "编译 macOS ARM64..."
	GOOS=darwin GOARCH=arm64 go build -ldflags "$(LDFLAGS)" -o dist/$(BINARY_NAME)-darwin-arm64 $(MAIN_PATH)
	
	@echo "编译完成！文件位于 dist/ 目录"

# 只编译macOS版本
.PHONY: build-macos
build-macos: clean
	@echo "编译macOS版本..."
	GOOS=darwin GOARCH=amd64 go build -ldflags "$(LDFLAGS)" -o dist/$(BINARY_NAME)-darwin-amd64 $(MAIN_PATH)
	GOOS=darwin GOARCH=arm64 go build -ldflags "$(LDFLAGS)" -o dist/$(BINARY_NAME)-darwin-arm64 $(MAIN_PATH)
	@echo "macOS编译完成！"

# 只编译Linux版本
.PHONY: build-linux
build-linux: clean
	@echo "编译Linux版本..."
	GOOS=linux GOARCH=amd64 go build -ldflags "$(LDFLAGS)" -o dist/$(BINARY_NAME)-linux-amd64 $(MAIN_PATH)
	GOOS=linux GOARCH=arm64 go build -ldflags "$(LDFLAGS)" -o dist/$(BINARY_NAME)-linux-arm64 $(MAIN_PATH)
	@echo "Linux编译完成！"

# 只编译Windows版本
.PHONY: build-windows
build-windows: clean
	@echo "编译Windows版本..."
	GOOS=windows GOARCH=amd64 go build -ldflags "$(LDFLAGS)" -o dist/$(BINARY_NAME)-windows-amd64.exe $(MAIN_PATH)
	GOOS=windows GOARCH=arm64 go build -ldflags "$(LDFLAGS)" -o dist/$(BINARY_NAME)-windows-arm64.exe $(MAIN_PATH)
	@echo "Windows编译完成！"

# 运行测试
.PHONY: test
test:
	go test -v ./...

# 代码格式化
.PHONY: fmt
fmt:
	go fmt ./...

# 代码检查
.PHONY: vet
vet:
	go vet ./...

# 完整的质量检查
.PHONY: check
check: fmt vet test

# 创建发布包
.PHONY: release
release: build-all
	@echo "创建发布包..."
	@mkdir -p release
	
	# 创建各平台的tar包
	@cd dist && tar -czf ../release/$(BINARY_NAME)-linux-amd64-$(VERSION).tar.gz $(BINARY_NAME)-linux-amd64
	@cd dist && tar -czf ../release/$(BINARY_NAME)-linux-arm64-$(VERSION).tar.gz $(BINARY_NAME)-linux-arm64
	@cd dist && tar -czf ../release/$(BINARY_NAME)-darwin-amd64-$(VERSION).tar.gz $(BINARY_NAME)-darwin-amd64
	@cd dist && tar -czf ../release/$(BINARY_NAME)-darwin-arm64-$(VERSION).tar.gz $(BINARY_NAME)-darwin-arm64
	@cd dist && zip -q ../release/$(BINARY_NAME)-windows-amd64-$(VERSION).zip $(BINARY_NAME)-windows-amd64.exe
	@cd dist && zip -q ../release/$(BINARY_NAME)-windows-arm64-$(VERSION).zip $(BINARY_NAME)-windows-arm64.exe
	
	@echo "发布包创建完成！位于 release/ 目录"

# 开发环境运行
.PHONY: run
run:
	go run $(MAIN_PATH)

# 显示帮助信息
.PHONY: help
help:
	@echo "可用的Make目标："
	@echo "  build        - 编译当前平台版本"
	@echo "  build-all    - 编译所有支持的平台版本"
	@echo "  build-macos  - 只编译macOS版本"
	@echo "  build-linux  - 只编译Linux版本"
	@echo "  build-windows- 只编译Windows版本"
	@echo "  clean        - 清理构建文件"
	@echo "  deps         - 安装依赖"
	@echo "  test         - 运行测试"
	@echo "  fmt          - 代码格式化"
	@echo "  vet          - 代码检查"
	@echo "  check        - 完整的质量检查"
	@echo "  release      - 创建发布包"
	@echo "  run          - 开发环境运行"
	@echo "  help         - 显示此帮助信息" 