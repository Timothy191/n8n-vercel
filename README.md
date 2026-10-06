# n8n on Vercel (Palolo)

![n8n](https://n8n.io/npm/n8n-nodes-base/logo/n8n-logo.png)

**Containerized [n8n](https://n8n.io/) workflow engine running on Vercel, backed by Supabase Postgres.**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=flat&logo=docker&logoColor=white)](https://www.docker.com/)
[![Vercel](https://img.shields.io/badge/vercel-%23000000.svg?style=flat&logo=vercel&logoColor=white)](https://vercel.com/)

---

## ⚡ Features

- **Serverless Workflow Automation** - Run n8n workflows on Vercel's serverless infrastructure
- **Dual Database Support** - Built-in support for SQLite (default) and Supabase Postgres
- **Auto-Refresh Cold Boot** - Professional loading page with automatic refresh during startup
- **Resilient Filesystem** - Prevents EMFILE crashes with graceful-fs integration
- **Production Ready** - Health checks, proper port mapping, and environment configuration
- **Developer Friendly** - Makefile, Docker Compose, and comprehensive documentation

---

## 🚀 Quick Start

### Deploy to Vercel (Recommended)

1. **Fork the repository** on GitHub
2. **Connect to Vercel** - Import the repository in your Vercel account
3. **Configure Environment Variables** in Vercel project settings:
   ```
   N8N_PORT=3000
   WEBHOOK_URL=https://your-domain.vercel.app
   USE_POSTGRES=true
   DB_TYPE=postgresdb
   DB_POSTGRESDB_HOST=your-supabase-host.supabase.co
   DB_POSTGRESDB_DATABASE=postgres
   DB_POSTGRESDB_USER=postgres
   DB_POSTGRESDB_PASSWORD=your-password
   ```
4. **Deploy** - Vercel will automatically deploy on push to `master`

### Local Development

#### Using Makefile (Recommended)
```bash
# Clone the repository
git clone https://github.com/Timothy191/n8n-vercel.git
cd n8n-vercel

# Copy environment template
cp .env.example .env.local

# Build and start
make build
make dev

# Access at: http://localhost:3000
```

#### Using Docker Directly
```bash
# Build the image
docker build -t n8n-vercel .

# Run with SQLite (default)
docker run -p 3000:3000 --env-file .env.local n8n-vercel

# Run with Postgres
docker compose --profile postgres up -d
```

---

## 📋 Configuration

### Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `N8N_PORT` | ✅ | 3000 | n8n application port |
| `PORT` | ❌ | - | Vercel-assigned port (auto-mapped) |
| `WEBHOOK_URL` | ✅ | - | Public URL for webhooks and callbacks |
| `USE_POSTGRES` | ❌ | false | Enable Postgres database |
| `DB_POSTGRESDB_HOST` | ✅* | - | Postgres host (*required when USE_POSTGRES=true) |
| `DB_POSTGRESDB_DATABASE` | ✅* | - | Database name |
| `DB_POSTGRESDB_USER` | ✅* | - | Database username |
| `DB_POSTGRESDB_PASSWORD` | ✅* | - | Database password |
| `N8N_DIAGNOSTICS_ENABLED` | ❌ | false | Enable n8n telemetry |
| `N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS` | ❌ | false | File permission enforcement |

> **⚠️ Important**: In production, always set `WEBHOOK_URL` to your production domain.

### Database Options

#### SQLite (Default)
```bash
USE_POSTGRES=false
# No additional configuration needed
```

#### Supabase Postgres
1. Create a new Supabase project
2. Get your connection details from Supabase dashboard
3. Configure environment variables:
   ```bash
   USE_POSTGRES=true
   DB_TYPE=postgresdb
   DB_POSTGRESDB_HOST=your-project-ref.supabase.co
   DB_POSTGRESDB_DATABASE=postgres
   DB_POSTGRESDB_USER=postgres
   DB_POSTGRESDB_PASSWORD=your-supabase-password
   DB_POSTGRESDB_PORT=5432
   ```

---

## 🛠️ Development

### Project Structure
```
n8n-vercel/
├── Dockerfile              # Container configuration
├── entrypoint.sh           # Entrypoint script with error handling
├── patch-fs.js             # Filesystem patch for EMFILE prevention
├── vercel.json             # Vercel platform configuration
├── docker-compose.yml      # Local development with optional Postgres
├── Makefile                # Common commands and automation
├── .env.example            # Environment variables template
├── .gitignore              # Git ignore patterns
├── .editorconfig           # Editor configuration
├── LICENSE                 # MIT License
├── README.md               # This file
├── CONTRIBUTING.md         # Development guide
└── scripts/
    └── validate.sh         # Project validation
```

### Available Commands

| Command | Description |
|---------|-------------|
| `make build` | Build Docker image |
| `make dev` | Start development container |
| `make run` | Start production container |
| `make down` | Stop and remove containers |
| `make validate` | Validate project configuration |
| `make clean` | Remove Docker images and containers |
| `make logs` | Show container logs |
| `make shell` | Shell into running container |

### Docker Compose Profiles

```bash
# Start with SQLite (default)
docker compose up -d

# Start with Postgres
docker compose --profile postgres up -d

# Start with PostGIS (geospatial support)
docker compose --profile postgis up -d

# Stop all services
docker compose down
```

---

## 🌐 Deployment Options

### Vercel (Recommended)
- **Automatic deployments** on Git push
- **Serverless containers** with automatic scaling
- **Global CDN** for fast access worldwide
- **Built-in CI/CD** with GitHub integration

### Self-Hosted
- **Docker**: Run on any Docker-compatible platform
- **Kubernetes**: Deploy to any K8s cluster
- **Other Platforms**: Compatible with any container runtime

---

## 🔒 Security

### Built-in Security Features
- ✅ **Non-root user** in Docker container
- ✅ **Telemetry disabled** by default
- ✅ **Environment variable validation**
- ✅ **Input validation** for critical configurations
- ✅ **Secure defaults** for production deployments

### Security Recommendations
1. **Always use HTTPS** in production
2. **Enable Basic Auth** for n8n dashboard:
   ```
   N8N_BASIC_AUTH_ACTIVE=true
   N8N_BASIC_AUTH_USER=admin
   N8N_BASIC_AUTH_PASSWORD=secure-password
   ```
3. **Set encryption key** for sensitive workflow data:
   ```
   N8N_ENCRYPTION_KEY=your-32-byte-base64-encoded-key
   ```
4. **Use secrets management** for database credentials

---

## 📊 Performance

### Optimizations Included
- **graceful-fs** for high-concurrency file operations
- **Increased file descriptor limits** (65536 preferred, 4096 fallback)
- **Health checks** for container orchestration
- **Auto-refresh** during cold starts to improve user experience

### Performance Tips
- Use **Postgres** for production workloads (better performance than SQLite)
- Enable **connection pooling** in your database configuration
- Consider **container pre-warming** to reduce cold start times
- Monitor **resource usage** and adjust container limits as needed

---

## 🐛 Troubleshooting

### Common Issues

#### Container won't start
```bash
# Check logs
docker logs n8n

# Validate configuration
make validate
```

#### Database connection fails
```bash
# Verify Postgres is accessible
docker compose ps

# Test connection manually
psql -h localhost -U n8n_user -d n8n_dev
```

#### EMFILE errors (too many open files)
```bash
# Ensure graceful-fs is loaded
# Check Dockerfile for proper configuration

# Increase file descriptor limits
docker run --ulimit nofile=65536:65536 n8n-vercel
```

#### Cold start takes too long
```bash
# This is normal for first startup
# Subsequent starts are faster
# Consider container pre-warming for production
```

### Debug Mode
```bash
# Enable verbose logging
docker run -e N8N_LOG_LEVEL=debug -p 3000:3000 n8n-vercel
```

---

## 📚 Resources

- **[n8n Documentation](https://docs.n8n.io/)** - Official n8n docs
- **[Vercel Documentation](https://vercel.com/docs)** - Vercel platform docs
- **[Docker Documentation](https://docs.docker.com/)** - Docker documentation
- **[Supabase Documentation](https://supabase.com/docs)** - Supabase docs

---

## 🤝 Contributing

We welcome contributions! Please see **[CONTRIBUTING.md](CONTRIBUTING.md)** for:
- Development setup
- Code style guidelines
- Testing procedures
- Pull request process

---

## 📄 License

This project is **MIT licensed** - see **[LICENSE](LICENSE)** for details.

---

## 🙏 Acknowledgments

- **[n8n](https://n8n.io/)** - The powerful workflow automation tool
- **[Vercel](https://vercel.com/)** - Serverless platform for frontend developers
- **[Supabase](https://supabase.com/)** - Open source Firebase alternative
- **All contributors** who help improve this project

---

**© 2026 Timothy191**

*Built with ❤️ for the n8n community*
