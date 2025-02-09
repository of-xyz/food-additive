package db

import (
	"database/sql"
	"log"

	"cloud.google.com/go/cloudsqlconn"
	"cloud.google.com/go/cloudsqlconn/postgres/pgxv5"
)

var db *sql.DB

func CreateNewClient() {
	// TODO: cleanup
	_, err := pgxv5.RegisterDriver("cloudsql-postgres", cloudsqlconn.WithIAMAuthN())
	if err != nil {
		log.Fatalf("Failed to register driver: %v", err)
	}

	db, err = sql.Open(
		"cloudsql-postgres",
		"host=chum-312212:asia-northeast1:food-additive user=postgres password=0MIzLNLZX&qZ9:lZ dbname=postgres sslmode=disable",
	)
	if err != nil {
		log.Fatalf("Failed to open database: %v", err)
	}
}

func GetDB() *sql.DB {
	return db
}
