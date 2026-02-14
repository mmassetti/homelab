# Replace Vercel with Self-Hosted Solution
**Save $20/month = $240/year!**

---

## What You're Currently Paying For

**Vercel Pro - $20/month:**
- Image optimization
- Multiple projects/seats
- 100GB bandwidth
- Serverless functions
- Automatic deployments
- Custom domains
- Edge network (fast CDN)

**Can you replace this? YES!** ✅

---

## Self-Hosted Alternative Stack

### Complete Replacement on Your Homelab:

```
┌─────────────────────────────────────────┐
│  Your Homelab (Mini PC)                 │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │ Nginx Proxy Manager or Traefik   │  │ ← Reverse proxy
│  │ (Auto SSL, subdomain routing)    │  │
│  └───────────────────────────────────┘  │
│              │                          │
│              ├─→ Frontend Apps (Static) │
│              ├─→ Backend APIs (Node.js) │
│              └─→ Databases (PostgreSQL) │
│                                         │
│  Image Optimization:                   │
│  ├─→ Sharp (Node.js)                   │
│  └─→ Or imgproxy                       │
│                                         │
│  Deployment:                           │
│  └─→ GitHub Actions → Docker deploy    │
└─────────────────────────────────────────┘
              ↓
      Cloudflare (CDN + DNS)
      ├─→ Caching
      ├─→ DDoS protection  
      └─→ Fast edge network
              ↓
         🌍 Users worldwide
```

---

## Component 1: Reverse Proxy

### Option A: Nginx Proxy Manager (RECOMMENDED - Easiest)

