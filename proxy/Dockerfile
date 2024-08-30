FROM golang:1.22-alpine3.18 as build-env

RUN mkdir /gostuff
WORKDIR /gostuff
COPY go.mod go.sum ./

# Get dependencies - will also be cached if we won't change mod/sum
RUN go mod download

WORKDIR /go/src/app
COPY . .

# bundle version into binary if specified in build-args, dev otherwise.
ARG version=dev
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags "-w -extldflags '-static' -X main.VersionTag=${version}" -o /go/bin/proxy cmd/proxy/proxy.go

FROM alpine:3.18
RUN apk add --no-cache tzdata openssl
WORKDIR /app
COPY --from=build-env /go/bin/proxy .
COPY .env ./
CMD ["sh", "-c", "sleep 3 && ./proxy"]
