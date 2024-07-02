package main

import (
	"log"
	"net/http"
	"net/url"
	"os"
	"strings"

	"github.com/embloy/embloy-go/embloy"
	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
)

func main() {
	err := godotenv.Load()
	if err != nil {
		log.Fatal("Error loading .env file")
	}

	ginMode, exists := os.LookupEnv("GIN_MODE")
	if !exists {
		ginMode = gin.ReleaseMode
	}
	gin.SetMode(ginMode)

	r := gin.Default()

	r.GET("/", func(c *gin.Context) {
		adminToken, exists := os.LookupEnv("ADMIN_TOKEN")
		if !exists {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "ADMIN_TOKEN is not set"})
			return
		}

		uID := c.Query("id")
		if uID == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "No ID provided"})
			return
		}

		referrer := c.Query("url")
		if referrer == "" {
			// Fallback to the Referer header if 'url' query parameter is not provided
			referrer = c.Request.Referer()
			if referrer == "" {
				log.Println("No Referrer URL provided")
				c.JSON(http.StatusBadRequest, gin.H{"error": "No referrer URL provided"})
				return
			}
		}
		log.Println("Referrer URL:", referrer)

		refURL, err := url.Parse(referrer)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid referrer URL"})
			return
		}

		var mode string
		switch refURL.Host {
		case "jobs.sandbox.lever.co", "hire.sandbox.lever.co":
			mode = "lever"
		default:
			mode = "job"
		}

		proxy := map[string]string{
			"origin":      referrer,
			"admin_token": adminToken,
			"user_id":     uID,
		}

		// Extract the jobSlug from the path
		pathSegments := strings.Split(refURL.Path, "/")
		if len(pathSegments) < 2 {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid job posting URL"})
			return
		}
		jobSlug := pathSegments[len(pathSegments)-1]

		sessionData := embloy.SessionData{
			Mode:       mode,
			SuccessURL: "your-success-url",
			CancelURL:  "your-cancel-url",
			JobSlug:    jobSlug,
			Proxy:      proxy,
		}
		client := embloy.NewEmbloyClient("", sessionData)

		response, err := client.MakeRequest()
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		c.Redirect(http.StatusFound, response)
	})

	r.Run(":8081")
}
