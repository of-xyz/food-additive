package server

import (
	"github.com/gin-gonic/gin"

	"api/controller"
)

func NewRouter() *gin.Engine {
	router := gin.Default()
	router.MaxMultipartMemory = 8 << 20 // 8 MiB

	foodAdditive := new(controller.FoodAdditiveController)
	router.POST("/", foodAdditive.Detect)
	// TODO: auth

	return router
}
