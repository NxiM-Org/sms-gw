package main

import (
	"fmt"
	"io"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	rotatelogs "github.com/lestrrat-go/file-rotatelogs"
	"github.com/sirupsen/logrus"
)

func main() {
	fmt.Println("Starting server...")

	logrus.SetFormatter(&logrus.TextFormatter{FullTimestamp: true})

	levelStr := strings.ToLower("info") // Default log level
	level, err := logrus.ParseLevel(levelStr)
	if err != nil || levelStr == "" {
		logrus.Warnf("Invalid log level: %v, using InfoLevel", levelStr)
		level = logrus.InfoLevel
	}
	logrus.SetLevel(level)

	// Get log path from env or use default
	logPath := "./logs"
	if err := os.MkdirAll(logPath, 0755); err != nil {
		logrus.Warnf("Failed to create logs directory: %v", err)
	}

	// Setup file rotatelogs
	logWriter, err := rotatelogs.New(
		fmt.Sprintf("%s/log%%Y%%m%%d.log", logPath), // daily file name
		rotatelogs.WithRotationTime(24*time.Hour),
	)
	if err != nil {
		logrus.Fatalf("Failed to initialize log rotation: %v", err)
	}

	// Set output to both stdout and file
	logrus.SetOutput(io.MultiWriter(os.Stdout, logWriter))
	logrus.Infof("Logging initialized. Output path: %s", logPath)

	r := gin.Default()

	r.GET("/send", func(c *gin.Context) {
		logrus.Infof("Hello, World!")
		c.JSON(http.StatusOK, gin.H{"message": "Hello, World!"})
	})

	r.Run(":8080")
}
