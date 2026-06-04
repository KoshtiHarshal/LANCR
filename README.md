# Lancr — Freelance Marketplace App

A full-stack mobile application connecting freelancers with clients. Built with Flutter and Supabase as a portfolio project.

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)
![Supabase](https://img.shields.io/badge/Supabase-PostgreSQL-3ECF8E?logo=supabase)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)
![Status](https://img.shields.io/badge/Status-In%20Progress-F59E0B)

---

## 📱 About

**Lancr** is a freelance marketplace mobile app where clients can post projects and hire talent, and freelancers can browse projects and submit proposals — similar to Upwork or Fiverr, built from scratch as a placement portfolio project.

---

## ✨ Features

### ✅ Completed
- **Authentication** — Email/password login and registration via Supabase Auth
- **Role Selection** — Users choose Freelancer or Client on first login
- **Edit Profile** — Name, headline, bio, skills, location, experience, portfolio & LinkedIn URLs
- **Public Profile Page** — Freelancer profile visible to clients with stats (proposals, active, completed)
- **Client Home** — Dashboard with posted projects overview
- **Post a Project** — Clients post projects with title, description, budget, and required skills
- **Browse Projects** — Freelancers browse open projects with search and skill-based filtering
- **Project Detail** — Full project view with client info, budget, and required skills
- **Submit Proposal** — Freelancers submit a cover letter and bid amount
- **My Proposals Tab** — Freelancers track all submitted proposals with stats strip (Total / Pending / Accepted / Rejected)
- **View Proposals** — Clients view all proposals on their project and Accept/Reject
- **My Projects Tab** — Clients manage all their posted projects
- **Real-time Messaging** — In-app chat between client and freelancer after proposal is accepted
   - Conversation auto-created on proposal acceptance
   - Real-time message delivery via Supabase Realtime
   - Messages tab available for both Client and Freelancer

### 📋 Planned
- **Project Completion Flow** — Client marks project as done; updates freelancer stats
- **Reviews & Ratings** — Post-project feedback system shown on public profile
- **Notifications** — Real-time alerts for proposal accepted/rejected and new messages
- **Advanced Search & Filters** — Filter projects by budget range, skills, location

---

## 🛠 Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter 3.x (Dart) |
| State Management | Riverpod 3.x |
| Navigation | GoRouter |
| Backend / Database | Supabase (PostgreSQL) |
| Authentication | Supabase Auth |
| Realtime | Supabase Realtime (WebSockets) |
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
| budget_min | numeric | Minimum budget (USD) |
| budget_max | numeric | Maximum budget (USD) |
| required_skills | text[] | Required skills |
| status | text | `open`, `closed`, `completed` |
| created_at | timestamptz | Posted time |

### `proposals`
| Column | Type | Description |
|---|---|---|
| id | uuid | Primary key |
| project_id | uuid | References projects |
| freelancer_id | uuid | References profiles |
| cover_letter | text | Proposal message |
| bid_amount | numeric | Proposed price (USD) |
| status | text | `pending`, `accepted`, `rejected`, `completed` |
| created_at | timestamptz | Submitted time |

### `conversations`
| Column | Type | Description |
|---|---|---|
| id | uuid | Primary key |
| project_id | uuid | References projects |
| client_id | uuid | References profiles |
| freelancer_id | uuid | References profiles |
| last_message | text | Preview of latest message |
| last_message_at | timestamptz | Time of latest message |
| created_at | timestamptz | Conversation start time |

### `messages`
| Column | Type | Description |
|---|---|---|
| id | uuid | Primary key |
| conversation_id | uuid | References conversations |
| sender_id | uuid | References profiles |
| content | text | Message text |
| created_at | timestamptz | Sent time |

---

## 📁 Project Structure
lib/  
│   
├── core/   
│ ├── config/    
│ │ ├── env.dart   
│ │ └── router.dart # GoRouter config   
│ ├── models/   
│ │ └── user.dart   
│ ├── presentation/  
│ │ └── main_shell_page.dart # Bottom nav shell (Client: 4 tabs, Freelancer: 5 tabs)   
│ └── theme/  
│   ├── app_colors.dart  
│   └── app_theme.dart  
│   
├── features/    
│ ├── auth/  
│ │ └── presentation/  
│ │   ├── auth_provider.dart  
│ │   ├── login_page.dart  
│ │   └── register_page.dart    
│ ├── onboarding/   
│ │ └── presentation/   
│ │    └── role_selection_page.dart   
│ ├── profiles/   
│ │ └── presentation/     
│ │   ├── profile_provider.dart   
│ │   ├── profile_page.dart   
│ │   ├── public_profile_page.dart   
│ │   └── edit_profile_page.dart    
│ ├── projects/   
│ │ └── presentation/   
│ │   ├── client_home_page.dart   
│ │   ├── client_projects_page.dart   
│ │   ├── freelancer_home_page.dart   
│ │   ├── freelancer_home_provider.dart  
│ │   ├── browse_projects_page.dart   
│ │   ├── browse_projects_provider.dart    
│ │   ├── post_project_page.dart  
│ │   ├── project_detail_page.dart   
│ │   ├── project_completion_page.dart  
│ │   ├── project_completion_provider.dart  
│ │   ├── proposals_provider.dart   
│ │   └── project_detail_provider.dart   
│ ├── proposals/    
│ │ └── presentation/  
│ │ │ ├── view_proposals_page.dart  
│ │ │ ├── submit_proposal_page.dart      
│ │ │ ├── my_proposals_page.dart  
│ │ │ └── my_proposals_provider.dart  
│ │ └── data/   
│ │     └── proposals_repository.dart     
│ └── messages/   
│   └── presentation/   
│     ├── conversations_page.dart    
│     ├── chat_page.dart  
│     ├── conversations_provider.dart   
│     └── messages_provider.dart   
│   
└── main.dart   


---

## 🧭 Navigation Routes

| Route | Page | Access |
|---|---|---|
| `/` | SplashPage | All |
| `/auth/login` | LoginPage | Public |
| `/auth/register` | RegisterPage | Public |
| `/onboarding/role` | RoleSelectionPage | New users |
| `/home` | MainShellPage | Authenticated |
| `/projects/post` | PostProjectPage | Client |
| `/projects/browse` | BrowseProjectsPage | Freelancer |
| `/client/projects` | ClientProjectsPage | Client |
| `/projects/:id` | ProjectDetailPage | All |
| `/projects/:id/submit-proposal` | SubmitProposalPage | Freelancer |
| `/projects/:id/proposals` | ViewProposalsPage | Client |
| `/profile/edit` | EditProfilePage | All |
| `/profile/:id` | PublicProfilePage | All |
| `/messages/:id` | ChatPage | All |

---

## 🚀 Getting Started

### Prerequisites
- Flutter 3.x SDK
- Dart 3.x
- A Supabase project

### Setup

1. **Clone the repo**
   ```bash
   git clone https://github.com/KoshtiHarshal/lancr_app.git
   cd lancr_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Supabase**

   Update `lib/main.dart` with your Supabase URL and anon key:
   ```dart
   await Supabase.initialize(
     url: 'YOUR_SUPABASE_URL',
     anonKey: 'YOUR_SUPABASE_ANON_KEY',
   );
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

---

## 🔐 Security

- Row Level Security (RLS) enabled on all tables
- Freelancers can only view and submit their own proposals
- Clients can only view proposals on their own projects
- Conversations and messages restricted to participant users only
- Profile data protected per user via `auth.uid()`

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