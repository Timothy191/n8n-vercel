# n8n on Vercel

Containerized [n8n](https://n8n.io/) workflow engine running on Vercel, backed by Supabase Postgres.

## Deployment

This project is connected to GitHub. Pushes to `master` trigger an automatic production deployment on Vercel.

```bash
cd /home/tim/Fork/n8n-vercel
git push origin master
```

## Local development

```bash
docker build -t n8n-vercel .
docker run -p 3000:3000 --env-file .env.local n8n-vercel
```