**What it does:**
- Manage multiple domains/subdomains
- Automatic SSL certificates (Let's Encrypt)
- Easy web UI (no config files!)
- Access lists (security)

**Docker Setup:**
```yaml
nginx-proxy-manager:
  image: 'jc21/nginx-proxy-manager:latest'
  container_name: nginx-proxy-manager
  ports:
    - '80:80'      # HTTP
    - '443:443'    # HTTPS
    - '81:81'      # Admin UI
  volumes:
    - /opt/docker/configs/npm/data:/data
    - /opt/docker/configs/npm/letsencrypt:/etc/letsencrypt
  restart: unless-stopped
  networks:
    - homelab
```

**After setup:**
1. Access: http://192.168.1.239:81
2. Add proxy host: app.matiasmassetti.com → container:port
3. Enable SSL (automatic!)
4. Done!

**Benefits:**
- ✅ Visual interface (no nginx config)
- ✅ Automatic SSL renewal
- ✅ Easy subdomain management
- ✅ Access control

---

### Option B: Traefik (More Advanced)

**What it does:**
- Same as NPM but auto-discovers Docker containers
- Labels on containers = automatic routing
- More powerful, steeper learning curve

**When to use:**
- You have many (10+) services
- You want full automation
- You're comfortable with Docker labels

---

## Component 2: Image Optimization

### Your Vercel Use Case: Image Optimization

**Vercel's Image Optimization:**
```javascript
import Image from 'next/image'

<Image 
  src="/photo.jpg" 
  width={800} 
  height={600}
  quality={75}
/>
// Vercel auto-optimizes, serves WebP, resizes
```

**Self-Hosted Replacement: Sharp**

**Option A: Next.js Self-Hosted Image Optimization**

If you're using Next.js:
```javascript
// next.config.js
module.exports = {
  images: {
    loader: 'default', // Use built-in loader
    domains: ['matiasmassetti.com'],
  },
}
```

**Then self-host Next.js:**
```dockerfile
# Dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build
EXPOSE 3000
CMD ["npm", "start"]
```

**Benefits:**
- ✅ Same Next.js Image component works
- ✅ Automatic optimization
- ✅ No code changes needed
- ❌ Requires CPU for optimization (your mini PC can handle it!)

---

**Option B: Standalone Image Optimization Service**

**Using imgproxy (Fast, lightweight):**

```yaml
imgproxy:
  image: darthsim/imgproxy:latest
  container_name: imgproxy
  ports:
    - "8081:8080"
  environment:
    - IMGPROXY_KEY=your_secret_key
    - IMGPROXY_SALT=your_secret_salt
    - IMGPROXY_USE_ETAG=true
  volumes:
    - /mnt/nas/Images:/images:ro
  restart: unless-stopped
  networks:
    - homelab
```

**Usage:**
```javascript
// In your frontend
const imageUrl = `https://img.matiasmassetti.com/
  width/800/
  quality/75/
  plain/s3://bucket/image.jpg`

<img src={imageUrl} />
```

**Benefits:**
- ✅ Very fast (written in Go)
- ✅ On-the-fly resizing
- ✅ Format conversion (WebP, AVIF)
- ✅ Caching
- ✅ Low resource usage

---

**Option C: Simple Node.js Sharp Service**

**Create your own image API:**

```javascript
// image-service/index.js
const express = require('express');
const sharp = require('sharp');
const app = express();

app.get('/optimize', async (req, res) => {
  const { url, width, quality } = req.query;
  
  // Download original image
  const response = await fetch(url);
  const buffer = await response.arrayBuffer();
  
  // Optimize with Sharp
  const optimized = await sharp(Buffer.from(buffer))
    .resize(parseInt(width) || 800)
    .webp({ quality: parseInt(quality) || 75 })
    .toBuffer();
  
  res.type('image/webp').send(optimized);
});

app.listen(3001);
```

**Docker:**
```yaml
image-optimizer:
  build: ./image-service
  container_name: image-optimizer
  ports:
    - "3001:3001"
  restart: unless-stopped
  networks:
    - homelab
```

---

## Component 3: Database (Replace Supabase)

**Vercel → Supabase (PostgreSQL):**
- Easy integration
- Free tier limits
- Managed service

**Self-Hosted PostgreSQL:**

```yaml
postgres:
  image: postgres:16-alpine
  container_name: postgres
  ports:
    - "5432:5432"
  environment:
    - POSTGRES_USER=matias
    - POSTGRES_PASSWORD=secure_password
    - POSTGRES_DB=myapp
  volumes:
    - /opt/docker/configs/postgres:/var/lib/postgresql/data
  restart: unless-stopped
  networks:
    - homelab
```

**Access from your apps:**
```javascript
// Database connection string
const connectionString = 'postgresql://matias:password@postgres:5432/myapp';
```

**Benefits:**
- ✅ No external dependencies
- ✅ Full control
- ✅ No rate limits
- ✅ Included in backups

**Alternative: Supabase Self-Hosted**

You can actually self-host the entire Supabase stack!

```bash
git clone --depth 1 https://github.com/supabase/supabase
cd supabase/docker
cp .env.example .env
# Edit .env with your settings
docker compose up -d
```

**Includes:**
- PostgreSQL
- Auth
- Realtime
- Storage
- API
- Studio UI

---

## Component 4: Deployment Automation

### GitHub Actions → Auto Deploy

**Current Vercel:**
```
Git push → Vercel auto-detects → Builds → Deploys
```

**Self-Hosted Equivalent:**

**Step 1: GitHub Actions Workflow**

```yaml
# .github/workflows/deploy.yml
name: Deploy to Homelab

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      
      - name: Build Docker image
        run: |
          docker build -t myapp:latest .
      
      - name: Deploy to homelab
        uses: appleboy/ssh-action@master
        with:
          host: ${{ secrets.HOMELAB_HOST }}
          username: ${{ secrets.HOMELAB_USER }}
          key: ${{ secrets.SSH_PRIVATE_KEY }}
          script: |
            cd /opt/apps/myapp
            docker compose pull
            docker compose up -d --build
```

**Step 2: Prepare Homelab**

```bash
# On mini PC
mkdir -p /opt/apps/myapp
cd /opt/apps/myapp

# Create docker-compose.yml for the app
nano docker-compose.yml
```

```yaml
# /opt/apps/myapp/docker-compose.yml
version: '3.9'

services:
  myapp:
    image: ghcr.io/youruser/myapp:latest
    container_name: myapp
    ports:
      - "3000:3000"
    environment:
      - DATABASE_URL=postgresql://postgres:5432/myapp
    restart: unless-stopped
    networks:
      - homelab

networks:
  homelab:
    external: true
```

**Step 3: Configure Nginx Proxy Manager**

```
1. Login to NPM: http://192.168.1.239:81
2. Add Proxy Host:
   - Domain: app.matiasmassetti.com
   - Forward to: myapp (container name)
   - Port: 3000
   - Enable SSL
3. Save
```

**Result:**
```
Git push → GitHub Actions builds → 
→ Pushes to GitHub Container Registry → 
→ SSHs to homelab → 
→ Pulls new image → 
→ Restarts container → 
→ Live at app.matiasmassetti.com!
```

---

## Component 5: Cloudflare for CDN

**Keep using Cloudflare!** (Free tier is perfect)

**Setup:**
```
1. Domain DNS in Cloudflare
2. Proxy enabled (orange cloud) for all subdomains
3. Cloudflare caches static assets
4. DDoS protection included
5. Fast edge network worldwide
```

**Benefits:**
- ✅ Free CDN
- ✅ DDoS protection
- ✅ SSL included
- ✅ Page Rules (caching, redirects)
- ✅ Fast delivery worldwide

**This gives you Vercel's edge network speed for free!**

---

## Complete Replacement Setup

### Full Stack for Frontend + Backend Projects

**1. Reverse Proxy (Nginx Proxy Manager)**
```yaml
nginx-proxy-manager:
  image: 'jc21/nginx-proxy-manager:latest'
  ports:
    - '80:80'
    - '443:443'
    - '81:81'
  volumes:
    - npm-data:/data
    - npm-ssl:/etc/letsencrypt
  networks:
    - homelab
```

**2. Database (PostgreSQL)**
```yaml
postgres:
  image: postgres:16-alpine
  environment:
    POSTGRES_PASSWORD: secure_pass
  volumes:
    - postgres-data:/var/lib/postgresql/data
  networks:
    - homelab
```

**3. Image Optimization (imgproxy)**
```yaml
imgproxy:
  image: darthsim/imgproxy:latest
  ports:
    - "8081:8080"
  environment:
    - IMGPROXY_USE_ETAG=true
  networks:
    - homelab
```

**4. Your Apps (as many as you want!)**
```yaml
app1:
  image: your-app-1:latest
  ports:
    - "3001:3000"
  networks:
    - homelab

app2:
  image: your-app-2:latest
  ports:
    - "3002:3000"
  networks:
    - homelab

telegram-bot:
  image: your-bot:latest
  networks:
    - homelab
```

**5. Node.js Backend (for scrapers, APIs)**
```yaml
scraper-api:
  image: node:18-alpine
  working_dir: /app
  volumes:
    - ./scraper:/app
  command: npm start
  networks:
    - homelab
```

---

## Subdomain Automation

### Auto-Create Subdomains with Cloudflare API

**Script to create subdomain:**

```bash
#!/bin/bash
# create-subdomain.sh

SUBDOMAIN=$1
CF_ZONE_ID="your_zone_id"
CF_API_TOKEN="your_api_token"
HOMELAB_IP="your_public_ip"  # Or use Cloudflare Tunnel

# Create DNS record
curl -X POST "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records" \
  -H "Authorization: Bearer $CF_API_TOKEN" \
  -H "Content-Type: application/json" \
  --data '{
    "type": "A",
    "name": "'$SUBDOMAIN'",
    "content": "'$HOMELAB_IP'",
    "ttl": 1,
    "proxied": true
  }'

