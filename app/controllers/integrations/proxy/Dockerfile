# Simplified Dockerfile for a Go Gin API

# Build the Go Gin backend
FROM golang:1.21 as builder
WORKDIR /go/src/app
COPY go.mod .
COPY go.sum .
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .


# Final stage
FROM alpine:latest  
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=builder /go/src/app/main .
COPY .env ./
EXPOSE 8080
CMD ["./main"]