package config

import (
    "log"
    "github.com/caarlos0/env/v11"
)


type ServerConfig struct {
    PORT int `env:"PORT"`
    DB_NAME string `env:"DB_NAME"`
    DB_USER string `env:"DB_USER"`
    DB_PASSWORD string `env:"DB_PASSWORD"`
    INSTANCE_CONNECTION_NAME string `env:"INSTANCE_CONNECTION_NAME"`
}


var serverConfig ServerConfig

func LoadConfig() {
	if err := env.Parse(&serverConfig); err != nil {
		log.Fatalln(err)
	}
}

func GetServerConfig() ServerConfig {
    return serverConfig
}