echo "Created $SUBDOMAIN.matiasmassetti.com"
```

**Usage:**
```bash
./create-subdomain.sh myapp
# Creates: myapp.matiasmassetti.com
```

**Integrate with deployment:**
```yaml
# In GitHub Actions
- name: Create subdomain
  run: |
    curl -X POST https://homelab.matiasmassetti.com/create-subdomain \
      -d "name=myapp"
```

---

## Cost Comparison

**Current (Vercel):**
```
Vercel Pro:             $20/month
Supabase (if paid):     $25/month (if you scale up)
─────────────────────────────────
TOTAL:                  $20-45/month
```

**Self-Hosted:**
```
Hardware:               $0 (already have mini PC)
Electricity:            ~$2/month extra
Software:               $0 (all open source)
Cloudflare:             $0 (free tier)
Domain:                 ~$10/year (Porkbun)
─────────────────────────────────
TOTAL:                  ~$2/month + $10/year
                        = ~$3/month average
```

**SAVINGS: $17/month = $204/year!** 🎉

---

## Migration Path

### Step-by-Step Migration

**Week 1: Setup Infrastructure**
```
Day 1: Install Nginx Proxy Manager
Day 2: Setup PostgreSQL
Day 3: Setup image optimization (if needed)
Day 4: Test with simple app
```

**Week 2: Migrate First App**
```
Day 1: Clone app from Vercel
Day 2: Update database connection
Day 3: Setup GitHub Actions
Day 4: Deploy and test
Day 5: Update DNS (Cloudflare)
Day 6: Monitor
```

**Week 3: Migrate Remaining Apps**
```
Repeat for each project
One app per day
```

**Week 4: Cancel Vercel**
```
Verify all apps working
Cancel Vercel subscription
SAVE $20/MONTH! 🎉
```

---

## Advantages of Self-Hosting

**Pros:**
```
✅ Save $240/year
✅ Unlimited projects
✅ Full control
✅ No vendor lock-in
✅ Learn valuable skills
✅ Unlimited bandwidth
✅ Faster iterations (local testing)
✅ Private data (no third party)
✅ Integrate with other homelab services
```

**Cons:**
```
❌ You're responsible for uptime
❌ Slower global edge (but Cloudflare helps!)
❌ Manual setup (but one-time)
❌ Need to maintain yourself
```

---

## When to Keep Vercel

**Keep Vercel if:**
- ❌ You deploy 10+ times per day
- ❌ You need guaranteed 99.99% uptime
- ❌ Global edge performance is critical
- ❌ You don't want any maintenance
- ❌ Team of 5+ developers

**Self-host if:**
- ✅ Personal projects
- ✅ Small team (1-3 people)
- ✅ Learning/experimentation
- ✅ Cost conscious
- ✅ Want full control
- ✅ Don't need 99.99% uptime (99% is fine!)

---

## Example: Complete Next.js App Self-Hosted

**Dockerfile:**
```dockerfile
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:18-alpine
WORKDIR /app
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/public ./public

