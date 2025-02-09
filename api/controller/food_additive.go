package controller

import (
	"errors"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"regexp"
	"strings"

	"golang.org/x/text/unicode/norm"

	language "cloud.google.com/go/language/apiv2"
	"cloud.google.com/go/language/apiv2/languagepb"
	vision "cloud.google.com/go/vision/apiv1"
	"github.com/gin-gonic/gin"

	"api/model"
)

type FoodAdditiveController struct{}

var foodAdditiveModel = new(model.FoodAdditive)

func (u FoodAdditiveController) Detect(c *gin.Context) {
	file, err := c.FormFile("image")
	if err != nil {
		fmt.Println(err)
		c.JSON(http.StatusBadRequest, gin.H{"message": "Failed to load Image File", "error": err.Error()})
		c.Abort()
		return
	}

	// 一時ファイルを作成
	tempFile, err := ioutil.TempFile("", "upload-*.png")
	if err != nil {
		fmt.Println(err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create temp file"})
		return
	}
	defer os.Remove(tempFile.Name())

	// アップロードされたファイルを一時ファイルに保存
	if err := c.SaveUploadedFile(file, tempFile.Name()); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save file"})
		return
	}

	// Vision APIを使用してテキスト抽出
	detectedText, err := detectTextFromFile(c, tempFile.Name())
	if err != nil {
		fmt.Println(err)
		return
	}
	sanitizedText, err := sanitizeDetectedText(c, detectedText)
	if err != nil {
		fmt.Println(err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to detect text"})
		return
	}

	entities, err := extractEntities(c, sanitizedText)
	// TODO: 省略形を復元する
	if err != nil {
		fmt.Println(err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to detect text"})
		return
	}

	var result []model.FoodAdditive
	var hit []string
	var not_hit []string

	for _, entity := range entities {
		normalized := normalizeFoodAdditiveName(entity)
		food_additive, err := foodAdditiveModel.QueryByName(normalized)
		if err != nil {
			not_hit = append(not_hit, normalized)
			continue
		}
		hit = append(hit, normalized)
		result = append(result, *food_additive)
	}

	log.Println("hit: %c", strings.Join(hit, ","))
	log.Println("not hit: %c", strings.Join(not_hit, ","))

	c.JSON(http.StatusOK, result)
	return
}

func sanitizeDetectedText(ctx *gin.Context, detectedText string) (string, error) {
	breakline_removed := strings.ReplaceAll(detectedText, "\n", "") // 改行除去
	pattern := `(^.*(原材料名|添加物)|(内容量|賞味期限|保存方法|製造者).*$)`
	re := regexp.MustCompile(pattern)

	cleaned := re.ReplaceAllString(breakline_removed, "")

	return cleaned, nil
}
func detectTextFromFile(ctx *gin.Context, fileName string) (string, error) {
	// Vision APIクライアントを作成
	client, err := vision.NewImageAnnotatorClient(ctx)
	if err != nil {
		log.Fatalf("Failed to create client: %v", err)
		return "", err
	}
	defer client.Close()

	// 画像ファイルを開く
	file, err := os.Open(fileName)
	if err != nil {
		log.Fatalf("Failed to read file: %v", err)
		return "", err
	}
	defer file.Close()

	image, err := vision.NewImageFromReader(file)
	if err != nil {
		log.Fatalf("Failed to create image: %v", err)
		return "", err
	}

	// テキスト検出を実行
	response, err := client.DetectTexts(ctx, image, nil, 10)
	if err != nil {
		log.Fatalf("Failed to detect text: %v", err)
		return "", err
	}

	if len(response) == 0 {
		return "", errors.New("No text found")
	}

	return response[0].Description, nil
}

func extractEntities(ctx *gin.Context, text string) ([]string, error) {
	entities := make([]string, 0, 100)

	// Initialize client.
	client, err := language.NewClient(ctx)
	if err != nil {
		return entities, err
	}
	defer client.Close()

	resp, err := client.AnalyzeEntities(ctx, &languagepb.AnalyzeEntitiesRequest{
		Document: &languagepb.Document{
			Source: &languagepb.Document_Content{
				Content: text,
			},
			Type: languagepb.Document_PLAIN_TEXT,
		},
		EncodingType: languagepb.EncodingType_UTF8,
	})

	if err != nil {
		return entities, fmt.Errorf("AnalyzeEntities: %w", err)
	}

	for _, entity := range resp.Entities {
		if entity.Type == languagepb.Entity_OTHER || entity.Type == languagepb.Entity_UNKNOWN || entity.Type == languagepb.Entity_CONSUMER_GOOD {
			entities = append(entities, entity.Name)
		}
	}
	return entities, nil
}

// 正規化
func normalizeFoodAdditiveName(entity string) string {
	// スペースとか
	re := regexp.MustCompile(`[\s　]+`)
	// ハイフンとか長音とか
	reH := regexp.MustCompile(`[\x{002D}\x{02D7}\x{1B78}\x{2010}\x{2011}\x{2012}\x{2013}\x{2014}\x{2015}\x{2043}\x{207B}\x{2212}\x{2500}\x{2501}\x{2796}\x{30FC}\x{3161}\x{FE58}\x{FE63}\x{FF0D}\x{FF70}\x{10110}\x{1680}]+`)
	// シングルクォートとかアポストロフィ
	reQ := regexp.MustCompile(`[\x{0027}\x{2018}\x{2019}\x{FF07}\x{02BC}\x{055A}]+`)
	// カンマとか
	reC := regexp.MustCompile(`[\x{002C}\x{201A}\x{2E41}\x{3001}\x{FF0C}]+`)
	normalized := re.ReplaceAllString(entity, "")
	normalized = reH.ReplaceAllString(normalized, "-")
	normalized = reQ.ReplaceAllString(normalized, "'")
	normalized = reC.ReplaceAllString(normalized, ",")
	normalized = norm.NFKC.String(normalized) // Unicode正規化
	normalized = strings.ToLower(normalized)  // 小文字化
	// 捨て仮名の並字化
	normalized = strings.ReplaceAll(normalized, "ァ", "ア")
	normalized = strings.ReplaceAll(normalized, "ィ", "イ")
	normalized = strings.ReplaceAll(normalized, "ェ", "エ")
	normalized = strings.ReplaceAll(normalized, "ォ", "オ")
	normalized = strings.ReplaceAll(normalized, "ャ", "ヤ")
	normalized = strings.ReplaceAll(normalized, "ュ", "ユ")
	normalized = strings.ReplaceAll(normalized, "ョ", "ヨ")
	return normalized
}
