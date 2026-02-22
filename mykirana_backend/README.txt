SnapBill Backend Documentation
Version: 1.0.0 Status: Production Ready Framework: FastAPI (Python) Database: PostgreSQL (Supabase) via SQLModel AI Engine: Google Gemini (Generative AI)

1. Project Overview
SnapBill is a backend system designed to power the "MyKirana" mobile application. It acts as the central brain that connects the mobile app to a secure cloud database and Google's Artificial Intelligence. Its primary functions are:

Secure Authentication: Managing User Login and Registration via Phone Number and OTP (One-Time Password).

Inventory Management: Allowing shop owners to save, edit, and retrieve their product lists from the cloud.

Voice-to-Bill AI: A specialized service that takes raw voice commands (e.g., "1 kg sugar") and converts them into structured billing data by cross-referencing the user's actual inventory prices.

2. Project Directory Tree
This structure represents the physical layout of your codebase.

mykirana_backend/
│
├── .env                       # Environment Variables (Secrets)
├── requirements.txt           # Python Dependency List
├── check_models.py            # Diagnostic Script for AI Models
│
└── app/                       # Main Application Source Code
    ├── __init__.py            # Package Initialization
    ├── main.py                # Server Entry Point (The "conductor")
    │
    ├── api/                   # API Routes (The "Front Desk")
    │   ├── __init__.py
    │   ├── auth.py            # Authentication Endpoints
    │   ├── items.py           # Inventory Endpoints
    │   └── voice.py           # AI Voice Processing Endpoints
    │
    ├── core/                  # Core Configuration
    │   ├── __init__.py
    │   └── security.py        # JWT Token & Security Logic
    │
    ├── db/                    # Database Layer (The "Memory")
    │   ├── __init__.py
    │   ├── database.py        # Database Connection Logic
    │   ├── models.py          # SQL Database Tables Definition
    │   └── schemas.py         # Data Validation Models (Pydantic)
    │
    └── services/              # Business Logic (The "Workers")
        ├── __init__.py
        ├── ai_service.py      # Google Gemini AI Integration
        ├── otp_service.py     # OTP Generation Logic
        └── sms_service.py     # SMS Delivery Logic

3. Root Configuration Files
3.1 .env (Environment Variables)
Purpose: Stores sensitive configuration settings that must be kept secret.

Key Variables:

DATABASE_URL: The address and password to connect to your Supabase PostgreSQL database.

SECRET_KEY: A random string used to sign and encrypt Digital ID Cards (JWT Tokens).

GEMINI_API_KEY: The access key provided by Google to use their AI models.

3.2 requirements.txt
Purpose: Lists every external library the project needs to run.

Usage: Used by the command pip install -r requirements.txt.

Key Libraries:

fastapi: The web framework.

uvicorn: The server that runs the Python code.

sqlmodel: Connects Python code to the SQL Database.

google-generativeai: Google's library for talking to Gemini.

python-jose: Handles security token creation.

3.3 check_models.py
Purpose: A diagnostic utility script.

Logic: It connects to Google using your API key and asks, "Which AI models am I allowed to use?" It prints a list of available models (e.g., gemini-2.0-flash-lite, gemini-1.5-flash).

Why it exists: To prevent "404 Model Not Found" errors by allowing us to verify our account permissions before running the main app.

4. Folder Breakdown: app/db (Database Layer)
Role: This folder manages long-term memory (Storage).

4.1 app/db/database.py
create_db_and_tables()

Logic: Connects to the database on startup and checks if our Tables (User, Item, OTP) exist. If not, it creates them automatically.

get_session()

Logic: Creates a temporary "session" (connection) for a single API request. It ensures the connection is closed immediately after the request is finished to prevent server crashes.

4.2 app/db/models.py
User Class

Role: Represents the user table in the database.

Fields: id (Primary Key), phone_number (Unique), shop_name, owner_name, address.

Item Class

Role: Represents the item table (Inventory).

Fields: id, name, price, unit, category, owner_id (Foreign Key linking it to a specific User).

