import os
import json
import openai
import PyPDF2
from zoneinfo import ZoneInfo

from flask import Flask, request, redirect, flash, url_for, render_template_string, session, abort
from functools import wraps

import google.auth.transport.requests
from google.oauth2 import id_token, credentials
from google_auth_oauthlib.flow import Flow
from googleapiclient.discovery import build
import requests
from pip._vendor import cachecontrol
from datetime import datetime, timedelta

# ========= CONFIGURATION =========
app = Flask(__name__)
app.secret_key = os.urandom(24)


os.environ["OAUTHLIB_INSECURE_TRANSPORT"] = "1"

client_secrets = {
    "web": {
        "client_id": os.environ["GOOGLE_CLIENT_ID"],
        "project_id": os.environ.get("GOOGLE_PROJECT_ID", ""),
        "auth_uri": os.environ.get("GOOGLE_AUTH_URI", "https://accounts.google.com/o/oauth2/auth"),
        "token_uri": os.environ.get("GOOGLE_TOKEN_URI", "https://oauth2.googleapis.com/token"),
        "auth_provider_x509_cert_url": os.environ.get("GOOGLE_AUTH_PROVIDER", "https://accounts.google.com"),
        "client_secret": os.environ["GOOGLE_CLIENT_SECRET"],
        "redirect_uris": [os.environ["GOOGLE_REDIRECT_URIS"]]
    }
}


openai.api_key = os.environ["OPENAI_API"]


flow = Flow.from_client_config(
    client_secrets,
    scopes=[
        "https://www.googleapis.com/auth/userinfo.profile",
        "https://www.googleapis.com/auth/userinfo.email",
        "openid",
        "https://www.googleapis.com/auth/calendar.events"
    ],
    redirect_uri=client_secrets["web"]["redirect_uris"][0]
)

# ========= DECORATOR =========
def login_is_required(func):
    """Require a valid Google login session to access certain routes."""
    @wraps(func)
    def wrapper(*args, **kwargs):
        if "google_id" not in session:
            return abort(401)  # Not logged in
        return func(*args, **kwargs)
    return wrapper

# ========= HTML TEMPLATES =========
INDEX_HTML = """
<!doctype html>
<html lang="en">
  <head>
    <title>Login | PDF to Google Calendar</title>
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <link 
      href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" 
      rel="stylesheet"
    >
    <style>
      body {
        background-color: #f0f2f5;
        display: flex;
        justify-content: center;
        align-items: center;
        height: 100vh;
      }
      .card {
        width: 100%;
        max-width: 500px;
        padding: 2rem;
        border-radius: 0.75rem;
        box-shadow: 0 10px 30px rgba(0, 0, 0, 0.1);
      }
    </style>
  </head>
  <body>
    <div class="card text-center">
      <h2 class="mb-3">Welcome to ScheduleSync!</h2>
      <p class="text-muted mb-3">
        Tired of manually adding class schedules to your calendar?
        This tool reads your class PDF, understands it with GPT-4, and automatically adds your lectures, discussions, and exams to your Google Calendar.
      </p>
      <p class="text-muted">
        Just upload your UCSD schedule PDF and let the magic happen ✨
      </p>
      <a href="/login" class="btn btn-outline-dark btn-lg w-100 mt-4 d-flex align-items-center justify-content-center">
        <img src="https://developers.google.com/identity/images/g-logo.png" alt="Google logo" style="width:20px; height:20px; margin-right:10px;">
        <span>Sign in with Google</span>
      </a>
    </div>
  </body>
</html>
"""


