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
	r.GET("/:mode", handleRedirect)       // e.g., https://apply.embloy.com/lever
	r.GET("/:mode/*path", handleRedirect) // e.g., https://apply.embloy.com/lever
	r.GET("/", handleAutoRequest)         // e.g., https://apply.embloy.com/?eType=auto&id=123&url=https://jobs.sandbox.lever.co/embloy&mode=lever
	r.Run(":8081")
}

func healthCheck(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"status": "ok"})
}

func handleRedirect(c *gin.Context) {
	mode := c.Param("mode")
	origin := c.Request.Header.Get("Origin")
	referrer := c.Request.Header.Get("Referer")
	path := c.Param("path")

	supportedModes := []string{"ashby", "lever", "job", "default"}
	if contains(supportedModes, mode) {
		// Incoming request looks like: apply.embloy.com/lever
		c.Redirect(http.StatusFound, cfg.MainInstance+"?origin="+url.QueryEscape(origin)+"&referrer="+url.QueryEscape(referrer)+"&mode="+url.QueryEscape(mode)+"&eType=external")
	} else {
		// Incoming request looks like: apply.embloy.com/jobs.sandbox.lever.co/de/bab6e549-d980-4911-a84c-668951c0e65e
		fullURL := mode + path
		log.Info("Full URL: ", fullURL)

		c.Request.URL.Path = "/"
		c.Request.URL.RawQuery = "url=" + url.QueryEscape(fullURL) + "&origin=" + url.QueryEscape(origin) + "&eType=auto&mode=default"

		log.Info("Redirected original request to auto request with parameters: ", c.Request.URL.RawQuery)
		handleAutoRequest(c)
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
	var errorDescription string
	if referrer == "" {
		errorDescription = "Invalid request. Please provide a valid referrer URL."
	} else if jobSlug == "" {
		errorDescription = "Invalid request. Please provide a valid job slug."
	} else if mode == "" {
		errorDescription = "Invalid request. Please provide a valid mode."
	}

	if errorDescription != "" {
		c.Redirect(http.StatusFound, cfg.MainInstance+"?eType=auto&id="+uID+"&url="+url.QueryEscape(referrer)+"&mode="+mode+"&error=invalid_request&error_description="+url.QueryEscape(errorDescription))
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
		errorDescription := "An error occurred while processing your request. This may be due to the job being unavailable or a misconfiguration in the application form by the job owner. If the problem persists, please contact the job owner directly or try again later."
		c.Redirect(http.StatusFound, cfg.MainInstance+"?eType=auto&id="+uID+"&url="+url.QueryEscape(referrer)+"&mode="+mode+"&error=internal_error&error_description="+url.QueryEscape(errorDescription))
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

	// Ensure the referrer URL includes a scheme
	if !strings.HasPrefix(referrer, "http://") && !strings.HasPrefix(referrer, "https://") {
		referrer = "https://" + referrer
	}

	refURL, err := url.Parse(referrer)
	if err != nil {
		log.Println("Error parsing referrer URL:", err)
		return "", "", "", ""
	}

	// If no mode is provided, try to infer it from the referrer URL
	if mode == "" || mode == "null" || mode == "job" || mode == "default" {
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
