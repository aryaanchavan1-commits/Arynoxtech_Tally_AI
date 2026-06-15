# Arynoxtech Tally AI

AI-Powered Smart Accounting Software for Indian Small Businesses.

A free, open-source desktop accounting application with an integrated AI agent that can understand natural language requests, process uploaded files, and perform accounting tasks autonomously (with user confirmation).

---

## Features

### Core Accounting
- Chart of Accounts (assets, liabilities, equity, revenue, expenses)
- Voucher entries (Payment, Receipt, Sales, Purchase, Contra, Journal)
- Customers & Suppliers management with GSTIN support
- Invoicing with GST (CGST/SGST/IGST) support
- Inventory management with stock tracking
- Expense tracking with categories

### Reports & Dashboard
- Trial Balance, Profit & Loss, Balance Sheet
- Day Book, General Ledger
- Dashboard with revenue chart, top customers, top products
- Export reports to PDF

### AI Agent
- **Agent Mode** - Switch to agent mode and tell the AI what to do
- **File Upload** - Upload TXT, CSV, PDF, Excel files for the AI to read
- **Action Proposals** - AI proposes actions (create customer, add product, etc.) with Confirm/Deny
- **Auto-Execute** - Confirmed actions execute immediately against your database
- Voice input & text-to-speech support
- Multiple AI providers: Groq, OpenAI, Gemini, OpenRouter (including free models)

### Enterprise Features
- Point of Sale (POS) with barcode support
- Bank Reconciliation
- TDS/TCS management
- Budget & Cost Center tracking
- Batch & BOM (manufacturing)
- Audit Logs
- GST Return data preparation
- Cheque printing

---

## Screenshots

*(Add screenshots here)*

---

## Download & Install

### Option 1: Download Pre-built Release (Recommended)

