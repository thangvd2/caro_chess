// Package config provides centralized configuration for the Caro Chess server.
package config

import (
	"flag"
	"os"
	"strconv"
)

// Config holds all server configuration values.
type Config struct {
	// Server configuration
	ServerAddr string
	ServerHost string
	ServerPort int

	// Database configuration
	UsersDBPath string

	// Game configuration
	BoardRows    int
	BoardColumns int

	// Matchmaking configuration
	EloRange           int
	MatchmakingTimeout int // seconds

	// WebSocket configuration
	PingInterval int // seconds
	PingTimeout  int // seconds
}

// Default configuration values
const (
	DefaultServerHost      = "0.0.0.0"
	DefaultServerPort      = 8080
	DefaultUsersDBPath     = "users.json"
	DefaultBoardRows       = 15
	DefaultBoardColumns    = 15
	DefaultEloRange        = 200
	DefaultMatchmakingTimeout = 30
	DefaultPingInterval    = 30
	DefaultPingTimeout     = 60
)

var cfg *Config

// Load initializes and returns the configuration.
// Should be called once at application startup.
func Load() *Config {
	if cfg != nil {
		return cfg
	}

	cfg = &Config{
		ServerAddr:          os.Getenv("CARO_CHESS_ADDR"),
		ServerHost:          os.Getenv("CARO_CHESS_HOST"),
		ServerPort:          intEnvVar("CARO_CHESS_PORT", DefaultServerPort),
		UsersDBPath:         stringEnvVar("CARO_CHESS_USERS_DB", DefaultUsersDBPath),
		BoardRows:           intEnvVar("CARO_CHESS_BOARD_ROWS", DefaultBoardRows),
		BoardColumns:        intEnvVar("CARO_CHESS_BOARD_COLUMNS", DefaultBoardColumns),
		EloRange:            intEnvVar("CARO_CHESS_ELO_RANGE", DefaultEloRange),
		MatchmakingTimeout:  intEnvVar("CARO_CHESS_MATCHMAKING_TIMEOUT", DefaultMatchmakingTimeout),
		PingInterval:        intEnvVar("CARO_CHESS_PING_INTERVAL", DefaultPingInterval),
		PingTimeout:         intEnvVar("CARO_CHESS_PING_TIMEOUT", DefaultPingTimeout),
	}

	// Construct ServerAddr from Host and Port if not set
	if cfg.ServerAddr == "" {
		if cfg.ServerHost == "" {
			cfg.ServerHost = DefaultServerHost
		}
		cfg.ServerAddr = cfg.ServerHost + ":" + strconv.Itoa(cfg.ServerPort)
	}

	// Allow command line flag overrides
	flag.StringVar(&cfg.ServerAddr, "addr", cfg.ServerAddr, "http service address")
	flag.StringVar(&cfg.UsersDBPath, "users-db", cfg.UsersDBPath, "user database path")
	flag.IntVar(&cfg.ServerPort, "port", cfg.ServerPort, "server port")
	flag.Parse()

	return cfg
}

// Get returns the loaded configuration.
// Panics if Load has not been called.
func Get() *Config {
	if cfg == nil {
		panic("config not loaded. Call config.Load() first")
	}
	return cfg
}

// Helper functions for environment variable parsing

func intEnvVar(key string, defaultValue int) int {
	if val := os.Getenv(key); val != "" {
		if intVal, err := strconv.Atoi(val); err == nil {
			return intVal
		}
	}
	return defaultValue
}

func stringEnvVar(key, defaultValue string) string {
	if val := os.Getenv(key); val != "" {
		return val
	}
	return defaultValue
}
