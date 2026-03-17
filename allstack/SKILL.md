---
name: allstack
description: Use when working on the real-time-fund project to understand the complete technical stack including Next.js frontend, JSONP data fetching, Supabase authentication, Docker deployment, and Glassmorphism UI design system
---

# All Stack - Real-Time Fund Technical Documentation

## Overview

Complete technical reference for the 基估宝 (Real-time Fund Valuation) project - a pure front-end fund tracking tool built with Next.js 16 App Router, using JSONP to bypass CORS for static deployment on GitHub Pages.

**Core principle:** Pure client-side application with no backend server, all data stored in browser localStorage, static hosting on GitHub Pages or Docker containers.

## Quick Reference

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Frontend Framework** | Next.js 16.1.5, React 18.3.1 | App Router, SSR-disabled static export |
| **State Management** | React hooks, localStorage | Client-side state persistence |
| **UI Components** | Framer Motion 12.29.2, Recharts 3.7.0 | Animations, historical charts |
| **Styling** | CSS Custom Properties, Glassmorphism | Theme system in `app/globals.css` |
| **Data Fetching** | JSONP/Script Tag Injection | CORS bypass for external APIs |
| **Authentication** | Supabase 2.78.0, Email OTP | Cloud sync, user sessions |
| **Database** | Supabase PostgreSQL | Row-Level Security, real-time sync |
| **Testing** | Playwright 1.58.2 | E2E tests for auth flows |
| **Deployment** | Docker, GitHub Actions CI/CD | Multi-stage builds, health checks |
| **Date Handling** | Day.js 1.11.19 | Timezone-aware formatting |

## Architecture Overview

### Application Structure

```
app/
├── page.jsx              # Single Page App (~5000 lines) - all logic
├── layout.jsx            # Root layout with Google Analytics
├── globals.css           # Glassmorphism design system
├── lib/
│   └── supabase.js       # Supabase client with noop fallback
└── components/
    ├── AnalyticsGate.jsx # GA integration (domain-restricted)
    ├── Announcement.jsx  # In-app notifications
    └── Icons.jsx         # Inline icon components
```

**Key pattern:** Single-file architecture with inline components - no complex routing, no API routes, pure client-side SPA.

### Data Flow

```
External APIs (天天基金, 东方财富, 腾讯财经)
    ↓ JSONP/Script Tag Injection (CORS bypass)
Browser State (React hooks + localStorage)
    ↓ Bi-directional sync
Supabase Cloud (user_configs table, RLS)
    ↓ PostgreSQL Changes
Real-time updates across devices
```

## Frontend Stack

### Next.js Configuration

```javascript
// next.config.js
module.exports = {
  reactStrictMode: true,
  reactCompiler: true,  // React Compiler auto-optimization
};
```

**Important:** No API routes, static export to `./out` directory for GitHub Pages deployment.

### React Patterns

**Single Page App (app/page.jsx):**
- ~5000 lines containing all application logic
- Fund search, valuation display, historical charts
- Group management, import/export, cloud sync
- Inline icon components (PlusIcon, TrashIcon, etc.)

**State Management with localStorage:**
```javascript
const [funds, setFunds] = useState([]);
const [holdings, setHoldings] = useState([]);
const [viewMode, setViewMode] = useState('card');
const [favorites, setFavorites] = useState(new Set());
const [detailModal, setDetailModal] = useState(null);
const [user, setUser] = useState(null);
const [refreshMs, setRefreshMs] = useState(5000);
```

All state persists to browser localStorage automatically.

### UI Components

**Framer Motion Animations:**
- `AnimatePresence` for entry/exit animations
- `Reorder` for drag-and-drop fund reordering
- Spring animations for interactions
- Modal scale/opacity transitions

**Recharts Historical Charts:**
- Time ranges: 7d, 1m, 3m, 6m, 12m
- `LineChart` with `Line` (no dots, active dot on hover)
- Custom `XAxis`/`YAxis` styling
- `ResponsiveContainer` for full-width display

## Data Fetching (JSONP - CORS Bypass)

The application uses **four different JSONP techniques** to bypass CORS restrictions:

### 1. Fund Valuation Data (天天基金)

**Pattern:** Script tag injection with global callback interception