1. Go to the [Releases page](https://github.com/aryaanchavan1-commits/Arynoxtech_Tally_AI/releases)
2. Download the latest `Arynoxtech_Tally_AI_vX.X.X.zip`
3. Extract the ZIP file
4. Double-click **Start_Arynoxtech.bat**
5. Wait 5-10 seconds for the app to launch

**No installation required.** The app runs portably from the folder.

### Option 2: Build from Source

#### Prerequisites

| Tool | Version | Download |
|------|---------|----------|
| Python | 3.13+ | [python.org](https://python.org) |
| Flutter | 3.44+ | [flutter.dev](https://flutter.dev) |
| Git | Any | [git-scm.com](https://git-scm.com) |

#### Step 1: Clone the Repository

```bash
git clone https://github.com/aryaanchavan1-commits/Arynoxtech_Tally_AI.git
cd Arynoxtech_Tally_AI
```

#### Step 2: Setup Backend

```bash
cd backend
python -m venv venv
.\venv\Scripts\activate    # Windows
# source venv/bin/activate  # Linux/Mac
pip install -r requirements.txt
```

To run the backend for development:
```bash
python run.py
# Server starts at http://localhost:8000
```

#### Step 3: Setup Frontend

```bash
cd ../flutter_app
flutter pub get
```

To run in development mode:
```bash
flutter run -d windows
```

#### Step 4: Build Executables

**Build Backend .exe (PyInstaller):**
```bash
cd backend
.\venv\Scripts\python -m PyInstaller Arynoxtech_Backend.spec
# Output: backend/dist/Arynoxtech_Backend.exe
```

**Build Flutter Windows .exe:**
```bash
cd flutter_app
flutter build windows --release
# Output: flutter_app/build/windows/x64/runner/Release/arynoxtech_tally.exe
```

**Build APK (Android):**
```bash
cd flutter_app
flutter build apk --release
# Output: flutter_app/build/app/outputs/flutter-apk/app-release.apk
```

> **Note:** APK build requires Android SDK. Set `ANDROID_HOME` environment variable to your SDK path.

---

## How to Use the AI Agent

1. Launch the app and go to **AI Assistant** from the sidebar
2. Tap the **robot icon** in the top bar to switch to **Agent Mode**
3. (Optional) Tap the **📎 attach button** to upload files (CSV with customer list, PDF invoice, etc.)
4. Type what you want, e.g.:
   - *"Create customers from this CSV file"*
   - *"Add a new product called Steel Chair with price ₹2500"*
   - *"Create a sales voucher for ₹15000"*
5. Review the AI's proposed action and tap **Confirm** or **Deny**
6. The action is executed and you'll see the result

### AI Configuration

Before using AI features, configure a provider in **Settings → AI Settings**:
- **Groq** - Free tier available (llama-3.3-70b, deepseek-r1)
- **OpenRouter** - Free models available (deepseek-v4-flash-free, gemini-2.0-flash-free)
- **OpenAI** - Requires paid API key
- **Gemini** - Free tier available

---

## Project Structure

```
Arynoxtech_Tally_AI/
├── backend/                    # Python FastAPI backend
│   ├── app/
│   │   ├── main.py            # FastAPI app entry point
│   │   ├── config.py          # App configuration
│   │   ├── database.py        # SQLAlchemy database setup
│   │   ├── models/            # SQLAlchemy ORM models
│   │   ├── routes/            # API route handlers
│   │   │   ├── auth.py
│   │   │   ├── accounts.py
│   │   │   ├── vouchers.py
│   │   │   ├── customers.py
│   │   │   ├── suppliers.py
│   │   │   ├── inventory.py
│   │   │   ├── invoices.py
│   │   │   ├── expenses.py
│   │   │   ├── reports.py
│   │   │   ├── dashboard.py
│   │   │   ├── backup.py
│   │   │   ├── search.py
│   │   │   ├── enterprise.py
│   │   │   └── ai_assistant.py  # AI chat + agent endpoints
│   │   ├── schemas/           # Pydantic request/response schemas
│   │   ├── services/
│   │   │   └── agent_service.py  # AI agent logic
│   │   └── utils/
│   ├── data/                  # SQLite database files
│   ├── run.py                 # Development server launcher
│   └── requirements.txt
│
├── flutter_app/               # Flutter frontend
│   ├── lib/
│   │   ├── main.dart
│   │   ├── core/
│   │   │   ├── constants/     # API endpoints, app constants
│   │   │   ├── network/       # HTTP client
│   │   │   ├── theme/         # App theme
│   │   │   └── routes/        # Navigation routes
│   │   ├── presentation/
│   │   │   ├── providers/     # State management (ChangeNotifier)
│   │   │   ├── screens/       # All UI screens
│   │   │   └── widgets/       # Shared widgets
│   │   └── models/            # Data models
│   └── pubspec.yaml
│
├── client_dist/               # Pre-built distribution (gitignored)
├── .gitignore
└── README.md
```

---

## API Endpoints

The backend provides a REST API at `http://localhost:8000`. Key endpoints:

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/login` | User login |
| POST | `/api/auth/register` | User registration |
| GET/POST | `/api/accounts` | List/Create accounts |
| GET/POST | `/api/customers` | List/Create customers |
| GET/POST | `/api/vouchers` | List/Create vouchers |
| GET/POST | `/api/invoices` | List/Create invoices |
| GET | `/api/reports/*` | Various reports |
| POST | `/api/ai/chat` | AI chat |
| POST | `/api/ai/agent` | AI agent (with actions) |
| POST | `/api/ai/upload` | Upload files for agent |
| POST | `/api/ai/agent/execute` | Execute confirmed action |
| GET | `/api/health` | Health check |

Full API documentation available at `http://localhost:8000/docs` (Swagger UI) when the backend is running.

---

## Technology Stack

- **Frontend:** Flutter 3.44+ (Dart 3.12+)
- **Backend:** Python 3.13+, FastAPI, SQLAlchemy, SQLite
- **AI Integration:** Groq, OpenAI, Gemini, OpenRouter APIs
- **Desktop:** Windows (native), Android (APK), Linux/macOS (experimental)
- **Packaging:** PyInstaller (backend), Flutter build (frontend)

---

## License

This project is open source under the MIT License.

---

## Disclaimer

This software is provided as-is. The AI agent's actions are proposals that require user confirmation before execution. The authors are not responsible for any financial data loss or incorrect accounting entries. Always verify AI-generated actions before confirming. For GST compliance, consult a qualified chartered accountant.
