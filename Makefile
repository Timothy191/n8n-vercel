# n8n-vercel Makefile
# ====================
# Common commands for development, testing, and deployment

.PHONY: help build run dev down restart logs shell test validate clean

# Default values
DOCKER_IMAGE ?= n8n-vercel
DOCKER_REGISTRY ?=
PORT ?= 3000
ENV_FILE ?= .env.local
COMPOSE_FILE ?= docker-compose.yml

help: ## Show this help message
	@echo "n8n-vercel Makefile - Common Commands"
	@echo "====================================="
	@echo ""
	@echo "Development:"
	@echo "  make build          - Build Docker image"
	@echo "  make dev            - Start development container with local mounting"
	@echo "  make run            - Start production container"
	@echo "  make down           - Stop and remove containers"
	@echo "  make restart        - Restart containers"
	@echo "  make logs           - Show container logs"
	@echo "  make shell          - Shell into running container"
	@echo ""
	@echo "Local Development with Docker Compose:"
	@echo "  make up             - Start services with docker-compose"
	@echo "  make up-postgres    - Start with Postgres database"
	@echo "  make down-all       - Stop all services"
	@echo "  make ps             - List running services"
	@echo ""
	@echo "Testing & Validation:"
	@echo "  make validate       - Validate configuration and files"
	@echo "  make test           - Run tests (if available)"
	@echo "  make lint           - Lint shell scripts"
	@echo ""
	@echo "Deployment:"
	@echo "  make push           - Build and push to registry"
	@echo "  make deploy         - Deploy to Vercel"
	@echo ""
	@echo "Cleanup:"
	@echo "  make clean          - Remove Docker images and containers"
	@echo "  make clean-all      - Full cleanup (images, containers, volumes)"
	@echo ""
	@echo "Utility:"
	@echo "  make help           - Show this help message"
	@echo "  make env-example    - Create .env.local from .env.example"

# Build Docker image
build: ## Build Docker image
	@echo "Building Docker image: $(DOCKER_IMAGE)"
	docker build -t $(DOCKER_IMAGE) .

# Run development container with local volume mounting
dev: ## Start development container
	@echo "Starting development container..."
	@if [ ! -f $(ENV_FILE) ]; then \
		cp .env.example $(ENV_FILE); \
		echo "Created $(ENV_FILE) from .env.example"; \
	fi
	docker run -it --rm \
	  -p $(PORT):$(PORT) \
	  -v $(PWD)/patch-fs.js:/entrypoint-fs-patch.js:ro \
	  -v $(PWD)/entrypoint.sh:/entrypoint.sh:ro \
	  --env-file $(ENV_FILE) \
	  --name n8n-dev \
	  $(DOCKER_IMAGE)

# Run production container
run: ## Start production container
	@echo "Starting production container..."
	@if [ ! -f $(ENV_FILE) ]; then \
		cp .env.example $(ENV_FILE); \
		echo "Created $(ENV_FILE) from .env.example"; \
	fi
	docker run -d \
	  -p $(PORT):$(PORT) \
	  --env-file $(ENV_FILE) \
	  --restart unless-stopped \
	  --name n8n \
	  $(DOCKER_IMAGE)

# Stop and remove containers
down: ## Stop and remove containers
	@echo "Stopping containers..."
	docker stop n8n n8n-dev 2>/dev/null || true
	docker rm n8n n8n-dev 2>/dev/null || true
	@echo "Containers stopped and removed"

# Restart containers
restart: down run ## Restart containers

# Show container logs
logs: ## Show container logs
	@echo "Showing logs for n8n container..."
	docker logs n8n 2>/dev/null || docker logs n8n-dev 2>/dev/null || echo "No running containers found"

# Follow container logs
logs-follow: ## Follow container logs in real-time
	docker logs -f n8n 2>/dev/null || docker logs -f n8n-dev 2>/dev/null || echo "No running containers found"

# Shell into running container
shell: ## Shell into running container
	@echo "Shell into n8n container..."
	docker exec -it n8n sh 2>/dev/null || docker exec -it n8n-dev sh 2>/dev/null || echo "No running containers found"

# Docker Compose commands
up: ## Start services with docker-compose
	@echo "Starting services with docker-compose..."
	docker compose -f $(COMPOSE_FILE) up -d

up-postgres: ## Start with Postgres database
	@echo "Starting services with Postgres..."
	docker compose -f $(COMPOSE_FILE) --profile postgres up -d

down-all: ## Stop all services
	@echo "Stopping all services..."
	docker compose -f $(COMPOSE_FILE) down

ps: ## List running services
	docker compose -f $(COMPOSE_FILE) ps

# Validation and Testing
validate: ## Validate configuration and files
	@echo "Validating project configuration..."
	@echo "Checking required files..."
	@for file in Dockerfile entrypoint.sh patch-fs.js vercel.json; do \
		if [ ! -f "$$file" ]; then \
			echo "✗ Missing $$file"; \
			exit 1; \
		fi; \
		echo "✓ $$file exists"; \
	done
	@echo "Checking shell scripts are executable..."
	@for script in entrypoint.sh; do \
		if [ ! -x "$$script" ]; then \
			echo "✗ $$script is not executable"; \
			exit 1; \
		fi; \
		echo "✓ $$script is executable"; \
	done
	@echo "Checking Dockerfile syntax..."
	@if ! docker build -t $(DOCKER_IMAGE)-validate . 2>/dev/null; then \
		 echo "✗ Dockerfile has syntax errors"; \
		 exit 1; \
	fi
	echo "✓ Dockerfile is valid"
	@echo "✅ All validations passed!"

lint: ## Lint shell scripts
	@echo "Linting shell scripts..."
	@if command -v shellcheck >/dev/null 2>&1; then \
		shellcheck entrypoint.sh; \
	else \
		echo "shellcheck not installed. Install with: brew install shellcheck (mac) or apt-get install shellcheck (ubuntu)"; \
	fi

test: validate lint ## Run all tests
	@echo "Running all tests..."

# Deployment
push: ## Build and push to registry
	@echo "Building and pushing Docker image..."
	@if [ -z "$(DOCKER_REGISTRY)" ]; then \
		echo "DOCKER_REGISTRY not set. Using local only."; \
		docker build -t $(DOCKER_IMAGE) .; \
	else \
		image_tag="$(DOCKER_REGISTRY)/$(DOCKER_IMAGE):$(shell git rev-parse --short HEAD)"; \
		docker build -t $$image_tag .; \
		docker push $$image_tag; \
		echo "Pushed: $$image_tag"; \
	fi

deploy: push ## Deploy to Vercel
	@echo "Deploying to Vercel..."
	@if command -v vercel >/dev/null 2>&1; then \
		vercel --prod; \
	else \
		echo "Vercel CLI not installed. Install with: npm install -g vercel"; \
	fi

# Cleanup
clean: ## Remove Docker images and containers
	@echo "Cleaning up..."
	docker stop n8n n8n-dev 2>/dev/null || true
	docker rm n8n n8n-dev 2>/dev/null || true
	docker rmi $(DOCKER_IMAGE) 2>/dev/null || true
	@echo "Cleanup complete"

clean-all: clean ## Full cleanup
	@echo "Full cleanup..."
	docker system prune -f 2>/dev/null || true
	@echo "Full cleanup complete"

# Utility
env-example: ## Create .env.local from .env.example
	@echo "Creating .env.local from .env.example..."
	@if [ -f .env.example ]; then \
		cp .env.example .env.local; \
		echo "✓ Created .env.local"; \
		echo "⚠️  Edit .env.local with your specific configuration"; \
	else \
		echo "✗ .env.example not found"; \
	fi