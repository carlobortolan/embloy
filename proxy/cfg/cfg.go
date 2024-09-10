package cfg

import (
	"fmt"
	"os"

	"github.com/getsentry/sentry-go"
	"github.com/joho/godotenv"
	log "github.com/sirupsen/logrus"
)

var (
	AdminToken   string
	MainInstance string
	GinMode      string
	LogDir       string
	LogLevel     = log.InfoLevel
)

// SetConfig sets the values of the parameter config and stops the execution
// if any of the required config variables are unset.
func SetConfig() {
	err := godotenv.Load()
	if err != nil {
		log.Fatal("Error loading .env file")
	}

	AdminToken = os.Getenv("ADMIN_TOKEN")
	if AdminToken == "" {
		log.Fatal("Environment variable ADMIN_TOKEN is not set")
	}

	MainInstance = os.Getenv("MAIN_INSTANCE") // e.g., https://embloy.com
	if MainInstance == "" {
		log.Fatal("Environment variable MAIN_INSTANCE is not set")
	}

	GinMode = os.Getenv("GIN_MODE") // e.g., release, debug, test; defaults to debug
	if GinMode == "" {
		GinMode = "debug"
	}

	// Logging
	LogDir = os.Getenv("LOG_DIR")
	if LogDir == "" {
		LogDir = "/var/log/embloy-proxy"
	}
	switch os.Getenv("LOG_LEVEL") {
	case "trace":
		LogLevel = log.TraceLevel
	case "debug":
		LogLevel = log.DebugLevel
	case "info":
		LogLevel = log.InfoLevel
	case "warn":
		LogLevel = log.WarnLevel
	case "error":
		LogLevel = log.ErrorLevel
	case "fatal":
		LogLevel = log.FatalLevel
	case "panic":
		LogLevel = log.PanicLevel
	default:
		LogLevel = log.InfoLevel
	}
	log.SetLevel(LogLevel)

	// err = os.MkdirAll(LogDir, 0o755)
	if err != nil {
		log.Warn("Could not create log directory: ", err)
	}

	// To initialize Sentry's handler, you need to initialize Sentry itself beforehand
	if err := sentry.Init(sentry.ClientOptions{
		Dsn:           "https://dac8c6b65c790d10bbf81fc1b31a127d@o4507920163209216.ingest.de.sentry.io/4507920291463248",
		EnableTracing: true,
		// Set TracesSampleRate to 1.0 to capture 100%
		// of transactions for tracing.
		// We recommend adjusting this value in production,
		TracesSampleRate: 1.0,
	}); err != nil {
		fmt.Printf("Sentry initialization failed: %v\n", err)
	}
}
