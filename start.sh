#!/bin/bash
# Startup script for the sample application

set -e

echo "Starting Sample Album API Application..."
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "Error: Docker daemon is not running."
    echo "   Please start Docker Desktop and try again."
    exit 1
fi

# Navigate to sample-app directory (where this script lives)
cd "$(dirname "$0")"

echo "Building and starting services..."
docker-compose up -d --build

echo ""
echo "Waiting for services to be ready..."
sleep 5

echo ""
echo "Services started! Checking status..."
docker-compose ps

echo ""
echo "Access points:"
echo "   - User API: http://localhost:8080"
echo "   - Admin API: http://localhost:8081"
echo "   - Grafana: http://localhost:3000 (admin/admin)"
echo "   - User API Health: http://localhost:8080/health"
echo "   - Admin API Health: http://localhost:8081/health"
echo ""
echo "View logs with: docker-compose logs -f api-user api-admin"
echo "Stop services with: docker-compose down"
echo ""

# Test the APIs
echo "Testing API health endpoints..."
if curl -s http://localhost:8080/health > /dev/null && curl -s http://localhost:8081/health > /dev/null; then
    echo "   ✓ Both APIs are responding!"
else
    echo "   APIs not ready yet. Wait a few seconds and try:"
    echo "      curl http://localhost:8080/health"
    echo "      curl http://localhost:8081/health"
fi
