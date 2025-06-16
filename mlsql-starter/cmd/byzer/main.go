package main

import (
	"fmt"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"

	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

type Config struct {
	JavaHome            string `mapstructure:"java.home"`
	DriverMemory        string `mapstructure:"byzer.server.runtime.driver-memory"`
	DriverPort          string `mapstructure:"streaming.driver.port"`
	SparkName           string `mapstructure:"streaming.name"`
	DataLakePath        string `mapstructure:"streaming.datalake.path"`
	Xmx                 string `mapstructure:"jvm.xmx"`
	KryoBufferSize      string `mapstructure:"spark.kryoserializer.buffer"`
	KryoBufferMax       string `mapstructure:"spark.kryoserializer.buffer.max"`
	PluginClazznames    string `mapstructure:"streaming.plugin.clzznames"`
	EnableHiveSupport   string `mapstructure:"streaming.enableHiveSupport"`
	PathSchemas         string `mapstructure:"spark.mlsql.path.schemas"`
	DryRun              string `mapstructure:"byzer.server.dryrun"`
	ThriftServer        string `mapstructure:"streaming.thrift"`
	SparkService        string `mapstructure:"streaming.spark.service"`
	JobCancel           string `mapstructure:"streaming.job.cancel"`
	Platform            string `mapstructure:"streaming.platform"`
	ServerMode          string `mapstructure:"byzer.server.mode"`
	RestService         string `mapstructure:"streaming.rest"`
	Serializer          string `mapstructure:"spark.serializer"`
	SchedulerMode       string `mapstructure:"spark.scheduler.mode"`
	HiveThriftSession   string `mapstructure:"spark.sql.hive.thriftServer.singleSession"`
}

var (
	configPath string
	rootCmd    = &cobra.Command{
		Use:   "byzer",
		Short: "Byzer-lang启动器",
		Long:  `用于启动Byzer-lang的命令行工具，支持读取配置文件并生成相应的Java启动命令`,
		Run:   runByzer,
	}
)

func main() {
	rootCmd.PersistentFlags().StringVarP(&configPath, "config", "c", "", "配置文件目录路径")
	
	if err := rootCmd.Execute(); err != nil {
		fmt.Fprintf(os.Stderr, "执行错误: %v\n", err)
		os.Exit(1)
	}
}

func runByzer(cmd *cobra.Command, args []string) {
	// 获取可执行文件所在目录
	execPath, err := os.Executable()
	if err != nil {
		log.Fatalf("无法获取可执行文件路径: %v", err)
	}
	
	binDir := filepath.Dir(execPath)
	baseDir := filepath.Dir(binDir) // 上级目录
	
	// 如果未指定配置路径，则使用默认路径
	if configPath == "" {
		configPath = filepath.Join(baseDir, "conf")
	}
	
	// 读取配置
	config, err := loadConfig(configPath)
	if err != nil {
		log.Fatalf("加载配置失败: %v", err)
	}
	
	// 构建并执行命令
	if err := executeByzerCommand(baseDir, config); err != nil {
		log.Fatalf("执行命令失败: %v", err)
	}
}

func loadConfig(configDir string) (*Config, error) {
	// 设置配置文件搜索路径
	viper.AddConfigPath(configDir)
	viper.SetConfigType("properties")
	
	// 读取主配置文件
	viper.SetConfigName("byzer")
	if err := viper.ReadInConfig(); err != nil {
		return nil, fmt.Errorf("读取byzer.properties失败: %w", err)
	}
	
	// 读取覆盖配置文件
	overwriteFile := filepath.Join(configDir, "byzer.properties.overwrite")
	if _, err := os.Stat(overwriteFile); err == nil {
		viper.SetConfigName("byzer.properties")
		viper.SetConfigFile(overwriteFile)
		if err := viper.MergeInConfig(); err != nil {
			return nil, fmt.Errorf("读取byzer.properties.overwrite失败: %w", err)
		}
	}
	
	// 解析配置到结构体
	var config Config
	if err := viper.Unmarshal(&config); err != nil {
		return nil, fmt.Errorf("解析配置失败: %w", err)
	}
	
	// 设置默认值
	setDefaults(&config)
	
	return &config, nil
}

func setDefaults(config *Config) {
	if config.JavaHome == "" {
		config.JavaHome = os.Getenv("JAVA_HOME")
	}
	if config.DriverMemory == "" {
		config.DriverMemory = "6g"
	}
	if config.Xmx == "" {
		config.Xmx = "6g"
	}
	if config.DriverPort == "" {
		config.DriverPort = "9004"
	}
	if config.SparkName == "" {
		config.SparkName = "Byzer-lang-desktop"
	}
	if config.DataLakePath == "" {
		config.DataLakePath = "./data/"
	}
	if config.KryoBufferSize == "" {
		config.KryoBufferSize = "256k"
	}
	if config.KryoBufferMax == "" {
		config.KryoBufferMax = "1024m"
	}
	if config.PluginClazznames == "" {
		config.PluginClazznames = "tech.mlsql.plugins.llm.LLMApp,tech.mlsql.plugins.visualization.ByzerVisualizationApp,tech.mlsql.plugins.ds.MLSQLExcelApp,tech.mlsql.plugins.assert.app.MLSQLAssert,tech.mlsql.plugins.shell.app.MLSQLShell,tech.mlsql.plugins.mllib.app.MLSQLMllib"
	}
	if config.EnableHiveSupport == "" {
		config.EnableHiveSupport = "false"
	}
	if config.PathSchemas == "" {
		config.PathSchemas = "oss,s3a,s3,abfs,file"
	}
	if config.DryRun == "" {
		config.DryRun = "false"
	}
	if config.ThriftServer == "" {
		config.ThriftServer = "false"
	}
	if config.SparkService == "" {
		config.SparkService = "true"
	}
	if config.JobCancel == "" {
		config.JobCancel = "true"
	}
	if config.Platform == "" {
		config.Platform = "spark"
	}
	if config.ServerMode == "" {
		config.ServerMode = "all-in-one"
	}
	if config.RestService == "" {
		config.RestService = "true"
	}
	if config.Serializer == "" {
		config.Serializer = "org.apache.spark.serializer.KryoSerializer"
	}
	if config.SchedulerMode == "" {
		config.SchedulerMode = "FAIR"
	}
	if config.HiveThriftSession == "" {
		config.HiveThriftSession = "true"
	}
}

func executeByzerCommand(baseDir string, config *Config) error {
	// 构建Java命令
	javaCmd := []string{}
	
	// Java路径
	var javaPath string
	if config.JavaHome != "" {
		javaPath = filepath.Join(config.JavaHome, "bin", "java")
	} else {
		javaPath = "java"
	}
	
	// 添加JVM参数
	javaCmd = append(javaCmd, "-Xmx"+config.Xmx)
	
	// 构建classpath
	classpath := buildClasspath(baseDir)
	javaCmd = append(javaCmd, "-cp", classpath)
	
	// 主类
	javaCmd = append(javaCmd, "tech.mlsql.example.app.LocalSparkServiceApp")
	
	// 添加应用程序参数
	javaCmd = append(javaCmd, "-byzer.server.runtime.driver-memory", config.DriverMemory)
	javaCmd = append(javaCmd, "-spark.kryoserializer.buffer", config.KryoBufferSize)
	javaCmd = append(javaCmd, "-streaming.plugin.clzznames", config.PluginClazznames)
	javaCmd = append(javaCmd, "-streaming.spark.service", config.SparkService)
	javaCmd = append(javaCmd, "-streaming.job.cancel", config.JobCancel)
	javaCmd = append(javaCmd, "-streaming.driver.port", config.DriverPort)
	javaCmd = append(javaCmd, "-streaming.platform", config.Platform)
	javaCmd = append(javaCmd, "-streaming.name", config.SparkName)
	javaCmd = append(javaCmd, "-streaming.thrift", config.ThriftServer)
	javaCmd = append(javaCmd, "-spark.kryoserializer.buffer.max", config.KryoBufferMax)
	javaCmd = append(javaCmd, "-spark.sql.hive.thriftServer.singleSession", config.HiveThriftSession)
	javaCmd = append(javaCmd, "-spark.scheduler.mode", config.SchedulerMode)
	javaCmd = append(javaCmd, "-byzer.server.mode", config.ServerMode)
	javaCmd = append(javaCmd, "-spark.serializer", config.Serializer)
	javaCmd = append(javaCmd, "-streaming.rest", config.RestService)
	javaCmd = append(javaCmd, "-streaming.datalake.path", config.DataLakePath)
	javaCmd = append(javaCmd, "-byzer.server.dryrun", config.DryRun)
	javaCmd = append(javaCmd, "-streaming.enableHiveSupport", config.EnableHiveSupport)
	javaCmd = append(javaCmd, "-spark.mlsql.path.schemas", config.PathSchemas)
	
	// 构建完整命令
	var fullCmd *exec.Cmd
	
	if runtime.GOOS == "darwin" {
		// macOS需要设置环境变量
		cmdStr := "export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES && " + javaPath + " " + strings.Join(javaCmd, " ")
		fullCmd = exec.Command("/bin/bash", "-c", cmdStr)
	} else {
		// Windows和Linux直接执行
		fullCmd = exec.Command(javaPath, javaCmd...)
	}
	
	// 设置输入输出
	fullCmd.Stdout = os.Stdout
	fullCmd.Stderr = os.Stderr
	fullCmd.Stdin = os.Stdin
	
	fmt.Printf("执行命令: %s %s\n", javaPath, strings.Join(javaCmd, " "))
	
	// 执行命令
	return fullCmd.Run()
}

func buildClasspath(baseDir string) string {
	classpaths := []string{
		filepath.Join(baseDir, "main", "byzer-lang-3.3.0-2.12-2.4.0.jar"),
		filepath.Join(baseDir, "spark", "*"),
		filepath.Join(baseDir, "libs", "*"),
		filepath.Join(baseDir, "plugin", "*"),
	}
	
	// 根据操作系统选择分隔符
	separator := ":"
	if runtime.GOOS == "windows" {
		separator = ";"
	}
	
	return strings.Join(classpaths, separator)
} 