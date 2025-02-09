package db

import (
	"database/sql"
	"fmt"
	"log"

	"cloud.google.com/go/cloudsqlconn"
	"cloud.google.com/go/cloudsqlconn/postgres/pgxv5"

	"api/config"
)

var db *sql.DB

func CreateNewClient() {
	// TODO: cleanup
	config := config.GetServerConfig()
	_, err := pgxv5.RegisterDriver("cloudsql-postgres", cloudsqlconn.WithIAMAuthN())
	if err != nil {
		log.Fatalf("Failed to register driver: %v", err)
	}

	dsn := fmt.Sprintf("host=%s user=%s password=%s dbname=%s sslmode=disable", config.INSTANCE_CONNECTION_NAME, config.DB_USER, config.DB_PASSWORD, config.DB_NAME)
	db, err = sql.Open("cloudsql-postgres", dsn)
	if err != nil {
		log.Fatalf("Failed to open database: %v", err)
	}
}

func GetDB() *sql.DB {
	return db
}