UPLOAD_HTML = """
<!doctype html>
<html lang="en">
  <head>
    <title>Upload PDF</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
  </head>
  <body class="bg-light">
    <div class="container py-5">
      <div class="card shadow-sm p-4">
        <h2 class="mb-4">Upload Your Class Schedule PDF</h2>

        {% with messages = get_flashed_messages() %}
          {% if messages %}
            <div class="alert alert-warning">
              {% for message in messages %}
                <div>{{ message }}</div>
              {% endfor %}
            </div>
          {% endif %}
        {% endwith %}

        <form method="POST" enctype="multipart/form-data" onsubmit="showLoading()">
          <div class="mb-3">
            <label for="file" class="form-label">Choose PDF File</label>
            <input type="file" id="file" name="file" accept="application/pdf" required class="form-control">
          </div>

          <!-- NEW date pickers -->
          <div class="mb-3">
            <label for="start_date" class="form-label">Quarter Start Date</label>
            <input type="date" id="start_date" name="start_date" required class="form-control">
          </div>
          <div class="mb-3">
            <label for="end_date" class="form-label">Quarter End Date</label>
            <input type="date" id="end_date" name="end_date" required class="form-control">
          </div>
          <!-- END new date pickers -->

          <button type="submit" id="uploadBtn" class="btn btn-primary">Upload</button>
          <a href="/logout" class="btn btn-secondary ms-2">Logout</a>
        </form>

        <script>
          function showLoading() {
            const btn = document.getElementById("uploadBtn");
            btn.disabled = true;
            btn.innerHTML = '<span class="spinner-border spinner-border-sm me-2" role="status" aria-hidden="true"></span>Beep-beep bop, boooop! Bweee-oooh…';
          }
        </script>
      </div>
    </div>
  </body>
</html>
"""
PREVIEW_HTML = """
<!doctype html>
<html lang="en">
  <head>
    <title>Schedule Preview</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
      pre {
        background-color: #f8f9fa;
        padding: 1rem;
        border: 1px solid #dee2e6;
        border-radius: 0.5rem;
      }
    </style>
  </head>
  <body class="bg-light">
    <div class="container py-5">
      <div class="card shadow-sm p-4 mb-4">
        <h2 class="mb-3">Extracted PDF Text</h2>
        <pre>{{ pdf_text }}</pre>
      </div>

      <div class="card shadow-sm p-4 mb-4">
        <h2 class="mb-3">Please Preview The Results Below, If they are'nt accurate logout and try again</h2>
        <pre>{{ schedule_text }}</pre>
      </div>

      <div class="text-center mb-4">
        <h2 class="mb-3">Import to Google Calendar</h2>
        <p class="mb-3">Click below to add events directly to your calendar.</p>
        <button id="importBtn" class="btn btn-success btn-lg">Import to Google Calendar</button>
      </div>

      <div class="text-center">
        <a href="/logout" class="btn btn-secondary">Logout</a>
      </div>
    </div>

    <script>
      const scheduleData = {{ schedule_json|tojson }};
      const importBtn = document.getElementById("importBtn");

      importBtn.addEventListener("click", function () {
        importBtn.disabled = true;
        importBtn.textContent = "Importing...";

        fetch("/import-to-calendar", {
          method: "POST",
          headers: {
            "Content-Type": "application/json"
          },
          body: JSON.stringify(scheduleData)
        })
        .then(response => {
          if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
          }
          return response.json();
        })
        .then(data => {
          alert("Successfully imported: " + (data.created || []).join(", "));
        })
        .catch(error => {
          console.error("Error:", error);
          alert("Error importing: " + error.message);
        })
        .finally(() => {
          importBtn.disabled = false;
          importBtn.textContent = "Import to Google Calendar";
        });
      });
    </script>
  </body>
</html>
"""

# ========= ROUTES =========
@app.route("/")
def index():
    return render_template_string(INDEX_HTML)

@app.route("/login")
def login():
    authorization_url, state = flow.authorization_url()
    session["state"] = state
    return redirect(authorization_url)

