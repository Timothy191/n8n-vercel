# Contributing to n8n-vercel (Palolo)

We welcome contributions to the **Palolo** project! This guide will help you get started with development, testing, and contributing.

## 🚀 Getting Started

### Prerequisites

- [Docker](https://www.docker.com/) - Container runtime
- [Docker Compose](https://docs.docker.com/compose/) - For multi-container development
- [Git](https://git-scm.com/) - Version control
- [Node.js](https://nodejs.org/) (optional) - For local development and debugging
- [Make](https://www.gnu.org/software/make/) (optional) - For using Makefile commands

### Quick Start

1. **Clone the repository**
   ```bash
   git clone https://github.com/Timothy191/n8n-vercel.git
   cd n8n-vercel
   ```

2. **Set up environment**
   ```bash
   # Copy example environment file
   cp .env.example .env.local
   
   # Edit .env.local with your configuration
   # For local development, the defaults should work fine
   ```

3. **Build the project**
   ```bash
   # Using Makefile (recommended)
   make build
   
   # Or manually
   docker build -t n8n-vercel .
   ```

4. **Run locally**
   ```bash
   # Using Makefile (recommended)
   make dev
   
   # Or manually
   docker run -p 3000:3000 --env-file .env.local n8n-vercel
   ```

5. **Access n8n**
   Open your browser and navigate to: `http://localhost:3000`

### Using Docker Compose

For a complete development environment with optional Postgres database:

```bash
# Start with SQLite (default)
docker compose up -d

# Start with Postgres
docker compose --profile postgres up -d

# Stop all services
docker compose down

# View logs
docker compose logs -f

# Shell into n8n container
docker compose exec n8n sh
```

## 📋 Project Structure

```
n8n-vercel/
├── Dockerfile              # Main container configuration
├── entrypoint.sh           # Container entrypoint script
├── patch-fs.js             # Filesystem patch for EMFILE prevention
├── vercel.json             # Vercel platform configuration
├── docker-compose.yml      # Local development with Docker Compose
├── Makefile                # Common commands and automation
├── .env.example            # Environment variables template
├── .gitignore              # Git ignore patterns
├── .editorconfig           # Editor configuration
├── LICENSE                 # MIT License
├── README.md               # Project documentation
├── CONTRIBUTING.md         # This file
└── scripts/
    └── validate.sh         # Project validation script
```

## 🎯 Development Workflow

### Making Changes

1. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**
   - Follow existing code style and patterns
   - Add appropriate comments
   - Update documentation as needed

3. **Test your changes**
   ```bash
   # Validate project structure
   make validate
   
   # Run local tests
   make dev
   
   # Test with different configurations
   ```

4. **Commit your changes**
   ```bash
   git add .
   git commit -m "feat: add your feature description"
   
   # Follow conventional commits:
   # - feat: for new features
   # - fix: for bug fixes
   # - docs: for documentation changes
   # - style: for formatting changes
   # - refactor: for code refactoring
   # - chore: for maintenance tasks
   ```

5. **Push and create PR**
   ```bash
   git push origin feature/your-feature-name
   # Open Pull Request on GitHub
   ```

### Code Style

- **Shell Scripts**: Follow POSIX standards, use `#!/bin/sh` shebang
- **JavaScript**: Use modern ES6+ syntax, include proper error handling
- **Docker**: Use multi-stage builds where appropriate, minimize layers
- **Indentation**: 2 spaces for most files, tabs for Makefile
- **Line Length**: Maximum 120 characters
- **Comments**: Use descriptive comments for complex logic

## 🧪 Testing

### Manual Testing

1. **Build validation**
   ```bash
   make validate
   ```

2. **Local development**
   ```bash
   make dev
   ```

3. **Test with different databases**
   ```bash
   # SQLite (default)
   USE_POSTGRES=false make dev
   
   # Postgres
   USE_POSTGRES=true make dev-postgres
   ```

4. **Test on Vercel**
   - Push to a feature branch and test Vercel preview deployments
   - Test with different Vercel regions and configurations

### Automated Testing (Future)

We plan to add automated testing for:
- Dockerfile syntax validation
- Container startup and health checks
- Environment variable validation
- Basic functionality tests

## 🚀 Deployment

### Local Deployment

```bash
# Build and run
make build
make run

# Or using docker-compose
docker compose up -d
```

### Vercel Deployment

The project is configured for automatic deployment to Vercel:

1. **Connect to GitHub**: Link your Vercel account to this repository
2. **Configure Environment Variables**: Set required variables in Vercel project settings
3. **Push to main branch**: Changes to `master` branch trigger automatic deployment

### Manual Vercel Deployment

```bash
# Install Vercel CLI
npm install -g vercel

# Deploy
vercel --prod
```

## 📊 Environment Variables

### Required Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `N8N_PORT` | n8n application port | 3000 |
| `WEBHOOK_URL` | Public URL for webhooks | `https://n8n-vercel-alpha.vercel.app` |

### Database Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `USE_POSTGRES` | Enable Postgres database | No (defaults to SQLite) |
| `DB_TYPE` | Database type | Set to `postgresdb` when `USE_POSTGRES=true` |
| `DB_POSTGRESDB_HOST` | Postgres host | Yes (when `USE_POSTGRES=true`) |
| `DB_POSTGRESDB_PORT` | Postgres port | 5432 |
| `DB_POSTGRESDB_DATABASE` | Database name | Yes (when `USE_POSTGRES=true`) |
| `DB_POSTGRESDB_USER` | Database username | Yes (when `USE_POSTGRES=true`) |
| `DB_POSTGRESDB_PASSWORD` | Database password | Yes (when `USE_POSTGRES=true`) |

### Optional Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `N8N_DIAGNOSTICS_ENABLED` | Enable telemetry | `false` |
| `N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS` | File permission enforcement | `false` |
| `N8N_BASIC_AUTH_ACTIVE` | Enable basic authentication | `false` |
| `N8N_BASIC_AUTH_USER` | Basic auth username | - |
| `N8N_BASIC_AUTH_PASSWORD` | Basic auth password | - |

## 🔧 Configuration

### Development Configuration

For local development, use `.env.local`:

```bash
# Example .env.local for development
N8N_PORT=3000
WEBHOOK_URL=http://localhost:3000
USE_POSTGRES=false
```

### Production Configuration

For production, configure environment variables in Vercel project settings.

**Important**: Always set `WEBHOOK_URL` to your production domain in production environments.

## 🐛 Troubleshooting

### Common Issues

#### Docker Build Fails
```bash
# Check Dockerfile syntax
make validate

# Build with debug output
docker build --no-cache -t n8n-vercel .
```

#### Container Won't Start
```bash
# Check logs
docker logs n8n

# Check environment variables
docker inspect n8n

# Test health endpoint
curl http://localhost:3000/healthz
```

#### Database Connection Fails
```bash
# Verify Postgres is running (if using Postgres)
docker compose ps

# Check connection manually
psql -h localhost -U n8n_user -d n8n_dev
```

#### EMFILE Errors
```bash
# Ensure graceful-fs is properly loaded
# Check that patch-fs.js is correctly referenced in Dockerfile

# Increase file descriptor limits
docker run --ulimit nofile=65536:65536 n8n-vercel
```

## 📚 Additional Resources

- [n8n Documentation](https://docs.n8n.io/)
- [Vercel Documentation](https://vercel.com/docs)
- [Docker Documentation](https://docs.docker.com/)
- [Supabase Documentation](https://supabase.com/docs)

## 🤝 Code of Conduct

- Be respectful and inclusive
- Follow best practices and coding standards
- Provide clear, constructive feedback
- Document your code and changes
- Test your changes thoroughly

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Thank You!

Thank you for contributing to Palolo! Your contributions help make n8n on Vercel better for everyone.

If you have questions or need help, please open an issue or discussion on GitHub.