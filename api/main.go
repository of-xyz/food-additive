package main

import (
    "fmt"

	"api/config"
	"api/db"
	"api/server"
)


func main() {
    fmt.Println("start")

    config.LoadConfig()
    db.CreateNewClient()

    server.Run()
}
