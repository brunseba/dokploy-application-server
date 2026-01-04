# ADR-002: Use Next.js for Frontend and API Layer

**Status**: Accepted  
**Date**: 2024-12-30  
**Deciders**: Architecture Team, Engineering Team  
**Technical Story**: Frontend framework and API architecture selection  

---

## Context

Dokploy requires a modern web application framework that can deliver:

1. **Rich Interactive UI**: Dashboard for managing applications, databases, monitoring
2. **API Layer**: RESTful endpoints for UI and external integrations
3. **Server-Side Rendering**: Fast initial page loads, SEO-friendly
4. **Real-time Updates**: WebSocket support for logs, metrics, deployments
5. **Authentication**: Secure login with local and OIDC support
6. **Developer Experience**: Fast development, hot reload, TypeScript support
7. **Performance**: Optimized builds, code splitting, efficient rendering

The framework choice impacts development velocity, application performance, maintainability, and team onboarding.

### Requirements

**Must Have**:
- TypeScript support (first-class)
- Server-side rendering (SSR) and static generation (SSG)
- API route support (backend logic)
- WebSocket integration capability
- Authentication middleware support
- State management compatibility
- Component-based architecture
- Hot module reloading
- Production-ready build system
- SEO optimization

**Should Have**:
- Material UI compatibility
- Dark mode support
- Internationalization (i18n)
- File-based routing
- Image optimization
- CSS-in-JS or Tailwind support
- Edge deployment capability
- Incremental Static Regeneration (ISR)

**Nice to Have**:
- Built-in analytics
- Automatic code splitting
- Built-in testing support
- Middleware for request processing
- Edge functions support

### Target Developer Profile

- Primary: Full-stack developers familiar with React
- Secondary: Frontend specialists learning backend
- Expertise: Intermediate JavaScript/TypeScript
- Team size: 5-15 contributors (open source)

---

## Decision

We will use **Next.js 14+** (App Router) with TypeScript as the frontend framework and API layer for Dokploy.

---

## Rationale

### Full-Stack Framework

Next.js provides both frontend and backend in one framework:
- **API Routes**: Backend endpoints without separate server
- **Server Components**: React components that run on server
- **Server Actions**: Direct server-side mutations
- **Middleware**: Request/response interception

This reduces complexity and deployment overhead (single container).

### Performance Optimization

Next.js excels at performance:
- **Automatic code splitting**: Only load what's needed
- **Image optimization**: Automatic WebP, lazy loading, responsive
- **Font optimization**: Automatic font loading optimization
- **Static generation**: Build HTML at build time when possible
- **Incremental Static Regeneration**: Update static pages without rebuild

Measured performance:
- Lighthouse score: 95+ achievable
- First Contentful Paint: <1.5s
- Time to Interactive: <3.5s

### Developer Experience

Next.js prioritizes DX:
- **Fast Refresh**: Instant feedback on code changes
- **TypeScript**: First-class support, zero config
- **File-based routing**: Intuitive route structure
- **Built-in linting**: ESLint configuration included
- **Error overlays**: Clear error messages in development

Average developer onboarding: 1-2 days for Next.js basics.

### React Ecosystem Access

Leverages the massive React ecosystem:
- Material UI (20M+ weekly downloads)
- React Query for data fetching
- Zustand/Redux for state management
- Vast component libraries
- Extensive tutorial and support content

This accelerates development and reduces custom code.

### Deployment Flexibility

Next.js supports multiple deployment targets:
- Docker containers (our use case)
- Vercel (first-party hosting)
- AWS, GCP, Azure
- Edge runtimes (Cloudflare Workers)
- Self-hosted Node.js

This aligns with our "Self-Hosting Capable" principle.

### SEO and Accessibility

Next.js provides SEO tools:
- Server-side rendering for crawlers
- Meta tag management
- Sitemap generation
- Structured data support
- Automatic accessibility linting

### Active Development and Community

