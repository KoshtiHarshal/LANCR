# Lancr — Freelance Marketplace App

A full-stack mobile application connecting freelancers with clients. Built with Flutter and Supabase as a portfolio project.

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)
![Supabase](https://img.shields.io/badge/Supabase-PostgreSQL-3ECF8E?logo=supabase)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)
![Status](https://img.shield  s.io/badge/Status-In%20Progress-F59E0B)

---

## 📱 About

**Lancr** is a freelance marketplace mobile app where clients can post projects and hire talent, and freelancers can browse projects and submit proposals — similar to Upwork or Fiverr, built from scratch as a placement portfolio project.

---

## ✨ Features

### ✅ Completed
- **Authentication** — Email/password login and registration via Supabase Auth
- **Role Selection** — Users choose Freelancer or Client on first login
- **Edit Profile** — Name, headline, bio, skills, location, experience, portfolio & LinkedIn URLs
- **Client Home** — Dashboard with posted projects overview
- **Post a Project** — Clients can post projects with title, description, budget, skills, and duration
- **Browse Projects** — Freelancers can browse open projects with skill-based filtering
- **Project Detail** — Full project view with client info, budget, duration, and required skills
- **Submit Proposal** — Freelancers submit a cover letter and bid amount
- **Proposal Status** — Freelancers can track proposal status (Pending / Accepted / Rejected)

### 🔲 In Progress
- **View Proposals** — Clients can view all proposals on their project and Accept/Reject
- **My Proposals Tab** — Freelancers can track all their submitted proposals
- **My Projects Tab** — Clients can manage all their posted projects

### 📋 Planned
- **Notifications** — Real-time alerts for proposal updates
- **Messaging** — In-app chat between freelancer and client
- **Reviews & Ratings** — Post-project feedback system
- **Search & Filters** — Advanced project search by budget, duration, skills

---

## 🛠 Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter 3.x (Dart) |
| State Management | Riverpod 3.x |
| Navigation | GoRouter |
| Backend / Database | Supabase (PostgreSQL) |
| Authentication | Supabase Auth |
| Storage | Supabase Storage |

---

## 🗄 Database Schema

### `profiles`
| Column | Type | Description |
|---|---|---|
| id | uuid | References auth.users |
| email | text | User email |
| role | text | `freelancer` or `client` |
| name | text | Display name |
| headline | text | Short professional title |
| bio | text | About me |
| skills | text[] | Array of skills |
| location | text | City / Country |
| company | text | Company name (clients) |
| experience_years | int | Years of experience |
| portfolio_url | text | Portfolio website |
| linkedin_url | text | LinkedIn profile |
| profile_completed | boolean | Onboarding status |
| created_at | timestamptz | Account creation time |

### `projects`
| Column | Type | Description |
|---|---|---|
| id | uuid | Primary key |
| client_id | uuid | References profiles |
| title | text | Project title |
| description | text | Full description |
| budget_min | int | Minimum budget (USD) |
| budget_max | int | Maximum budget (USD) |
| skills | text[] | Required skills |
| duration | text | Project timeline |
| status | text | `open` or `closed` |
| created_at | timestamptz | Posted time |

### `proposals`
| Column | Type | Description |
|---|---|---|
| id | uuid | Primary key |
| project_id | uuid | References projects |
| freelancer_id | uuid | References auth.users |
| cover_letter | text | Proposal message |
| bid_amount | numeric | Proposed price (USD) |
| status | text | `pending`, `accepted`, `rejected` |
| created_at | timestamptz | Submitted time |

---

## 📁 Project Structure
lib/
├── core/
│ ├── presentation/
│ │ └── main_shell_page.dart # Bottom nav shell
│ ├── router/
│ │ └── router.dart # GoRouter config
│ └── theme/
│ ├── app_colors.dart
│ └── app_theme.dart
├── features/
│ ├── auth/
│ │ └── presentation/
│ │ ├── auth_provider.dart
│ │ ├── login_page.dart
│ │ └── register_page.dart
│ ├── onboarding/
│ │ └── presentation/
│ │ └── role_selection_page.dart
│ ├── profiles/
│ │ └── presentation/
│ │ ├── profile_provider.dart
│ │ └── edit_profile_page.dart
│ └── projects/
│ └── presentation/
│ ├── browse_projects_page.dart
│ ├── browse_projects_provider.dart
│ ├── client_home_page.dart
│ ├── freelancer_home_page.dart
│ ├── post_project_page.dart
│ ├── project_detail_page.dart
│ ├── project_detail_provider.dart
│ └── submit_proposal_page.dart
└── main.dart

---

## 🚀 Getting Started

### Prerequisites
- Flutter 3.x SDK
- Dart 3.x
- A Supabase project

### Setup

1. **Clone the repo**
   ```bash
   git clone https://github.com/your-username/lancr_app.git
   cd lancr_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Supabase**

   Copy the example config and fill in your keys:
   ```bash
   cp lib/core/config/env.example.dart lib/core/config/env.dart
   ```
   Then edit `env.dart` with your actual Supabase URL and anon key.

4. **Run the app**
   ```bash
   flutter run
   ```

---

## 🔐 Security

- Row Level Security (RLS) enabled on all tables
- Freelancers can only view and submit their own proposals
- Clients can only view proposals on their own projects
- Profile data is protected per user via `auth.uid()`

---

## 👨‍💻 Developer

**Harshal Koshti**
- 4th Year Computer Engineering (Software Engineering) Student
- 📍 Surat, Gujarat, India
- 🔗 [LinkedIn](https://linkedin.com/in/harshalkoshti01)
- 🐙 [GitHub](https://github.com/KoshtiHarshal)

---

## 📌 Project Status

> 🚧 Actively in development — new features added regularly.

This project is being built as a placement portfolio piece to demonstrate full-stack mobile development skills using Flutter + Supabase.

---

## 📄 License

Copyright © 2026 Harshal Koshti. All rights reserved.

This project is currently closed source. The code is shared publicly  
for portfolio and demonstration purposes only. Copying, distributing,  
or building upon this project without explicit written permission  
from the author is not permitted.