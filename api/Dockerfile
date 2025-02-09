# builder
FROM golang:1.23.2-bullseye AS builder

WORKDIR /app

COPY go.* ./
RUN go mod download

COPY config config
COPY controller controller
COPY db db
# dev: COPY gcp-credential.json .
COPY main.go .
COPY model model
COPY server server

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -v -o main ./main.go


# runner
FROM alpine:latest
COPY --from=builder /app/main /main
# dev: COPY --from=builder /app/gcp-credential.json /app/gcp-credential.json

EXPOSE 8080

CMD ["/main"]