Next.js has strong backing:
- Maintained by Vercel (well-funded company)
- 120K+ GitHub stars
- 3M+ weekly npm downloads
- Regular releases (monthly)
- Large community and ecosystem
- Conference (Next.js Conf annually)

---

## Alternatives Considered

### Alternative 1: Remix

**Pros**:
- Modern React framework
- Excellent form handling
- Progressive enhancement focus
- Nested routing
- Web standards-based
- Great developer experience

**Cons**:
- Smaller ecosystem than Next.js
- Less mature (released 2021 vs 2016 for Next.js)
- Fewer deployment options
- Smaller community (10K stars vs 120K)
- Less tooling and tutorials
- No built-in image optimization

**Why Not Chosen**:
While technically excellent, Remix's smaller ecosystem and community make it riskier for an open-source project needing contributors. Next.js's maturity and widespread adoption reduce onboarding friction.

### Alternative 2: SvelteKit

**Pros**:
- Excellent performance (no virtual DOM)
- Simple syntax (less boilerplate)
- Smaller bundle sizes
- Great developer experience
- Built-in state management

**Cons**:
- Smaller ecosystem than React
- Fewer React component libraries work with Svelte
- Smaller talent pool (harder to find contributors)
- Less enterprise adoption
- Smaller community (18K stars)
- Material UI not available (limited UI libraries)

**Why Not Chosen**:
Svelte's smaller ecosystem violates our "API-First" principle (need extensive libraries). React's ecosystem advantage outweighs performance benefits for our use case. Contributor acquisition would be harder.

### Alternative 3: Nuxt.js (Vue)

**Pros**:
- Mature Vue framework
- Similar features to Next.js
- Great documentation
- Strong community
- Good performance

**Cons**:
- Vue ecosystem smaller than React
- TypeScript support improving but historically weaker
- Material UI not available (different UI libraries)
- Smaller community than Next.js
- Fewer full-stack developers know Vue vs React

**Why Not Chosen**:
React's ecosystem and developer pool are larger. Most full-stack developers know React, reducing contributor barriers.

### Alternative 4: Separate SPA + Backend API

**Pros**:
- Clear separation of concerns
- Independent scaling
- Technology flexibility (any frontend + any backend)
- Better for microservices

**Cons**:
- Increased deployment complexity (two containers minimum)
- More operational overhead
- Slower initial page loads (client-side rendering)
- Poor SEO without SSR
- More code (separate API definitions)
- Increased development time
- CORS configuration needed

**Why Not Chosen**:
Violates "Developer Experience Focus" and "Cost-Effectiveness" principles. Adds complexity without clear benefit for our use case. Next.js API routes provide sufficient backend capability.

### Alternative 5: Plain React + Express.js

**Pros**:
- Maximum flexibility
- Familiar technologies
- Simple mental model
- Well-understood patterns

**Cons**:
- No SSR without custom implementation
- Manual routing setup
- No built-in optimization
- More boilerplate code
- Slower development
- Manual build configuration
- No file-based routing

**Why Not Chosen**:
Reinvents features Next.js provides out-of-box. Development velocity would be significantly slower.

---

## Consequences

### Positive

1. **Fast Development**: File-based routing, API routes, hot reload accelerate development
2. **Performance**: Automatic optimizations (images, fonts, code splitting)
3. **SEO-Friendly**: Server-side rendering ensures good search rankings
4. **Single Deployment**: Frontend + backend in one container
5. **Large Ecosystem**: Access to entire React ecosystem
6. **Easy Onboarding**: Most developers know React
7. **Future-Proof**: Strong backing from Vercel ensures longevity
8. **Flexibility**: Can deploy anywhere, not locked to specific platform

### Negative

1. **Learning Curve**: New developers must learn Next.js conventions (App Router, Server Components)
2. **Bundle Size**: Next.js adds ~70KB gzipped base bundle (vs vanilla React ~45KB)
3. **Opinionated**: File-based routing not configurable
4. **Vendor Influence**: Vercel controls roadmap (though open source)
5. **Breaking Changes**: Major versions can require migration (Pages → App Router)
6. **Build Times**: Can be slow for very large apps (100+ routes)
7. **Debugging Complexity**: SSR bugs harder to debug than client-only

