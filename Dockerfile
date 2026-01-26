# Build stage
FROM golang:1.23-alpine AS builder

WORKDIR /build

# Copy go mod files
COPY go.mod go.sum* ./
# Use GOTOOLCHAIN=auto to automatically download newer Go version if needed
ENV GOTOOLCHAIN=auto
RUN go mod download

# Copy source code
COPY cmd ./cmd

# Build api-user
WORKDIR /build/cmd/api-user
RUN CGO_ENABLED=0 GOOS=linux go build -o /build/api-user .

# Build api-admin
WORKDIR /build/cmd/api-admin
RUN CGO_ENABLED=0 GOOS=linux go build -o /build/api-admin .

# Runtime stage
FROM alpine:latest

RUN apk --no-cache add ca-certificates

WORKDIR /app

# Copy binaries from builder
COPY --from=builder /build/api-user /app/api-user
COPY --from=builder /build/api-admin /app/api-admin

EXPOSE 8080

# Default to api-user, can be overridden in docker-compose
CMD ["/app/api-user"]
