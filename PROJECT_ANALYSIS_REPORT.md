# AlgoVerse AI - Comprehensive Project Analysis & Architecture Report

> **Document Version:** 1.0.0  
> **Target Project:** AlgoVerse (`Uday-Mahajan-Dev/AlgoVerse`)  
> **Generated:** March 2026  
> **Status:** Active Development & Architecture Blueprint Alignment  

---

## Table of Contents

1. [Executive Summary & Platform Vision](#1-executive-summary--platform-vision)
2. [Technology Stack & Ecosystem Inventory](#2-technology-stack--ecosystem-inventory)
3. [System Architecture & Repository Topology](#3-system-architecture--repository-topology)
4. [Detailed Breakdown of Implemented Features](#4-detailed-breakdown-of-implemented-features)
   - [4.1 Backend: Data Layer, Models & Migrations](#41-backend-data-layer-models--migrations)
   - [4.2 Backend: Authentication, Security & RBAC Engine](#42-backend-authentication-security--rbac-engine)
   - [4.3 Backend: Services, Repositories & API Endpoints](#43-backend-services-repositories--api-endpoints)
   - [4.4 Frontend: Architecture, Routing & State Management](#44-frontend-architecture-routing--state-management)
   - [4.5 Frontend: Authentication UI & Social Login Integration](#45-frontend-authentication-ui--social-login-integration)
   - [4.6 Frontend: Student & Teacher Dashboards](#46-frontend-student--teacher-dashboards)
5. [Documented Architectural Modules & Target Roadmap](#5-documented-architectural-modules--target-roadmap)
   - [5.1 Story Engine & Interactive Concept Cards](#51-story-engine--interactive-concept-cards)
   - [5.2 Sandboxed Online Judge (Docker Execution)](#52-sandboxed-online-judge-docker-execution)
   - [5.3 AI DSA Tutor & Code Analysis](#53-ai-dsa-tutor--code-analysis)
   - [5.4 Machine Learning Adaptive Recommendation Engine](#54-machine-learning-adaptive-recommendation-engine)
   - [5.5 Gamification & Social Arenas](#55-gamification--social-arenas)
6. [Implementation Status Matrix & Gap Analysis](#6-implementation-status-matrix--gap-analysis)
7. [Recommended Next Steps & Action Items](#7-recommended-next-steps--action-items)

---

## 1. Executive Summary & Platform Vision

**AlgoVerse AI** is an API-first, adaptive Data Structures and Algorithms (DSA) learning platform. Its core objective is to bridge the gap between theoretical computer science and intuitive problem-solving by combining:

1. **Story-First Learning:** Abstract data structures (Stacks, Trees, Graphs, DP) taught via illustrated storylines, visual animations, and interactive mini-games.
2. **LeetCode-Style Online Judge:** Sandboxed code submission and evaluation engine supporting multiple languages (Java 21, C++17, Python).
3. **AI DSA Tutor:** Contextual code explanations, hints without spoiling solutions, and algorithmic time/space complexity analysis.
4. **Machine Learning Recommendation Engine:** Scikit-learn / XGBoost adaptive difficulty scaling based on individual student mastery curves and error patterns.
5. **Educator & Classroom Analytics:** Real-time visibility for teachers to track class progress, diagnose weak concepts, and assign curriculum modules.
6. **Gamification & Social Challenges:** Level/XP progression, daily streaks, badges, leaderboards, and peer challenges.

The system is architected as an **API-First Modular Monolith** on the backend with a **Flutter cross-platform client (Android, iOS, Web, Desktop)** on the frontend.

---

## 2. Technology Stack & Ecosystem Inventory

### 2.1 Backend Stack (FastAPI / Python)

| Technology / Library | Version / Spec | Purpose & Architectural Role |
| :--- | :--- | :--- |
| **Python** | `3.12+` | Backend runtime environment |
| **FastAPI** | `0.141.1` | High-performance asynchronous REST API framework |
| **Starlette** | `1.4.1` | Underlying ASGI framework & session middleware |
| **Uvicorn** | `0.52.1` | High-performance ASGI web server |
| **SQLAlchemy** | `2.0.51` | Object-Relational Mapper (ORM) with Mapped Column typing |
| **PostgreSQL** | `15+` | Primary relational database engine |
| **psycopg / psycopg2** | `3.3.4 / 2.9.12` | PostgreSQL database drivers |
| **Alembic** | `1.19.0` | Database schema version control and migration engine |
| **Pydantic / Pydantic Settings**| `2.13.4 / 2.14.2` | Data validation, serialisation, and environment configuration |
| **Firebase Admin SDK** | `7.5.0` | Server-side verification of Google & GitHub OAuth tokens |
| **Passlib + Bcrypt** | `1.7.4 / 4.0.1` | Password hashing with adaptive salt |
| **Python-Jose / Cryptography** | `3.5.0 / 50.0.0` | JWT token encoding, decoding, signing, and verification |
| **Python-Multipart** | `0.0.32` | Form-data parsing |
| **WebSockets** | `17.0.1` | Real-time communication protocol |
| **AnyIO / Greenlet** | `4.14.2 / 3.5.4` | Asynchronous event loop and concurrency utilities |
| **SMTPLib / Email-Validator** | Standard / `2.3.0` | Email OTP delivery and RFC-compliant address validation |

### 2.2 Frontend Stack (Flutter / Dart)

| Technology / Library | Version / Spec | Purpose & Architectural Role |
| :--- | :--- | :--- |
| **Flutter SDK** | `3.11+ / Material 3` | Cross-platform UI toolkit (Android, iOS, Web, Desktop) |
| **Dart** | `3.11+` | Strongly-typed client programming language |
| **Flutter Riverpod** | `^3.3.2` | Compile-time safe, reactive state management |
| **GoRouter** | `^17.3.0` | Declarative routing, deep linking, and navigation management |
| **Dio** | `^5.11.0` | Feature-rich HTTP client with interceptors |
| **Http** | `^1.6.0` | Lightweight HTTP client for network requests |
| **Flutter Secure Storage** | `^10.3.1` | Keychain (iOS) & Keystore (Android) encrypted token storage |
| **Firebase Core** | `^4.13.0` | Client-side Firebase infrastructure |
| **Firebase Auth** | `^6.5.7` | Firebase Authentication SDK |
| **Google Sign-In** | `^7.2.0` | Native Google OAuth authentication provider |
| **Hive / Hive Flutter** | `^2.2.3 / ^1.1.0` | Fast, lightweight NoSQL key-value database for offline caching |
| **Shared Preferences** | `^2.5.5` | Primitive key-value configuration storage |
| **Lottie** | `^3.3.2` | Vector animation renderer for story cards & gamification |

### 2.3 DevOps, Judge & Infrastructure Blueprint

| Component | Technology | Description |
| :--- | :--- | :--- |
| **Code Judge Sandbox** | Docker + Java 21 + C++17 | Resource-capped container execution (CPU, RAM, timeout) |
| **Message Queue / Cache** | Redis + Celery | Async task dispatch for judge submissions & AI tasks |
| **Media & Object Storage** | Cloudflare R2 / S3 API | Storage for story cards, videos, and animation assets |
| **Reverse Proxy & SSL** | Nginx + Let's Encrypt | Ingress routing, SSL termination, rate limiting |
| **CI/CD** | GitHub Actions | Automated linting, testing, and VPS Docker deployment |

---

## 3. System Architecture & Repository Topology

### 3.1 Repository Directory Structure

```text
AlgoVerse/
├── backend/
│   ├── alembic/                      # Database migration versions
│   │   ├── versions/                 # 6 migration revisions
│   │   └── env.py                    # Alembic migration runner
│   ├── app/
│   │   ├── api/                      # REST API Endpoints & Route Definitions
│   │   │   ├── deps.py               # Dependency injection (Auth, DB, RBAC)
│   │   │   ├── router.py             # Root v1 API router
│   │   │   └── v1/
│   │   │       ├── admin/            # Admin endpoints (Teacher Invitations)
│   │   │       ├── auth/             # Auth endpoints (Login, Register, OTP, Social)
│   │   │       └── health/           # Healthcheck endpoint
│   │   ├── core/                     # Configuration, Security, Enums, Logging
│   │   │   ├── config.py             # Pydantic Settings
│   │   │   ├── enums.py              # UserRole (STUDENT, TEACHER, ADMIN)
│   │   │   ├── firebase.py           # Firebase Admin App initialization
│   │   │   ├── security.py          # Password hashing, JWT & token hashing
│   │   │   └── teacher_invitation_enums.py
│   │   ├── db/                       # SQLAlchemy Engine & Session configuration
│   │   │   ├── base.py               # Model registry import aggregator
│   │   │   ├── base_class.py         # Declarative Base with ID & Timestamp mixins
│   │   │   └── session.py            # SessionLocal factory
│   │   ├── exceptions/               # Custom HTTP exception classes
│   │   ├── models/                   # SQLAlchemy ORM Data Models
│   │   │   ├── auth_provider.py      # OAuth identity links
│   │   │   ├── base_model.py         # UUID + Created/Updated audit model
│   │   │   ├── email_otp.py          # 6-digit OTP verification records
│   │   │   ├── refresh_token.py      # Stored refresh token hashes
│   │   │   ├── role.py               # RBAC Roles table
│   │   │   ├── teacher_invitation.py # Admin teacher invites
│   │   │   └── user.py               # User entity
│   │   ├── repositories/             # Data Access Layer (CRUD per model)
│   │   ├── schemas/                  # Pydantic Request/Response DTOs
│   │   ├── services/                 # Business Logic Layer
│   │   │   ├── auth_service.py       # Core authentication workflows
│   │   │   ├── email_otp_service.py  # OTP generation & validation logic
│   │   │   ├── email_service.py      # SMTP mail delivery
│   │   │   ├── firebase_auth_service.py # Firebase token verification
│   │   │   ├── social_auth_service.py   # Social login & auto-provisioning
│   │   │   └── teacher_invitation_service.py
│   │   ├── ai/                       # (Design Phase) AI Tutor module
│   │   ├── judge/                    # (Design Phase) Online Judge executor
│   │   ├── ml/                       # (Design Phase) ML Recommendation models
│   │   └── main.py                   # FastAPI Application Entrypoint
│   ├── scripts/                      # Seed scripts (seed_roles.py)
│   ├── firebase-service-account.json # Firebase Admin credentials
│   ├── requirements.txt              # Python dependency manifest
│   └── alembic.ini                   # Alembic configuration
│
├── frontend/app/
│   ├── lib/
│   │   ├── app/                      # App startup, Theme, and GoRouter setup
│   │   ├── core/
│   │   │   ├── constants/            # Routes, assets, network timeouts
│   │   │   ├── network/              # ApiClient with JSON HTTP handlers
│   │   │   ├── storage/              # TokenStorage (FlutterSecureStorage)
│   │   │   ├── theme/                # Colors, Spacing, Typography, Radius
│   │   │   └── widgets/              # Reusable UI components
│   │   ├── features/
│   │   │   ├── auth/                 # Login, Register, OTP Verification, Social Auth
│   │   │   ├── home/                 # Home overview & session management
│   │   │   ├── splash/               # Splash screen
│   │   │   ├── student_dashboard/    # Complete Student Dashboard UI & Widgets
│   │   │   └── teacher_dashboard/    # Teacher Dashboard with Clean Architecture
│   │   │       ├── data/             # Mock Data Source, DTO Models, Repository Impl
│   │   │       ├── domain/           # Entities & Repository Interfaces
│   │   │       └── presentation/     # Riverpod Providers, Pages & Widgets
│   │   ├── firebase_options.dart     # Generated Firebase client options
│   │   └── main.dart                 # Flutter App Entrypoint
│   └── pubspec.yaml                  # Flutter package manifest
│
└── docs/
    └── AlgoVerse_Documentation/      # 21 Architectural Specification Documents
```

### 3.2 High-Level Architecture Diagram

```
+-----------------------------------------------------------------------------------+
|                                 CLIENT LAYER                                      |
|   +---------------------------------------------------------------------------+   |
|   |                         Flutter Mobile & Web App                          |   |
|   |  - Auth UI (Login / Register / OTP)    - Student Dashboard (XP/Missions)  |   |
|   |  - Teacher Dashboard (Analytics)       - Riverpod State + GoRouter        |   |
|   |  - Secure Token Storage                - Firebase Auth (Google / GitHub)  |   |
|   +-------------------------------------+-------------------------------------+   |
+-----------------------------------------|-----------------------------------------+
                                          | HTTPS / REST / WebSockets
                                          v
+-----------------------------------------------------------------------------------+
|                                BACKEND MONOLITH                                   |
|   +---------------------------------------------------------------------------+   |
|   |                             FastAPI API Gateway                           |   |
|   |      SessionMiddleware | Bearer HTTP Auth | RBAC Route Dependencies       |   |
|   +-------------------------------------+-------------------------------------+   |
|                                         |                                         |
|   +-------------------------------------+-------------------------------------+   |
|   |                              Services Layer                               |   |
|   |  - AuthService         - SocialAuthService     - TeacherInvitationService |   |
|   |  - EmailOTPService     - EmailService (SMTP)   - FirebaseAuthService      |   |
|   +-------------------------------------+-------------------------------------+   |
|                                         |                                         |
|   +-------------------------------------+-------------------------------------+   |
|   |                            Repositories Layer                             |   |
|   |  - UserRepository      - RoleRepository        - RefreshTokenRepository   |   |
|   |  - EmailOTPRepository  - AuthProviderRepository- TeacherInviteRepository  |   |
|   +-------------------------------------+-------------------------------------+   |
|                                         |                                         |
|   +-------------------------------------+-------------------------------------+   |
|   |                             SQLAlchemy ORM                                |   |
|   |     User | Role | RefreshToken | EmailOTP | AuthProvider | TeacherInvite   |   |
|   +-------------------------------------+-------------------------------------+   |
+-----------------------------------------|-----------------------------------------+
                                          |
                                          v
+-----------------------------------------------------------------------------------+
|                              DATA & INFRASTRUCTURE                                |
|  - PostgreSQL (Relational DB)          - Firebase Auth Cloud Service              |
|  - Redis Cache / Queue (Planned)       - Docker Judge Sandbox (Planned)           |
+-----------------------------------------------------------------------------------+
```

---

## 4. Detailed Breakdown of Implemented Features

### 4.1 Backend: Data Layer, Models & Migrations

All models inherit from a common [BaseModel](file:///c:/Users/udayk/AlgoVerse/backend/app/models/base_model.py) which provides:
- UUIDv4 Primary Keys (`id: UUID`)
- Timezone-aware creation timestamp (`created_at: DateTime(timezone=True)`)
- Auto-updating modification timestamp (`updated_at: DateTime(timezone=True)`)

#### Implemented Tables & Entity Relationships

1. **`roles`** ([role.py](file:///c:/Users/udayk/AlgoVerse/backend/app/models/role.py)):
   - Stores system access roles: `STUDENT` (default), `TEACHER`, `ADMIN`.
   - Seeded via `seed_roles.py`.

2. **`users`** ([user.py](file:///c:/Users/udayk/AlgoVerse/backend/app/models/user.py)):
   - Attributes: `username`, `email`, `hashed_password`, `first_name`, `last_name`, `avatar_url`, `cover_image_url`, `bio`, `country`, `timezone`, `preferred_language`, `date_of_birth`, `gender`.
   - Flags: `is_active` (bool), `email_verified` (bool), `phone_verified` (bool).
   - Foreign Key: `role_id -> roles.id`.
   - Cascading relationships: `refresh_tokens`, `email_otps`, `auth_providers`.

3. **`email_otps`** ([email_otp.py](file:///c:/Users/udayk/AlgoVerse/backend/app/models/email_otp.py)):
   - Stores SHA-256 hashed 6-digit numeric OTP codes.
   - Fields: `user_id`, `otp_hash`, `expires_at` (10-minute lifetime), `attempts` (capped at 5), `used` (boolean).

4. **`refresh_tokens`** ([refresh_token.py](file:///c:/Users/udayk/AlgoVerse/backend/app/models/refresh_token.py)):
   - Stores SHA-256 hashed refresh tokens.
   - Fields: `user_id`, `token_hash`, `expires_at` (30-day lifetime), `revoked` (boolean), `device_name`, `ip_address`.

5. **`auth_providers`** ([auth_provider.py](file:///c:/Users/udayk/AlgoVerse/backend/app/models/auth_provider.py)):
   - Manages third-party federated logins (Firebase/Google/GitHub).
   - Unique Constraint: `(provider, provider_user_id)` to prevent duplicate links.

6. **`teacher_invitations`** ([teacher_invitation.py](file:///c:/Users/udayk/AlgoVerse/backend/app/models/teacher_invitation.py)):
   - Secure invitation workflow for teachers initiated by Admins.
   - Fields: `email`, `status` (`PENDING`, `ACCEPTED`, `EXPIRED`, `REVOKED`), `token_hash`, `invited_by` (FK to admin user), `expires_at` (48-hour lifetime), `accepted_at`.

#### Database Migration Version History (`alembic/versions/`):
- `68d6235bb05a`: Initial roles and users tables.
- `c2916a34d130`: Refresh token management table.
- `f954fb26367c`: Auth providers table for OAuth/Firebase integration.
- `575f764a705d`: Email and phone verification flags.
- `50379f94c158`: Email OTP verification system.
- `12174c995d8c`: Teacher invitations engine.

---

### 4.2 Backend: Authentication, Security & RBAC Engine

The authentication engine implemented in [app/services/auth_service.py](file:///c:/Users/udayk/AlgoVerse/backend/app/services/auth_service.py), [app/core/security.py](file:///c:/Users/udayk/AlgoVerse/backend/app/core/security.py), and [app/api/deps.py](file:///c:/Users/udayk/AlgoVerse/backend/app/api/deps.py) is production-grade and follows strict security standards:

```
[ User Registers / Logins ]
          │
          ├──────────────────────────┬────────────────────────────┐
          ▼                          ▼                            ▼
  [ Email & Password ]       [ Verify Email OTP ]          [ Firebase Social Auth ]
          │                          │                            │
   Bcrypt Hash Check          Verify Hash & Expiry         Firebase Admin Token Check
          │                          │                            │
          └──────────────────────────┼────────────────────────────┘
                                     ▼
                      [ Issue Access & Refresh JWT ]
                                     │
                 ┌───────────────────┴───────────────────┐
                 ▼                                       ▼
        Access Token (30 min)                  Refresh Token (30 days)
        Payload: {sub: user_id, type: "access"} SHA-256 Stored in DB
```

1. **Password Hashing:** Passlib with `bcrypt` (work factor: 12) generates secure one-way salted hashes.
2. **Dual-Token JWT Architecture:**
   - **Access Token:** Standard HS256 JWT, short expiry (30 mins), payload contains `sub: <user_id>` and `type: "access"`.
   - **Refresh Token:** Long expiry (30 days), payload contains `sub: <user_id>` and `type: "refresh"`. The plaintext token is never stored in the database—only its SHA-256 hash is saved.
3. **Token Rotation & Revocation:**
   - When `/auth/refresh` is called, the old refresh token is deleted/revoked and a new pair is issued.
   - When `/auth/logout` is called, the refresh token is marked `revoked = True` in the database.
4. **Email OTP Verification Flow:**
   - Generates cryptographically secure 6-digit numeric OTPs (`secrets.randbelow`).
   - Limits: 10 minutes expiry, maximum 5 failed attempts, 60-second cooldown between resend requests.
   - Delivered via asynchronous SMTP with HTML formatting.
5. **Firebase Social Auth Integration:**
   - Verifies Google/GitHub ID tokens via `firebase_admin.auth.verify_id_token`.
   - Auto-provisions new users or links existing email accounts.
   - Automatically checks if the user has an accepted Teacher Invitation and upgrades them to the `TEACHER` role.
6. **Role-Based Access Control (RBAC):**
   - FastAPI dependency injection guards:
     - `get_current_user`: Validates access token and active account status.
     - `get_current_admin`: Requires `role == "ADMIN"`.
     - `get_current_teacher`: Requires `role == "TEACHER"`.
     - `get_current_student`: Requires `role == "STUDENT"`.

---

### 4.3 Backend: Services, Repositories & API Endpoints

The API is fully modularized with standard schemas and clean status codes:

| Method | Endpoint | Auth Required | Description |
| :--- | :--- | :--- | :--- |
| `GET` | `/` | None | Root API health status |
| `GET` | `/api/v1/health` | None | Service liveness probe |
| `POST` | `/api/v1/auth/register` | None | Register new user with student role, triggers OTP |
| `POST` | `/api/v1/auth/verify-email` | None | Validates 6-digit OTP and activates email verification |
| `POST` | `/api/v1/auth/resend-verification` | None | Resends a fresh OTP code subject to cooldown |
| `POST` | `/api/v1/auth/login` | None | Authenticates email/password, issues JWT pair |
| `POST` | `/api/v1/auth/social-login` | None | Authenticates Firebase ID token (Google/GitHub) |
| `POST` | `/api/v1/auth/refresh` | None | Rotates refresh token and issues fresh access token |
| `POST` | `/api/v1/auth/logout` | None | Revokes refresh token in database |
| `GET` | `/api/v1/auth/me` | Bearer JWT | Returns current authenticated user profile |
| `POST` | `/api/v1/auth/teacher-invitations` | Admin Only | Creates and sends an invite link to an aspiring teacher |
| `GET` | `/api/v1/auth/teacher-invitations/accept` | None | Validates signed invitation token and approves teacher role |

---

### 4.4 Frontend: Architecture, Routing & State Management

The Flutter frontend is built with **Clean Architecture** principles and feature-based domain separation:

```text
lib/
├── app/          # App initialization, GoRouter routes, Theme definition
├── core/         # Cross-cutting concerns: Network, Storage, Theme tokens, Reusable Widgets
└── features/     # Feature modules: Auth, Student Dashboard, Teacher Dashboard, Home, Splash
```

#### Routing ([lib/app/router.dart](file:///c:/Users/udayk/AlgoVerse/frontend/app/lib/app/router.dart))
Configured via `GoRouter` with defined routes:
- `/` (`AppRoutes.splash`): Initial routing logic.
- `/login` (`AppRoutes.login`): Primary authentication entry.
- `/register` (`AppRoutes.register`): Account creation form.
- `/verify-email` (`AppRoutes.verifyEmail`): OTP submission page (receives `?email=` query parameter).
- `/home` (`AppRoutes.home`): Main application landing page.
- `/student-dashboard` (`AppRoutes.studentDashboard`): Student learning and gamification dashboard.
- `/teacher` (`AppRoutes.teacher`): Teacher analytics portal.

#### Design System & Tokenization
- **Typography & Theme:** Google Font pairings, strict Material 3 compliance.
- **Color Palette ([app_colors.dart](file:///c:/Users/udayk/AlgoVerse/frontend/app/lib/core/theme/app_colors.dart)):** Primary `#2563EB` (Indigo/Royal Blue), Background `#F8FAFC`, dark mode ready.
- **Tokens:** Standardized spacing (`AppSpacing`), corner radiuses (`AppRadius`), drop shadows (`AppShadow`).
- **Shared Widgets:** `PrimaryButton`, `SocialLoginButton`, `AppCard`, `AppScaffold`, `AppLogo`, `SectionTitle`.

---

### 4.5 Frontend: Authentication UI & Social Login Integration

1. **`LoginPage` ([login_page.dart](file:///c:/Users/udayk/AlgoVerse/frontend/app/lib/features/auth/presentation/pages/login_page.dart)):**
   - Clean, modern form with email and obscured password fields.
   - Dual social login buttons for **Google** and **GitHub**.
   - Direct integration with `SocialAuthService` -> `FirebaseAuth` -> `ApiClient.socialLogin` -> `TokenStorage.saveTokens`.
   - Auto-navigates to `/student-dashboard` upon Google sign-in.

2. **`RegisterPage` ([register_page.dart](file:///c:/Users/udayk/AlgoVerse/frontend/app/lib/features/auth/presentation/pages/register_page.dart)):**
   - Inputs: First name, Last name, Username, Email, Password (8+ character validation).
   - Upon successful submission, pushes to `/verify-email?email=<encoded_email>`.

3. **`VerifyEmailPage` ([verify_email_page.dart](file:///c:/Users/udayk/AlgoVerse/frontend/app/lib/features/auth/presentation/pages/verify_email_page.dart)):**
   - Large 6-digit spaced numeric text field.
   - Built-in "Resend verification code" cooldown action.
   - Success redirect to `/login`.

4. **`TokenStorage` ([token_storage.dart](file:///c:/Users/udayk/AlgoVerse/frontend/app/lib/core/storage/token_storage.dart)):**
   - Asynchronous encrypted storage via `FlutterSecureStorage` with persistent helpers: `getAccessToken()`, `getRefreshToken()`, `saveTokens()`, `clear()`.

---

### 4.6 Frontend: Student & Teacher Dashboards

#### Student Dashboard ([student_dashboard_page.dart](file:///c:/Users/udayk/AlgoVerse/frontend/app/lib/features/student_dashboard/presentation/pages/student_dashboard_page.dart))
A rich gamified dashboard built with the following modular sections:
- **Header & Profile:** Welcome greeting, notification trigger, and interactive confirmation logout modal.
- **Level & XP Progress Card:** High-contrast Indigo banner showing current Level (e.g. `Level 12`), XP progress (`780 / 1000 XP`), linear progress indicator, and XP needed for next level.
- **Continue Learning Card:** Current curriculum topic (e.g. `Binary Trees`), module category (`Data Structures & Algorithms`), percentage completion (`72% Complete`), and resumption CTA.
- **Daily Missions:** Multi-card list displaying 3 daily quests (e.g., "Solve 3 Problems", "Complete a Lesson", "Daily Challenge") with reward indicators (`+50 XP`, `+30 XP`, `+75 XP`) and progress bars.
- **Performance Metrics:** Side-by-side KPI cards highlighting **Day Streak** (Flame icon) and **Total XP Earned** (Bolt icon).
- **Next Achievement Roadmap:** Goal tracker showing problem completion metrics (e.g., `Problem Solver: 87 / 100 Problems solved`).
- **Weekly Challenge:** Algorithm Sprint progress tracker (`7 / 10 complete`, `200 XP`).
- **Recent Activity Feed:** Real-time log of recently solved problems and level-ups with XP badges.

#### Teacher Dashboard ([teacher_dashboard_page.dart](file:///c:/Users/udayk/AlgoVerse/frontend/app/lib/features/teacher_dashboard/presentation/pages/teacher_dashboard_page.dart))
Architected using Riverpod state management and Clean Architecture:
- **Responsive Layout:** Automatically adapts between a persistent Desktop Sidebar (`width >= 900px`) and a mobile Navigation Drawer (`width < 900px`).
- **KPI Stat Cards:** Total Enrolled Students (`120`), Active Learners (`87`), Average Class Mastery (`72%`), and Total Problems Solved (`1,842`).
- **Concept Performance Matrix:** Progress breakdown across core DSA topics: Arrays (84%), Linked Lists (71%), Stacks & Queues (67%), Trees (58%), Graphs (49%), and Dynamic Programming (43%).
- **Weak Concepts Alert Card:** Highlights struggling topics (e.g., DP, Graphs) and pinpoints the exact count of affected students needing intervention.
- **Recent Student Activity Feed:** Real-time student action stream with timestamps.

---

## 5. Documented Architectural Modules & Target Roadmap

Based on the 21 blueprint specification documents in `docs/AlgoVerse_Documentation/`, the remaining platform modules have been designed as follows:

```
                                 [ Learning Pipeline ]
                                           │
  ┌────────────────────────────────────────┼────────────────────────────────────────┐
  ▼                                        ▼                                        ▼
[ Story Engine ]                  [ Online Judge Engine ]                  [ AI & ML Intelligence ]
• Narrative Chapters              • Docker Execution Sandbox               • AI DSA Tutor (LLM)
• Interactive Concept Cards       • Java 21 / C++17 / Python               • Socratic Hint System
• Step-by-Step Animations         • Celery + Redis Queue                   • ML Adaptive Difficulty
• Mini-Games & Quizzes            • Test Case Memory/Time Limiter          • Retention & Mastery Model
```

### 5.1 Story Engine & Interactive Concept Cards
- **Purpose:** Transform algorithms into narrative journeys where data structures are characters in a visual storyline.
- **Components:**
  - **Topic Progression:** Topics partitioned into narrative chapters.
  - **Card Types:** Theory Cards, Visualization Cards, Interactive Mini-Games, and Checkpoint Quizzes.
  - **Asset Delivery:** Object storage URLs (Cloudflare R2) serving Lottie animations and vector assets.

### 5.2 Sandboxed Online Judge (Docker Execution)
- **Purpose:** Provide LeetCode-style code submission, compilation, and evaluation.
- **Execution Flow:**
  1. Student submits code via Flutter editor.
  2. FastAPI enqueues submission into **Redis Queue**.
  3. **Celery Worker** spins up an isolated, non-root **Docker Sandbox Container**.
  4. Compiles and executes code against public and hidden test cases with strict constraints:
     - CPU Limit: `1 core`
     - Memory Limit: `256 MB`
     - Execution Timeout: `2.0 seconds`
     - Network Access: Disabled
  5. Returns structured verdict: `Accepted (AC)`, `Wrong Answer (WA)`, `Time Limit Exceeded (TLE)`, `Memory Limit Exceeded (MLE)`, or `Compilation Error (CE)`.

### 5.3 AI DSA Tutor & Code Analysis
- **Capabilities:**
  - **Socratic Hints:** 3-stage incremental hints without revealing the full solution.
  - **Code Explanation:** Step-by-step breakdown of submitted logic.
  - **Complexity Estimation:** Automated calculation of Big-O Time and Space complexities.
  - **Bug Localization:** Pinpoints logical edge cases that failed hidden test cases.

### 5.4 Machine Learning Adaptive Recommendation Engine
- **Models:** Scikit-learn and XGBoost regression/classification pipelines.
- **Inputs:** Student submission history, error frequency, hint usage count, time taken per problem, and quiz accuracy.
- **Outputs:**
  - Predicted topic mastery score ($0.0 \rightarrow 1.0$).
  - Recommended next challenge tailored to the student's current skill frontier.
  - Identification of prerequisite concepts requiring revision.

### 5.5 Gamification & Social Arenas
- **Features:**
  - **XP & Coin Economy:** Earned from solving problems, daily logins, and story completion.
  - **Daily Streaks:** Streak protection freezes and milestone badges.
  - **Leaderboards:** Global, regional, and classroom leaderboards powered by Redis Sorted Sets (`ZSET`).
  - **Peer Challenges (1v1 Arena):** Real-time timed coding duels via WebSockets.

---

## 6. Implementation Status Matrix & Gap Analysis

| Module / Component | Layer | Implementation Status | Current State |
| :--- | :--- | :--- | :--- |
| **Relational Database Schema** | Backend | **Completed** | 6 Alembic migrations, PostgreSQL ORM models with UUIDs |
| **Email/Password Auth & OTP** | Backend | **Completed** | Bcrypt hashing, 6-digit numeric OTP, SMTP service |
| **JWT Access & Refresh Engine** | Backend | **Completed** | HS256 tokens, DB hash storage, rotation, and revocation |
| **Firebase Social Auth** | Backend | **Completed** | Google & GitHub verification via Firebase Admin SDK |
| **Role-Based Access Control (RBAC)**| Backend | **Completed** | `STUDENT`, `TEACHER`, `ADMIN` with FastAPI dependency guards |
| **Teacher Invitation Engine** | Backend | **Completed** | Admin invite creation, signed url tokens, auto-promotion |
| **Health & Diagnostic APIs** | Backend | **Completed** | `/api/v1/health` and root probe |
| **Flutter Design System** | Frontend | **Completed** | Colors, Spacing, Typography, Radius, Custom Widgets |
| **Flutter Authentication UI** | Frontend | **Completed** | Login, Register, Verify Email, Firebase Social Auth |
| **Flutter Secure Token Storage** | Frontend | **Completed** | Encrypted token storage with auto-refresh hooks |
| **Student Dashboard UI** | Frontend | **Completed** | Level/XP, Missions, Streak, Achievements, Activity Feed |
| **Teacher Dashboard UI & State**| Frontend | **Completed** | Riverpod clean architecture, KPIs, Weak concepts, Matrix |
| **Teacher Dashboard Live API Link**| Fullstack | *In Progress / Mocked* | UI powered by `TeacherDashboardMockDataSource` |
| **Story Engine APIs & Models** | Fullstack | *Design Ready* | Blueprint frozen; models & endpoints to be scaffolded |
| **Online Judge Sandbox & Worker**| Backend | *Design Ready* | Blueprint frozen; Celery + Docker executor to be built |
| **AI DSA Tutor Integration** | Backend | *Design Ready* | Prompt blueprints ready; LLM gateway to be integrated |
| **ML Recommendation Pipeline** | Backend | *Design Ready* | Model architecture specified; training pipeline pending |
| **WebSockets (1v1 Duels / Live)**| Fullstack | *Design Ready* | WebSocket dependency installed; handlers pending |

---

## 7. Recommended Next Steps & Action Items

To progress from the current robust foundation towards the complete MVP, the following sequence of development is recommended:

```
[ Phase 1: Dashboard API Binding ]
  └── Connect Flutter Teacher & Student Dashboards to live FastAPI endpoints.
  
[ Phase 2: Story Engine Development ]
  ├── Create SQLAlchemy models: Topics, Chapters, Stories, ConceptCards, Quizzes.
  ├── Implement Story REST APIs (/api/v1/stories/...).
  └── Build Flutter Story Player with Lottie animations.

[ Phase 3: Online Judge Engine ]
  ├── Setup Redis & Celery task worker.
  ├── Create Docker runner container with Java 21 and C++17 compilers.
  ├── Build Problem Catalog & Submission APIs (/api/v1/judge/submit).
  └── Integrate Flutter In-App Code Editor.

[ Phase 4: AI Tutor & ML Recommendations ]
  ├── Implement FastAPI AI router with OpenAI/Gemini SDK for Socratic hints.
  └── Train initial Scikit-learn mastery assessment model.

[ Phase 5: Production Deployment ]
  └── Docker Compose multi-container setup (FastAPI + PostgreSQL + Redis + Celery + Nginx).
```

---

*Report prepared automatically from codebase inspection and documentation analysis.*