```javascript
const fetchFundValuation = (fundCode) => {
  const callbackName = `jsonpgz_${fundCode}_${Date.now()}`;
  const script = document.createElement('script');

  // Temporarily override global callback
  const originalCallback = window.jsonpgz;
  window.jsonpgz = (data) => {
    // Process data
    window.jsonpgz = originalCallback; // Restore
    document.body.removeChild(script);
  };

  script.src = `https://fundgz.1234567.com.cn/js/${fundCode}.js?callback=${callbackName}`;
  document.body.appendChild(script);
};
```

**URL:** `fundgz.1234567.com.cn/js/{code}.js`
**Callback:** `window.jsonpgz` (temporarily overridden)

### 2. Fund Search (东方财富)

**Pattern:** JSONP with dynamic callback

```javascript
const searchFunds = (query) => {
  const callbackName = `SuggestData_${Date.now()}`;
  window[callbackName] = (data) => {
    // Process search results
    delete window[callbackName];
  };

  const script = document.createElement('script');
  script.src = `https://fundsuggest.eastmoney.com/FundSearch/api/FundSearchAPI.ashjx?callback=${callbackName}&m=1&key=${query}`;
  document.body.appendChild(script);
};
```

**URL:** `fundsuggest.eastmoney.com/FundSearch/api/FundSearchAPI.ashjx`
**Callback:** Dynamically created global function

### 3. Historical Net Value (东方财富)

**Pattern:** Script tag injection with pagination

```javascript
const fetchHistoricalData = (fundCode, days) => {
  const pageCount = Math.ceil(days / 500);
  const promises = [];

  for (let page = 1; page <= pageCount; page++) {
    const script = document.createElement('script');
    script.src = `https://fundf10.eastmoney.com/F10DataApi.aspx?type=lsjz&code=${fundCode}&page=${page}&per=500&sdate=${startDate}&edate=${endDate}`;

    promises.push(new Promise((resolve) => {
      window[`callback_${page}`] = resolve;
      document.body.appendChild(script);
    }));
  }

  return Promise.all(promises);
};
```

**URL:** `fundf10.eastmoney.com/F10DataApi.aspx?type=lsjz`
**Pagination:** 500 items per page, max 20 pages
**Time ranges:** 7 days, 1/3/6/12 months (day/month units)

### 4. Stock Quotes (腾讯财经)

**Pattern:** Similar script injection approach

```javascript
const fetchStockQuote = (stockCode) => {
  const callbackName = `v_${stockCode}_${Date.now()}`;
  // Script tag injection pattern
};
```

## Authentication & Cloud Sync

### Supabase Integration

**Client Configuration (app/lib/supabase.js):**

```javascript
const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || '';
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || '';

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    autoRefreshToken: true,
    persistSession: true,
    detectSessionInUrl: true
  }
});
```

**Noop Fallback:**
- Graceful degradation when Supabase not configured
- `createNoopSupabase()` returns mock auth/table methods
- App functions offline without cloud sync

### Authentication Flow

**Email OTP (One-Time Password):**
```javascript
// Send OTP
const { data, error } = await supabase.auth.signInWithOtp({
  email: userEmail
});

// Verify OTP
const { data, error } = await supabase.auth.verifyOtp({
  email: userEmail,
  token: otpToken,
  type: 'email'
});
```

### Cloud Sync Architecture

**Database Schema:**
```sql
CREATE TABLE user_configs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID UNIQUE NOT NULL,
  config JSONB NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE user_configs ADD CONSTRAINT user_id_unique UNIQUE (user_id);
```

**Bi-directional Sync:**
```javascript
// Push to cloud
const syncToCloud = async () => {
  const { error } = await supabase
    .from('user_configs')
    .upsert({
      user_id: userId,
      config: { funds, holdings, favorites, groups },
      updated_at: new Date().toISOString()
    }, { onConflict: 'user_id' });
};

// Pull from cloud
const loadFromCloud = async () => {
  const { data, error } = await supabase
    .from('user_configs')
    .select('config, updated_at')
    .eq('user_id', userId)
    .maybeSingle();
};

// Real-time subscription
supabase
  .channel('config-changes')
  .on('postgres_changes', {
    event: '*',
    schema: 'public',
    table: 'user_configs',
    filter: `user_id=eq.${userId}`
  }, (payload) => {
    // Handle remote changes
  })
  .subscribe();