EXPOSE 3000
CMD ["npm", "start"]
```

**docker-compose.yml:**
```yaml
version: '3.9'

services:
  nextjs-app:
    build: .
    container_name: myapp
    ports:
      - "3000:3000"
    environment:
      - DATABASE_URL=postgresql://postgres/myapp
      - NODE_ENV=production
    restart: unless-stopped
    networks:
      - homelab

networks:
  homelab:
    external: true
```

**Deploy:**
```bash
cd /opt/apps/myapp
git pull
docker compose up -d --build
```

**Access:**
```
https://myapp.matiasmassetti.com
```

**Done!** Same as Vercel, but self-hosted!

---

## Conclusion

**You can 100% replace Vercel with your homelab!**

**What you need:**
1. ✅ Nginx Proxy Manager (reverse proxy)
2. ✅ PostgreSQL (database)
3. ✅ imgproxy or Sharp (image optimization)
4. ✅ GitHub Actions (CI/CD)
5. ✅ Cloudflare (CDN, free!)

**Benefits:**
- Save $240/year
- Full control
- Unlimited projects
- Learn valuable skills
- No vendor lock-in

**Effort:**
- Initial setup: 4-6 hours
- Maintenance: ~1 hour/month
- Learning curve: Medium

**Recommendation:**
- Start with one small project
- Migrate gradually
- Keep Vercel for 1 month parallel (safety)
- Then cancel when confident

**Your mini PC can easily handle 10-20 apps!** 🚀

---

**Next Steps:**
1. Setup Nginx Proxy Manager
2. Choose your first app to migrate
3. Follow migration guide above
4. Test thoroughly
5. Migrate more apps
6. Cancel Vercel
7. Enjoy savings! 💰