package model

import (
	"log"

	"database/sql"

	"api/db"
)

type FoodAdditive struct {
	ID                 int      `json:"id"`
	Name               string   `json:"name"`
	Purpose            string   `json:"purpose"`
	Description        string   `json:"description"`
	PermissionEu       string   `json:"permission_eu"`
	PermissionUs       string   `json:"permission_us"`
	UsageStatus        string   `json:"usage_status"`
	RegulationStandard string   `json:"regulation_standard"`
	Category           int      `json:"category"`
	Adi                *float64 `json:"adi"`
}

func (h FoodAdditive) QueryByName(entity string) (*FoodAdditive, error) {
	db_client := db.GetDB()
	row := db_client.QueryRow("SELECT FOOD_ADDITIVE.* FROM FOOD_ADDITIVE INNER JOIN FOOD_ADDITIVE_ALIAS ON FOOD_ADDITIVE.id = FOOD_ADDITIVE_ALIAS.food_additive_id WHERE FOOD_ADDITIVE_ALIAS.alias_name = $1", entity)

	fa := &FoodAdditive{}
	err := row.Scan(&fa.ID, &fa.Name, &fa.Purpose, &fa.Description, &fa.PermissionEu, &fa.PermissionUs, &fa.UsageStatus, &fa.RegulationStandard, &fa.Category, &fa.Adi)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, err
		}
		log.Println(err)
		return nil, err
	}

	return fa, nil
}