```

**Row Level Security (RLS):**
- Users can only read/write their own config
- Policy: `user_id = auth.uid()`

## Data Persistence

### Client-Side Storage

**All data in browser localStorage:**
- Container restart/delete does NOT lose data
- Clearing browser cache DOES lose data
- No server-side persistence (pure SPA)

**Backup Methods:**
1. **Export/Import:** JSON file download/upload
2. **Cloud Sync:** Automatic cross-device backup via Supabase
3. **Manual Backup:** `scripts/backup-data.sh` guidance

**LocalStorage Keys:**
```
funds_realtime_v5              # Fund list with valuations
holdings_realtime_v5           # User holdings
favorites_realtime_v5          # Favorite funds Set
groups_realtime_v5             # Fund groups
viewMode_realtime_v5           # Table/Card view preference
refreshMs_realtime_v5          # Auto-refresh interval (5-300s)
hasClosedAnnouncement_v5       # Dismissed announcements
user_realtime_v5               # Supabase session
```

## UI Design System

### Glassmorphism Theme (app/globals.css)

**CSS Custom Properties:**
```css
:root {
  --bg: #0f172a;           # Dark slate background
  --card: #111827;         # Card backgrounds
  --text: #e5e7eb;         # Primary text
  --muted: #9ca3af;        # Secondary text
  --primary: #22d3ee;      # Cyan accent
  --accent: #60a5fa;       # Blue accent
  --success: #34d399;      # Green (down = profit)
  --danger: #f87171;       # Red (up = loss in China)
  --border: #1f2937;       # Border color
}
```

**Glass Effect:**
```css
.glass {
  background: linear-gradient(180deg,
    rgba(255, 255, 255, 0.06),
    rgba(255, 255, 255, 0.02)
  );
  border: 1px solid var(--border);
  border-radius: 16px;
  box-shadow: 0 8px 30px rgba(0, 0, 0, 0.25);
  backdrop-filter: blur(8px);
}
```

**Background Gradient:**
```css
body {
  background:
    radial-gradient(1200px 600px at 10% -10%,
      rgba(96, 165, 250, 0.15), transparent 40%),
    radial-gradient(1000px 500px at 90% 0%,
      rgba(34, 211, 238, 0.12), transparent 45%),
    var(--bg);
}
```

### Responsive Grid System

**Card View (default):**
```css
.fund-card {
  grid-column: span 3;  /* 4 columns on >1440px */
}
@media (max-width: 1440px) { .fund-card { grid-column: span 4; } }  /* 3 columns */
@media (max-width: 1024px) { .fund-card { grid-column: span 6; } }  /* 2 columns */
@media (max-width: 640px) { .fund-card { grid-column: span 12; } }  /* 1 column */
```

**Table View (PC-optimized):**
```css
.table-row {
  display: grid;
  grid-template-columns: 2fr 1fr 1fr 1fr 1.2fr 1fr 1.2fr 1.2fr 1.2fr;
  /* Name, Net Value, Today Change, Yesterday Change, Time,
     Today Profit, Holding Amount, Holding Profit, Actions */
}
```

**Mobile Table:**
```css
@media (max-width: 768px) {
  .table-row {
    grid-template-columns: 1fr auto auto;
    grid-template-areas:
      "name today-change yesterday-change";
  }
  .table-header-row { display: none; }  /* Hide headers on mobile */
}
```

### Component Patterns

**Modal Pattern:**
```javascript
<ModalOverlay onClick={handleClose}>
  <ModalContent onClick={(e) => e.stopPropagation()}>
    {/* Modal content - click overlay to close */}
  </ModalContent>
</ModalOverlay>
```

**Swipe Actions (Mobile):**
```javascript
<Reorder.Item value={fund} dragHandleProps={dragHandleProps}>
  <div className="swipe-action-bg">Delete</div>
  <div className="item-content">{/* Fund card */}</div>
</Reorder.Item>
```

**Icons (inline components):**
```javascript
const PlusIcon = () => (
  <svg width="20" height="20" viewBox="0 0 20 20" fill="currentColor">
    <path d="M10 5v10M5 10h10" stroke="currentColor" strokeWidth="2" />
  </svg>
);
```

## Deployment

### Docker Multi-Stage Build

**Dockerfile:**
```dockerfile
# ===== Build stage =====
FROM node:22-bullseye AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install --legacy-peer-deps
COPY . .
RUN npx next build

# ===== Runtime stage =====
FROM node:22-bullseye AS runner
WORKDIR /app
ENV NODE_ENV=production
COPY --from=builder /app/package.json ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/.next ./.next
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD wget -qO- http://localhost:3000 || exit 1
CMD ["npm", "start"]
```

**Docker Compose:**
```yaml
services:
  app:
    build: .
    container_name: real-time-fund
    ports:
      - "3000:3000"
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    environment:
      - NODE_ENV=production
      - NEXT_PUBLIC_SUPABASE_URL=${NEXT_PUBLIC_SUPABASE_URL:-}
      - NEXT_PUBLIC_SUPABASE_ANON_KEY=${NEXT_PUBLIC_SUPABASE_ANON_KEY:-}
    env_file:
      - .env_local