@app.route("/callback")
def callback():

    flow.fetch_token(authorization_response=request.url)

    if session.get("state") != request.args.get("state"):
        return abort(500)  

    creds = flow.credentials
    request_session = requests.session()
    cached_session = cachecontrol.CacheControl(request_session)
    token_request = google.auth.transport.requests.Request(session=cached_session)

    id_info = id_token.verify_oauth2_token(
        creds._id_token, token_request, os.environ["GOOGLE_CLIENT_ID"]
    )

    # Store relevant data in session
    session["google_id"] = id_info.get("sub")
    session["name"] = id_info.get("name")
    session["credentials"] = {
        "token": creds.token,
        "refresh_token": creds.refresh_token,
        "token_uri": creds.token_uri,
        "client_id": creds.client_id,
        "client_secret": creds.client_secret,
        "scopes": creds.scopes
    }

    return redirect("/upload")

@app.route("/logout")
def logout():
    session.clear()
    return redirect("/")

@app.route("/upload", methods=["GET", "POST"])
@login_is_required
def upload():
    if request.method == "POST":
        # 1) Check file
        file = request.files.get("file")
        if not file or file.filename == "":
            flash("No file selected.")
            return redirect(request.url)

        # 2) Capture the start/end dates
        #    (Make sure to handle any missing form fields gracefully)
        start_date_str = request.form.get("start_date")
        end_date_str = request.form.get("end_date")

        if not start_date_str or not end_date_str:
            flash("Please select both a start date and an end date.")
            return redirect(request.url)

        # Store them in session
        session["quarter_start"] = start_date_str
        session["quarter_end"] = end_date_str

        # 3) Extract text from PDF
        try:
            pdf_reader = PyPDF2.PdfReader(file)
            pdf_text = "\n".join(page.extract_text() or "" for page in pdf_reader.pages)
        except Exception as e:
            flash(f"Error reading PDF: {e}")
            return redirect(request.url)

        if not pdf_text.strip():
            flash("PDF has no readable text.")
            return redirect(request.url)

        # 4) Prompt GPT to parse schedule
        prompt = f"""
You are an assistant that converts a PDF class schedule into an organized JSON format:
- weeklyEvents: a list of events that repeat each week
- exams: any tests or finals
Use the format:
{{
  "weeklyEvents": [
    {{
      "title": "...",
      "instructor": "...",
      "location": "...",
      "days": ["Monday","Wednesday"],
      "startTime": "7:00a",
      "endTime": "7:50a"
    }}
  ],
  "exams": [
    {{
      "title": "...",
      "type": "Midterm",
      "date": "04/24/2025",
      "startTime": "8:00p",
      "endTime": "9:50p",
      "location": "..."
    }}
  ]
}}

Raw PDF text:
{pdf_text}
"""
        try:
            response = openai.ChatCompletion.create(
                model="gpt-4",
                messages=[{"role": "user", "content": prompt}],
                temperature=0
            )
            schedule_text = response.choices[0].message.content.strip()
        except Exception as e:
            flash(f"OpenAI API error: {e}")
            return redirect(request.url)

        # 5) Validate the JSON
        try:
            schedule_json = json.loads(schedule_text)
        except json.JSONDecodeError:
            flash("GPT response is not valid JSON.")
            schedule_json = {}

        # 6) Render preview page
        return render_template_string(
            PREVIEW_HTML,
            pdf_text=pdf_text,
            schedule_text=schedule_text,
            schedule_json=schedule_json
        )

    return render_template_string(UPLOAD_HTML)