### Mitigation Strategies

**For Learning Curve**:
- Comprehensive contributor documentation
- Video tutorials for onboarding
- Code examples and patterns
- Mentorship for new contributors

**For Bundle Size**:
- Use dynamic imports for large components
- Optimize third-party library imports
- Regular bundle analysis (next/bundle-analyzer)
- Target <200KB total bundle for initial load

**For Build Times**:
- Use incremental builds in CI/CD
- Optimize build configuration
- Cache node_modules and .next folder
- Current codebase unlikely to hit scale issues

**For Breaking Changes**:
- Stay on LTS versions when available
- Test upgrades thoroughly in development
- Maintain backward compatibility when possible
- Document migration paths for users

---

## Implementation Details

### Project Structure

```
dokploy/
├── app/                    # Next.js App Router
│   ├── (auth)/            # Authentication group
│   │   ├── login/
│   │   └── register/
│   ├── (dashboard)/       # Protected dashboard
│   │   ├── applications/
│   │   ├── databases/
│   │   └── monitoring/
│   ├── api/               # API routes
│   │   ├── apps/
│   │   ├── databases/
│   │   └── deployments/
│   ├── layout.tsx         # Root layout
│   └── page.tsx           # Home page
├── components/            # React components
│   ├── ui/               # Material UI components
│   └── features/         # Feature components
├── lib/                   # Utilities
│   ├── docker.ts         # Docker API client
│   └── db.ts             # Database client
├── public/               # Static assets
├── styles/               # Global styles
└── next.config.js        # Next.js configuration
```

### API Route Example

```typescript path=/app/api/apps/route.ts start=null
import { NextRequest, NextResponse } from 'next/server'
import { getServerSession } from 'next-auth'
import { dockerClient } from '@/lib/docker'

export async function GET(request: NextRequest) {
  const session = await getServerSession()
  
  if (!session) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }
  
  const services = await dockerClient.listServices()
  return NextResponse.json({ services })
}

export async function POST(request: NextRequest) {
  const session = await getServerSession()
  
  if (!session) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }
  
  const body = await request.json()
  const service = await dockerClient.createService(body)
  
  return NextResponse.json({ service }, { status: 201 })
}
```

### Server Component Example

```typescript path=/app/(dashboard)/applications/page.tsx start=null
import { getApplications } from '@/lib/db'
import ApplicationCard from '@/components/features/ApplicationCard'

export default async function ApplicationsPage() {
  // Fetch data on server
  const applications = await getApplications()
  
  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
      {applications.map(app => (
        <ApplicationCard key={app.id} application={app} />
      ))}
    </div>
  )
}
```

### Configuration

```javascript path=/next.config.js start=null
/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'standalone', // For Docker deployment
  experimental: {
    serverActions: true,
  },
  images: {
    domains: ['avatars.githubusercontent.com'],
  },
  webpack: (config, { isServer }) => {
    // Custom webpack configuration
    return config
  },
}

module.exports = nextConfig
```

---

## Integration Points

### Docker API Client

```typescript path=/lib/docker.ts start=null
import Docker from 'dockerode'

export const dockerClient = new Docker({
  socketPath: '/var/run/docker.sock'
})

export async function deployService(config: ServiceConfig) {
  return dockerClient.createService({
    Name: config.name,
    TaskTemplate: {
      ContainerSpec: {
        Image: config.image,
        Env: config.env,
      },
      Resources: {
        Limits: {
          MemoryBytes: config.memoryLimit,
        },
      },
    },
    Mode: {
      Replicated: {
        Replicas: config.replicas,
      },
    },
  })
}
```

### Database Integration

```typescript path=/lib/db.ts start=null
import { Pool } from 'pg'

export const pool = new Pool({
  host: process.env.POSTGRES_HOST,
  database: process.env.POSTGRES_DB,
  user: process.env.POSTGRES_USER,
  password: process.env.POSTGRES_PASSWORD,
  port: 5432,
})

export async function query(text: string, params?: any[]) {
  const client = await pool.connect()
  try {
    return await client.query(text, params)
  } finally {
    client.release()
  }
}
```

