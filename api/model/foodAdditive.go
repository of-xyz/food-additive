package model

import (
	"log"

    "database/sql"

	"api/db"
)


type FoodAdditive struct {
	ID          int    `json:"id"`
	Name        string `json:"name"`
	Purpose     string `json:"purpose"`
	Description string `json:"description"`
}


func (h FoodAdditive) QueryByName(entity string) (*FoodAdditive, error) {
	db_client := db.GetDB()
	row := db_client.QueryRow("SELECT FOOD_ADDITIVE.* FROM FOOD_ADDITIVE INNER JOIN FOOD_ADDITIVE_ALIAS ON FOOD_ADDITIVE.id = FOOD_ADDITIVE_ALIAS.food_additive_id WHERE FOOD_ADDITIVE_ALIAS.alias_name = $1", entity)

	fa := &FoodAdditive{}
	err := row.Scan(&fa.ID, &fa.Name, &fa.Purpose, &fa.Description)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, err
		}
		log.Println(err)
		return nil, err
	}

	return fa, nil
}
