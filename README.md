# 📱 UCSD App

A Flutter-based mobile application designed to centralize essential tools and resources for **UC San Diego students** — including navigation, calendar access, campus info, and an AI assistant.

---

## 🚀 Features

### 🔐 Authentication (Supabase)

- Email & password login / signup
- Google Sign-In integration
- Persistent session handling
- Secure authentication using Supabase Auth

---

### 🏠 Home Dashboard

- Quick access to:
  - Health & wellness resources (CAPS, Student Health, etc.)
  - Weather widget
  - UCSD news feed
  - Campus events
- Clean modular block layout

---

### 🗺️ Maps & Navigation

- Real-time user location tracking
- Place search with autocomplete
- Custom markers for current location & destination
- Open directions directly in Google Maps
- Uses Google Maps + Places API

---

### 📅 Calendar Integration

- Embedded Google Calendar inside the app
- Loading + error handling UI
- External Flask scheduling app support
- Option to open schedule tool in browser

---

### 🤖 TritonAI Chatbot

- AI assistant tailored for UCSD students
- Answers questions about:
  - Academics
  - Campus resources
  - Events
  - Career prep
- Built using OpenAI API
- Maintains chat history for context

---

### 👤 Profile Page

- Displays:
  - User email
  - Account creation date
- Logout functionality
- “Report Issue” email integration

---

### 📱 Navigation System

- Bottom navigation bar with 5 main tabs:
  - Home
  - Maps
  - Calendar
  - TritonAI
  - Profile
- Auth-based routing (Login → Main App)

---

## 🛠️ Tech Stack

- **Flutter** (UI framework)
- **Supabase** (authentication)
- **Google Maps API**
- **Google Places API**
- **OpenAI API**
- **WebView (Google Calendar)**
- **Flask (external scheduling tool)**

---

## ⚙️ Setup Instructions

### 1. Clone the repo

git clone https://github.com/YOUR_USERNAME/YOUR_REPO.git
cd YOUR_REPO

### 2. Clone the repo

flutter pub get

### 3. Configure environment variables

GOOGLE_MAPS_KEY=your_google_maps_api_key
OPENAI_API_KEY=your_openai_api_key

### 4. Supabase Setup

In main.dart, replace with your project credentials:

await Supabase.initialize(
url: 'https://YOUR_PROJECT_ID.supabase.co',
anonKey: 'YOUR_PUBLISHABLE_KEY',
);

### 5. Run the app

flutter run
