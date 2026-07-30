# 🏋️ Gym Tracker

A full-stack workout tracking app — log your sets, follow a 6-day training split,
watch your progress, and hit new personal bests. Built with **Flutter** and a
**FastAPI + PostgreSQL** backend.

> Replace the screenshots below with your own (drop the PNGs in a `/screenshots`
> folder). A row of 3–4 screenshots here is the single biggest thing a recruiter
> looks at — put your best screens first (dashboard, analytics, exercise demo).

<p align="center">
  <img src="screenshots/dashboard.png" width="200"/>
  <img src="screenshots/analytics.png" width="200"/>
  <img src="screenshots/exercise_demo.png" width="200"/>
</p>

---

## ✨ Features

- **6-day training split** — a full weekly plan (Legs & Abs, Back & Biceps,
  Chest & Shoulders, and more) with every exercise organised by muscle group.
- **Set logging** with decimal weights, auto set-numbering, and a rest timer
  that keeps accurate time even when the screen locks.
- **Animated home dashboard** — current streak, total volume, sets logged, and
  achievement badges that unlock as you train.
- **Progress analytics** — volume-over-time chart plus a per-split-day breakdown,
  built by joining sets to their training sessions.
- **Personal-best detection** — beat your heaviest weight on a lift and the app
  celebrates it with confetti.
- **Animated exercise demos** — a searchable, muscle-filtered library of exercises,
  each with looping start→end form frames and written instructions
  (data from the public-domain [Free Exercise DB](https://github.com/yuhonas/free-exercise-db)).
- **Rest-timer alarm** — sound + vibration when your rest period ends.

---

## 🛠️ Tech Stack

| Layer      | Technology                                   |
|------------|----------------------------------------------|
| Frontend   | Flutter (Dart), fl_chart, confetti           |
| Backend    | FastAPI (Python), SQLAlchemy                  |
| Database   | PostgreSQL (Neon)                             |
| Hosting    | Render (backend), Neon (database)            |

---

## 📁 Project Structure

```
gym-tracker/
├── app/        # Flutter mobile app
└── backend/    # FastAPI REST API
```

---

## 🚀 Running It Locally

### Backend
```bash
cd backend
pip install -r requirements.txt
# Point DATABASE_URL at your own Postgres (Neon, Supabase, or local):
export DATABASE_URL="postgresql://user:password@host/dbname"
uvicorn app.main:app --reload
```
The API runs at `http://localhost:8000` — interactive docs at `http://localhost:8000/docs`.

### App
```bash
cd app
flutter pub get
flutter run
```
> Set the API base URL in `app/lib/services/api_service.dart` to your backend
> (local or deployed).

---

## 🧠 What I Learned

> This section is your interview gold — write 3–4 honest bullets in your own words.
> Recruiters love it. Some real ones from building this:
- Diagnosing a production outage from Render logs (an expired free database) and
  migrating to a persistent Postgres provider.
- Designing a rest timer around wall-clock time instead of a ticking counter, so
  it stays correct after the phone sleeps.
- Handling cold-start latency on free hosting with request retries + a warm-up ping.
- Evolving the database schema safely (integer → float weights) with live migrations.

---

## 📝 License

MIT — feel free to learn from it.