### Authentication

```typescript path=/lib/auth.ts start=null
import NextAuth from 'next-auth'
import CredentialsProvider from 'next-auth/providers/credentials'
import { OIDCProvider } from 'next-auth/providers/oidc'

export const authOptions = {
  providers: [
    CredentialsProvider({
      name: 'Credentials',
      credentials: {
        username: { label: "Username", type: "text" },
        password: { label: "Password", type: "password" }
      },
      async authorize(credentials) {
        // Validate credentials
        return user || null
      }
    }),
    OIDCProvider({
      clientId: process.env.OIDC_CLIENT_ID,
      clientSecret: process.env.OIDC_CLIENT_SECRET,
      issuer: process.env.OIDC_ISSUER,
    })
  ],
  callbacks: {
    async jwt({ token, user }) {
      if (user) {
        token.role = user.role
      }
      return token
    },
  },
}

export default NextAuth(authOptions)
```

---

## Performance Considerations

### Bundle Size Targets

- Initial bundle: <200KB gzipped
- Per-route: <50KB additional
- Images: Lazy loaded, optimized formats

### Optimization Strategies

1. **Code Splitting**: Dynamic imports for heavy components
2. **Image Optimization**: Next.js Image component with WebP
3. **Font Optimization**: next/font for automatic font loading
4. **Static Generation**: Pre-render dashboard shell
5. **Caching**: Aggressive caching of static assets

### Monitoring

```typescript path=/app/layout.tsx start=null
import { Analytics } from '@vercel/analytics/react'

export default function RootLayout({ children }) {
  return (
    <html lang="en">
      <body>
        {children}
        <Analytics /> {/* Optional for self-hosted */}
      </body>
    </html>
  )
}
```

---

## Validation

### Success Criteria

- ✅ Lighthouse Performance: >90
- ✅ First Contentful Paint: <1.5s
- ✅ Time to Interactive: <3.5s
- ✅ Bundle size: <200KB initial
- ✅ Hot reload: <1s
- ✅ Build time: <2 minutes for production

### Testing Strategy

```typescript path=/app/api/apps/route.test.ts start=null
import { GET, POST } from './route'
import { NextRequest } from 'next/server'

describe('/api/apps', () => {
  it('requires authentication', async () => {
    const request = new NextRequest('http://localhost:3000/api/apps')
    const response = await GET(request)
    
    expect(response.status).toBe(401)
  })
  
  it('returns applications for authenticated user', async () => {
    // Mock authenticated session
    const request = new NextRequest('http://localhost:3000/api/apps')
    const response = await GET(request)
    
    expect(response.status).toBe(200)
  })
})
```

---

## Related

- **ADR-001**: Docker Swarm orchestration (Docker API integration)
- **ADR-005**: Material UI (Component library choice)
- **ADR-006**: PostgreSQL (Database accessed via Next.js API)
- **Architecture Vision**: Developer experience focus principle
- **Container Diagram**: Shows Next.js as API and Web container

---

## References

- [Next.js Documentation](https://nextjs.org/docs)
- [Next.js App Router](https://nextjs.org/docs/app)
- [React Server Components](https://react.dev/blog/2023/03/22/react-labs-what-we-have-been-working-on-march-2023#react-server-components)
- [Next.js Performance](https://nextjs.org/docs/pages/building-your-application/optimizing)
- [Dockerizing Next.js](https://nextjs.org/docs/deployment#docker-image)

---

## Decision Log

| Date | Action | Reason |
|------|--------|--------|
| 2024-12-30 | Status: Accepted | Initial architectural decision |
| Future | Evaluate App Router migration | When stable and production-ready |
| Q2 2025 | Performance audit | Ensure targets still met |

---

**Last Updated**: 2024-12-30  
**Next Review**: 2025-06-30  
**Superseded By**: None  
**Supersedes**: None