@app.route("/import-to-calendar", methods=["POST"])
@login_is_required
def import_to_calendar():
    """Take the schedule JSON and create events in the user's Google Calendar."""
    schedule_data = request.json or {}
    creds_data = session.get("credentials")

    if not creds_data:
        return {"status": "error", "message": "No credentials in session"}

    # --- 1) Rebuild Google creds and service
    creds = credentials.Credentials(**creds_data)
    service = build("calendar", "v3", credentials=creds)

    # --- 2) Get the user-chosen quarter start/end from session
    start_date_str = session.get("quarter_start") 
    end_date_str   = session.get("quarter_end")  
    if not start_date_str or not end_date_str:
        start_date_str = "2025-03-31"
        end_date_str = "2025-06-13"

    quarter_start = datetime.strptime(start_date_str, "%Y-%m-%d").date()
    quarter_end   = datetime.strptime(end_date_str, "%Y-%m-%d").date()

    la_tz = ZoneInfo("America/Los_Angeles")

    end_dt_local = datetime.combine(quarter_end, datetime.max.time()).replace(tzinfo=la_tz)
    end_dt_utc   = end_dt_local.astimezone(ZoneInfo("UTC"))
    until_str    = end_dt_utc.strftime("%Y%m%dT%H%M%SZ")  # e.g. 20250613T235959Z

    events_created = []

    # Helper function: create and insert an event
    def create_event(title, location, start_dt, end_dt, is_weekly=False):
        print(f"Creating: {title} from {start_dt} to {end_dt}")
        event_body = {
            "summary": title,
            "location": location,
            "start": {
                "dateTime": start_dt.isoformat(),
                "timeZone": "America/Los_Angeles"
            },
            "end": {
                "dateTime": end_dt.isoformat(),
                "timeZone": "America/Los_Angeles"
            },
        }
        if is_weekly:
            event_body["recurrence"] = [f"RRULE:FREQ=WEEKLY;UNTIL={until_str}"]

        created_event = service.events().insert(
            calendarId="primary", body=event_body
        ).execute()
        events_created.append(created_event.get("summary", "Untitled Event"))

    # Helper: parse 12-hour times like "7:00p" to a time object
    def parse_12h_time(tstr):
        tstr = tstr.strip().lower().replace(" ", "")
        if tstr.endswith("a") or tstr.endswith("p"):
            tstr = tstr[:-1] + ("am" if tstr.endswith("a") else "pm")
        return datetime.strptime(tstr, "%I:%M%p").time()

    # Day-of-week map for weekly events
    days_map = {
        "Monday": 0, "Tuesday": 1, "Wednesday": 2,
        "Thursday": 3, "Friday": 4, "Saturday": 5, "Sunday": 6
    }

    # --- 4) Process Weekly Events
    for ev in schedule_data.get("weeklyEvents", []):
        title = ev.get("title", "Untitled")
        location = ev.get("location", "")
        days = ev.get("days", [])
        try:
            start_time = parse_12h_time(ev["startTime"])
            end_time = parse_12h_time(ev["endTime"])
        except Exception as e:
            print(f"Error parsing time: {e}")
            continue

        # For each day in the event, figure out which date in the first week
        # For example, if quarter_start is a Monday and the schedule says "Monday",
        # then offset is 0. For "Wednesday", offset is 2 days, etc.
        start_dow = quarter_start.weekday()  
        for day in days:
            if day not in days_map:
                continue

            offset = (days_map[day] - start_dow) % 7
            event_date = quarter_start + timedelta(days=offset)

            # Combine date with time in LA
            start_dt = datetime.combine(event_date, start_time).replace(tzinfo=la_tz)
            end_dt   = datetime.combine(event_date, end_time).replace(tzinfo=la_tz)

            # Create the weekly recurring event (until user-chosen end)
            create_event(title, location, start_dt, end_dt, is_weekly=True)

    # --- 5) Process Exams
    # Exams typically do not recur, so we just create single events
    for exam in schedule_data.get("exams", []):
        title = f"{exam.get('title', 'Exam')} - {exam.get('type', 'Exam')}"
        location = exam.get("location", "")
        try:
            exam_date = datetime.strptime(exam["date"], "%m/%d/%Y").date()
            start_time = parse_12h_time(exam["startTime"])
            end_time = parse_12h_time(exam["endTime"])
            start_dt = datetime.combine(exam_date, start_time).replace(tzinfo=la_tz)
            end_dt   = datetime.combine(exam_date, end_time).replace(tzinfo=la_tz)
            create_event(title, location, start_dt, end_dt, is_weekly=False)
        except Exception as e:
            print(f"Error processing exam: {e}")
            continue

    return {"status": "success", "created": events_created}

# ========= MAIN =========
if __name__ == "__main__":
    app.run(debug=True)