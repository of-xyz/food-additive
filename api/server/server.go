package server

import (
	"strconv"

	"api/config"
)

func Run() {
	config := config.GetServerConfig()
	r := NewRouter()
	r.Run(":" + strconv.Itoa(config.PORT))
}
