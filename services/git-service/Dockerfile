FROM golang:1.22-alpine AS builder

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /git-service .

FROM alpine:3.19
RUN apk --no-cache add ca-certificates git
COPY --from=builder /git-service /usr/local/bin/git-service
RUN mkdir -p /var/lib/parralax/repos

EXPOSE 8082
ENTRYPOINT ["git-service"]