```

### GitHub Pages Deployment

**Workflow (`.github/workflows/nextjs.yml`):**
```yaml
on:
  push:
    branches: ["main"]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: "20"
      - uses: actions/configure-pages@v5
        with:
          static_site_generator: next
          enablement: true
      - run: npm ci
      - run: npx next build
      - uses: actions/upload-pages-artifact@v3
        with:
          path: ./out

  deploy:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - uses: actions/deploy-pages@v4
```

**Environment Variables (GitHub Secrets):**
- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_ANON_KEY`
- `NEXT_PUBLIC_WEB3FORMS_ACCESS_KEY`

### Docker CI/CD

**Workflow (`.github/workflows/docker-ci.yml`):**
```yaml
on:
  push:
    branches: ["main"]

jobs:
  dockerfile-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - run: docker build -t real-time-fund .
      - run: docker run -d --name fund -p 3000:3000 real-time-fund
      - run: sleep 10 && curl -f http://localhost:3000
      - run: docker stop fund && docker rm fund

  docker-compose-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - run: docker compose up -d --build
      - run: sleep 10 && curl -f http://localhost:3000
      - run: docker compose down
```

## Testing

### E2E Testing (Playwright)

**Test Structure (tests/e2e/):**
```
tests/e2e/
└── auth/
    └── login.spec.ts    # Auth flow tests
```

**Example Test:**
```typescript
import { test, expect } from '@playwright/test';

test('email OTP login flow', async ({ page }) => {
  await page.goto('http://localhost:3000');
  await page.click('[data-testid="login-button"]');
  await page.fill('[data-testid="email-input"]', 'test@example.com');
  await page.click('[data-testid="send-otp-button"]');

  // Verify OTP sent message
  await expect(page.locator('.login-message.success'))
    .toContainText('验证码已发送');

  // Enter OTP (mock in tests)
  await page.fill('[data-testid="otp-input"]', '123456');
  await page.click('[data-testid="verify-button"]');

  // Verify logged in state
  await expect(page.locator('[data-testid="user-avatar"]'))
    .toBeVisible();
});
```

**Configuration:**
```javascript
// playwright.config.ts
export default defineConfig({
  testDir: './tests/e2e',
  fullyParallel: false,  // Avoid race conditions
  workers: 1,
  reporter: 'html',
  use: {
    baseURL: 'http://localhost:3000',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },
});
```

**Run Tests:**
```bash
# Start app first
docker compose up -d --build

# Run tests
npx playwright test

# View report
npx playwright show-report

# Cleanup
docker compose down
```

### Backup Testing Tools

**Validation Script (scripts/validate-backup.js):**
```javascript
const validateBackup = (backupFile) => {
  const data = JSON.parse(fs.readFileSync(backupFile));
  assert(data.funds, 'Missing funds array');
  assert(data.holdings, 'Missing holdings object');
  assert(Array.isArray(data.funds), 'funds must be array');
  console.log('✅ Backup file is valid');
};
```

**Interactive Test (scripts/test-backup.sh):**
```bash
#!/bin/bash
# Tests export/import functionality with real user data
# Validates backup file format and restore process
```

## Key Patterns & Conventions

### Code Patterns

1. **Inline Components:** Icons defined in `app/page.jsx` for single-file architecture
2. **Debouncing:** Search input uses debounce to avoid excessive API calls
3. **Error Handling:** Fallback to latest NAV data when valuation unavailable
4. **Merge Strategy:** Import merges data (not replace) to preserve existing entries
5. **Modal Close:** Click overlay to close, stopPropagation on content

### List View Columns Order

1. Name
2. Net Value
3. Today Change
4. Yesterday Change
5. Time
6. Today Profit
7. Holding Amount
8. Holding Profit
9. Actions

### Color Convention (Chinese Market)

- **Red (`--danger`):** Up/Price increase (loss in short positions)
- **Green (`--success`):** Down/Price decrease (profit in short positions)

**Opposite of Western markets** (where green = up, red = down).

### Group Management

- Funds can be removed from groups via detail modal button
- Button only shows when viewing a group (not "All" or "Favorites")
- Drag-and-drop reordering with Framer Motion `Reorder`

## Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| Charts not showing | Rebuild container: `docker compose up -d --build` |
| Data lost after cache clear | Use import feature to restore from backup |
| Modal not opening | Check console for errors, verify recharts installed |
| Historical data missing | API limitation, check console for fetch errors |
| Cloud sync not working | Verify Supabase env vars, check RLS policies |
| JSONP callback conflicts | Use unique callback names with timestamps |

## Environment Variables

**Runtime (Client-Side):**
```bash
NEXT_PUBLIC_SUPABASE_URL=https://xxx.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGci...
NEXT_PUBLIC_WEB3FORMS_ACCESS_KEY=xxx
```

**No build-time vars needed** for core functionality.

**Google Analytics:** Only loads on `Nelsontop.github.io` domain (see `AnalyticsGate` component).

## Node Version Requirement

**Minimum:** Node.js >= 20.9.0
**Docker:** Node 22 (bullseye slim)
**CI:** Node 20

See `package.json` engines field for enforcement.

## Related Documentation

- **CLAUDE.md:** Development workflow and coding standards
- **README.md:** Project overview and quick start
- **docs/DATA_PERSISTENCE.md:** Detailed backup guide
- **docs/BACKUP_TEST_REPORT.md:** Backup functionality test results

## Quick Commands Reference

```bash
# Development
docker compose up -d --build     # Build and start
docker compose logs -f           # View logs
docker compose restart           # Restart container
docker compose down              # Stop and remove

# Testing
npx playwright test              # Run E2E tests
npx playwright test --ui         # Run with UI
npx playwright show-report       # View HTML report

# Backup
bash scripts/test-backup.sh      # Test backup functionality
node scripts/validate-backup.js backup.json  # Validate backup file

# Git (after code changes)
git add . && git commit -m "feat: ..."
docker compose up -d --build     # Rebuild to verify
# Manual testing in browser
git push                         # Push only after tests pass
```

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                     User Browser (SPA)                      │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Next.js 16 App (app/page.jsx ~5000 lines)          │  │
│  │  - React hooks state management                     │  │
│  │  - localStorage persistence                         │  │
│  │  - Framer Motion animations                        │  │
│  │  - Recharts historical data visualization           │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
         │                                    │
         │ JSONP/Script Tag                   │ Supabase SDK
         │ (CORS bypass)                      │
         ↓                                    ↓
┌──────────────────────┐          ┌──────────────────────────┐
│  External APIs       │          │  Supabase Cloud          │
│  ┌──────────────┐    │          │  ┌────────────────────┐  │
│  │ 天天基金      │    │          │  │ PostgreSQL        │  │
│  │ Fund Valuation│   │          │  │ - user_configs    │  │
│  └──────────────┘    │          │  │ - RLS policies    │  │
│  ┌──────────────┐    │          │  └────────────────────┘  │
│  │ 东方财富      │    │          │  ┌────────────────────┐  │
│  │ Search/History│   │          │  │ Auth (Email OTP)   │  │
│  └──────────────┘    │          │  └────────────────────┘  │
│  ┌──────────────┐    │          │  ┌────────────────────┐  │
│  │ 腾讯财经      │    │          │  │ Real-time Sync     │  │
│  │ Stock Quotes │    │          │  │ postgres_changes   │  │
│  └──────────────┘    │          │  └────────────────────┘  │
└──────────────────────┘          └──────────────────────────┘
         │                                    │
         │ Static files                      │ JSON config
         ↓                                    ↓
┌──────────────────────┐          ┌──────────────────────────┐
│  GitHub Pages        │          │  Browser localStorage    │
│  (Static Hosting)    │          │  - funds_realtime_v5     │
│  ./out directory     │          │  - holdings_realtime_v5  │
└──────────────────────┘          │  - favorites_realtime_v5 │
                                  └──────────────────────────┘
```

## Summary

**Core Stack:** Next.js 16 + React 18 + Framer Motion + Recharts
**Data Fetching:** JSONP with script tag injection (4 different patterns)
**Authentication:** Supabase Email OTP with noop fallback
**Database:** Supabase PostgreSQL with Row-Level Security
**State Management:** React hooks + localStorage persistence
**Styling:** Glassmorphism design system with CSS custom properties
**Deployment:** Docker multi-stage builds + GitHub Pages static export
**Testing:** Playwright E2E for auth flows, backup validation scripts

**Key Differentiator:** Pure client-side SPA using JSONP to bypass CORS, enabling static hosting on GitHub Pages without a backend server, while still providing real-time data, cloud sync, and smooth animations.