OTP Class

Role: Represents the otp table.

Fields: phone_number, otp_code (The temporary 6-digit code), created_at.

4.3 app/db/schemas.py
Role: Data Validation. Ensures data coming IN from the App is correct before it touches the Database.

OTPRequest: Ensures incoming login requests contain a phone_number and the is_login flag.

VerifyOTPRequest: Ensures verification requests contain the otp_code.

ItemCreate: Ensures new items have a name and a valid price.

5. Folder: app/core (Security)
Role: The Guard. Handles permissions and access.

5.1 app/core/security.py
create_access_token(data: dict)

Logic: Takes the User's ID (e.g., User #5) and mixes it with the SECRET_KEY and a timestamp.

Output: A long string (JWT Token).

Purpose: This token acts as a "Digital ID Card." The App sends this token with every request so the server knows "User #5 is asking." The server can verify the signature without needing to check the password database every time.

6. Folder: app/services (Business Logic)
Role: The Workers. This is where the complex calculations happen.

6.1 app/services/otp_service.py
create_otp(session, phone_number)

Logic: Generates a random 6-digit number (e.g., "492810"). Deletes any old OTPs for this phone number to keep the table clean. Saves the new code to the OTP table.

verify_otp(session, phone_number, otp_code)

Logic: Looks up the phone number in the OTP table. If the stored code matches the otp_code provided by the user, it returns True. It then deletes the code so it cannot be used twice.

6.2 app/services/sms_service.py
send_otp(phone_number, otp)

Logic: Currently setup for "Dev Mode." Instead of sending a real SMS (which costs money), it prints the OTP to the Server Terminal. This allows for free testing during development.

6.3 app/services/ai_service.py (The AI Brain)
Initialization (__init__):

Sets up the connection to Google.

Defines a priority list of models (candidate_models): gemini-2.0-flash-lite, gemini-flash-latest, etc.

process_voice_command(user_text, inventory):

Step 1: Converts the User's SQL Inventory list into a JSON string.

Step 2 (Prompt Engineering): Constructs a strict instruction for the AI: "You are a billing AI. Here is the inventory. Here is what the user said. Match them. If the user didn't say a price, use the inventory price. Return JSON."

Step 3 (Auto-Discovery Loop): It attempts to send this prompt to the first model in the list. If that model fails (due to quota or availability), it catches the error and tries the next model automatically.

Step 4: Returns the cleaned JSON bill to the API.

7. Folder: app/api (The Endpoints)
Role: The Interface. These are the URLs the Mobile App actually calls.

7.1 app/api/auth.py
POST /send-otp

Logic: Receives a phone number.

The Check: If is_login=True, it checks if the user exists. If NOT, it raises a 404 Error ("Register First"). If is_login=False, it ensures the user does NOT exist.

Action: Calls otp_service to generate a code.

POST /verify-otp

Logic: Verifies the code.

Action: If this was a Registration (is_new_user), it creates a new row in the User table with the provided Shop Name and Address.

Output: Returns the secure Access Token.

7.2 app/api/items.py
get_current_user() (Helper)

Logic: Reads the "Bearer Token" from the request header. Decodes it to find the User ID. If the token is fake or expired, it blocks the request (401 Unauthorized).

POST /items/

Logic: Accepts item details. Saves them to the Item table, tagging them with the current user's ID (owner_id).

GET /items/

Logic: Fetches all items where owner_id matches the logged-in user. This ensures User A never sees User B's inventory.

7.3 app/api/voice.py
POST /voice/process

Logic:

Identifies the user (via Token).

Fetches that specific user's inventory from the database.

Passes both the Inventory and the User's Voice Text to ai_service.py.

Returns the structured Bill JSON to the App.

8. Server Entry Point
8.1 app/main.py
lifespan Context Manager:

Runs immediately when the server starts.

Calls create_db_and_tables() to ensure the database is ready.

Router Registration:

Tells the FastAPI app to "mount" the routes from auth, items, and voice so they are accessible from the outside world.

Starts the server on Port 8000.