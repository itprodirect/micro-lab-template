FROM golang:1.22-alpine AS builder

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -o /lab-cli ./cmd/lab-cli

FROM alpine:3.20 AS runtime

RUN addgroup -S app && adduser -S app -G app
COPY --from=builder /lab-cli /usr/local/bin/lab-cli
USER app

ENTRYPOINT ["lab-cli"]
