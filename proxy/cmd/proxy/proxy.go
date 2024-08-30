package main

import (
	"net/http"
	"net/url"
	"strings"

	"github.com/embloy/embloy-go/embloy"
	"github.com/gin-gonic/gin"

	"github.com/Embloy/proxy/cfg"
	log "github.com/sirupsen/logrus"
)

func main() {
	cfg.SetConfig()

	gin.SetMode(cfg.GinMode)

	r := gin.Default()
	r.GET("/health", healthCheck)
	r.GET("/:mode", handleRedirect) // e.g., https://apply.embloy.com/lever
	r.GET("/", handleAutoRequest)   // e.g., https://apply.embloy.com/?eType=auto&id=123&url=https://jobs.sandbox.lever.co/embloy&mode=lever
	r.Run(":8081")
}

func healthCheck(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"status": "ok"})
}

func handleRedirect(c *gin.Context) {
	mode := c.Param("mode")
	origin := c.Request.Header.Get("Origin")
	referrer := c.Request.Header.Get("Referer")

	supportedModes := []string{"ashby", "lever"}
	if contains(supportedModes, mode) {
		c.Redirect(http.StatusFound, cfg.MainInstance+"?origin="+origin+"&referrer="+referrer+"&mode="+mode+"&eType=external")
	} else {
		c.Redirect(http.StatusFound, cfg.MainInstance+"?origin="+origin+"&referrer="+referrer+"&mode="+mode+"&eType=external&error=invalid_request&error_description=Invalid mode. Supported modes are 'ashby' and 'lever'.")
	}
}

func contains(slice []string, item string) bool {
	for _, s := range slice {
		if s == item {
			return true
		}
	}
	return false
}

func handleAutoRequest(c *gin.Context) {
	uID, referrer, jobSlug, mode := extractParams(c)
	if referrer == "" || jobSlug == "" {
		c.Redirect(http.StatusFound, cfg.MainInstance+"?eType=auto&id="+uID+"&url="+referrer+"&mode="+mode+"&error=invalid_request&error_description=Invalid request. Missing parameters or invalid URL.")
		return
	}

	proxy := map[string]string{
		"origin":      referrer,
		"admin_token": cfg.AdminToken,
	}

	if uID != "" {
		proxy["user_id"] = uID
	}

	sessionData := embloy.SessionData{
		Mode:       mode,
		SuccessURL: "your-success-url",
		CancelURL:  "your-cancel-url",
		JobSlug:    jobSlug,
		Proxy:      proxy,
	}
	client := embloy.NewEmbloyClient("", sessionData)

	log.WithFields(log.Fields{
		"origin":  referrer,
		"jobSlug": jobSlug,
		"mode":    mode,
		"uID":     uID,
		"proxy":   proxy,
	}).Info("Requesting Embloy URL")

	response, err := client.MakeRequest()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.Redirect(http.StatusFound, response)
}

// ExtractParams extracts the necessary parameters from the request query
func extractParams(c *gin.Context) (string, string, string, string) {
	eType := c.Query("eType") // auto (=normal proxy service redirect), manual (=user opened and submitted proxy form manually), external (=user opened proxy-form from external source)
	uID := c.Query("id")
	referrer := c.Query("url")
	mode := c.Query("mode")

	// If no referrer URL is provided, try to infer it from the request headers
	if referrer == "" {
		referrer = c.Request.Referer()
		if referrer == "" {
			log.Println("No Referrer URL provided")
			return "", "", "", ""
		}
	}
	log.Println("Referrer URL:", referrer)

	refURL, err := url.Parse(referrer)
	if err != nil {
		log.Println("Error parsing referrer URL:", err)
		return "", "", "", ""
	}

	// If no mode is provided, try to infer it from the referrer URL
	if mode == "" || mode == "null" {
		switch refURL.Host {
		case "jobs.sandbox.lever.co", "hire.sandbox.lever.co":
			mode = "lever"
		case "app.ashbyhq.com":
			mode = "ashby"
		default:
			mode = "job"
		}
	}

	var jobSlug string

	switch eType {
	case "manual":
		// Request is coming from Embloy URL form -> Continue
	case "external":
		// Request is coming from external form -> Continue
	case "auto":
		// Request is coming from the proxy service -> Continue
	default:
		// Request is coming from a different source -> Requires uID
		if uID == "" {
			return "", "", "", ""
		}
	}

	// Extract job slug based on the mode
	switch mode {
	case "lever":
		pathSegments := strings.Split(refURL.Path, "/")
		if len(pathSegments) < 3 {
			return "", "", "", ""
		}
		jobSlug = pathSegments[len(pathSegments)-1]
	case "ashby":
		pathSegments := strings.Split(refURL.Path, "/")
		if len(pathSegments) < 5 {
			return "", "", "", ""
		}
		jobSlug = pathSegments[4]
	default:
		pathSegments := strings.Split(refURL.Path, "/")
		if len(pathSegments) < 2 {
			return "", "", "", ""
		}
		jobSlug = pathSegments[len(pathSegments)-1]
	}

	return uID, referrer, jobSlug, mode
}
