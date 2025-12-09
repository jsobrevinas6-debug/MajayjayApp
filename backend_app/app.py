from flask import Flask, request, jsonify
from flask_cors import CORS
import jwt
import datetime
import psycopg2
from psycopg2.extras import RealDictCursor

app = Flask(__name__)
CORS(app, resources={r"/*": {"origins": "*"}})

app.config["SECRET_KEY"] = "supersecretkey123"

# Database connection
def get_db_connection():
    # Temporarily disabled - update password first
    # conn = psycopg2.connect(
    #     host="localhost",
    #     database="usersdb",
    #     user="postgres",
    #     password="your_password"  # Change this to your actual password
    # )
    # return conn
    raise Exception("Database not configured")

# Mock data for users (authentication)
users = [
    {"user_id": 1, "name": "John Doe", "email": "john@example.com", "password": "admin123", "user_type": "admin"},
    {"user_id": 2, "name": "Jane Smith", "email": "jane@example.com", "password": "student123", "user_type": "student"},
    {"user_id": 3, "name": "Carlos Perez", "email": "carlos@example.com", "password": "student123", "user_type": "student"},
    {"user_id": 4, "name": "Mayor Johnson", "email": "mayor@example.com", "password": "mayor123", "user_type": "mayor"},
]

# Mock data for students/scholars
students = [
    {"id": 1, "name": "Jane Smith", "email": "jane@example.com", "course": "Computer Science", "year": 2},
    {"id": 2, "name": "Carlos Perez", "email": "carlos@example.com", "course": "Engineering", "year": 3},
    {"id": 3, "name": "Maria Lopez", "email": "maria@example.com", "course": "Business", "year": 1},
]

# Mock data for scholarship applications
applications = [
    {"app_id": 1, "student_id": 2, "student_name": "Jane Smith", "status": "Pending", "type": "New Application", "date": "2024-12-01"},
    {"app_id": 2, "student_id": 3, "student_name": "Carlos Perez", "status": "Approved", "type": "Renewal", "date": "2024-11-28"},
    {"app_id": 3, "student_id": 1, "student_name": "Maria Lopez", "status": "Under Review", "type": "New Application", "date": "2024-12-05"},
]

# Mock data for scholarship records
scholarship_records = [
    {"record_id": 1, "student_id": 2, "student_name": "Jane Smith", "scholarship_type": "Academic", "amount": 10000, "semester": "1st Semester 2024"},
    {"record_id": 2, "student_id": 3, "student_name": "Carlos Perez", "scholarship_type": "Financial Aid", "amount": 15000, "semester": "1st Semester 2024"},
]

# Home route
@app.route('/')
def home():
    return jsonify({"message": "Student Dashboard API is running!"})


# -----------------------------
# Authentication Routes
# -----------------------------

@app.route("/login", methods=["POST"])
def login():
    """Login with JWT token generation."""
    data = request.get_json()
    email = data.get("email")
    password = data.get("password")

    # Find user by email and password
    user = next((u for u in users if u["email"] == email and u["password"] == password), None)
    if user:
        token = jwt.encode(
            {
                "user_id": user["user_id"],
                "email": email,
                "user_type": user["user_type"],
                "exp": datetime.datetime.utcnow() + datetime.timedelta(hours=2)
            },
            app.config["SECRET_KEY"],
            algorithm="HS256"
        )
        return jsonify({
            "token": token, 
            "user": {
                "user_id": user["user_id"],
                "name": user["name"],
                "email": user["email"],
                "user_type": user["user_type"]
            }
        })
    return jsonify({"error": "Invalid credentials"}), 401


@app.route("/verify_token", methods=["POST"])
def verify_token():
    """Verify JWT tokens."""
    data = request.get_json()
    token = data.get("token")

    try:
        decoded = jwt.decode(token, app.config["SECRET_KEY"], algorithms=["HS256"])
        return jsonify({"valid": True, "decoded": decoded})
    except jwt.ExpiredSignatureError:
        return jsonify({"valid": False, "error": "Token expired"})
    except jwt.InvalidTokenError:
        return jsonify({"valid": False, "error": "Invalid token"})


# -----------------------------
# Admin Routes
# -----------------------------

@app.route("/admin/dashboard", methods=["GET"])
def admin_dashboard():
    """Get admin dashboard statistics."""
    total_users = len(users)
    total_students = len([u for u in users if u["user_type"] == "student"])
    total_admins = len([u for u in users if u["user_type"] == "admin"])
    total_mayors = len([u for u in users if u["user_type"] == "mayor"])
    total_applications = len(applications)
    pending_applications = len([a for a in applications if a["status"] == "Pending"])

    return jsonify({
        "total_users": total_users,
        "total_students": total_students,
        "total_admins": total_admins,
        "total_mayors": total_mayors,
        "total_applications": total_applications,
        "pending_applications": pending_applications
    })


@app.route("/admin/users", methods=["GET"])
def admin_users():
    """Return all users for admin."""
    return jsonify({"data": users})


@app.route("/admin/add", methods=["POST", "OPTIONS"])
def add_admin():
    if request.method == "OPTIONS":
        return jsonify({"status": "ok"}), 200
    """Add new admin account."""
    data = request.get_json()
    first_name = data.get("first_name", "")
    middle_name = data.get("middle_name", "")
    last_name = data.get("last_name", "")
    name = data.get("name") or f"{first_name} {middle_name} {last_name}".strip()
    email = data.get("email")
    password = data.get("password", "admin123")
    
    if not email or not name:
        return jsonify({"error": "Name and email are required"}), 400
    
    # Check if email already exists
    if any(u["email"] == email for u in users):
        return jsonify({"error": "Email already exists"}), 400
    
    new_id = max([u["user_id"] for u in users], default=0) + 1
    new_admin = {
        "user_id": new_id,
        "name": name,
        "email": email,
        "password": password,
        "user_type": "admin"
    }
    
    users.append(new_admin)
    return jsonify({"message": "Admin added successfully", "admin": new_admin})


@app.route("/mayor/add", methods=["POST"])
def add_mayor():
    """Add new mayor account."""
    data = request.get_json()
    name = data.get("name")
    email = data.get("email")
    password = data.get("password", "mayor123")
    
    if not name or not email:
        return jsonify({"error": "Name and email are required"}), 400
    
    # Check if email already exists
    if any(u["email"] == email for u in users):
        return jsonify({"error": "Email already exists"}), 400
    
    new_id = max([u["user_id"] for u in users], default=0) + 1
    new_mayor = {
        "user_id": new_id,
        "name": name,
        "email": email,
        "password": password,
        "user_type": "mayor"
    }
    
    users.append(new_mayor)
    return jsonify({"message": "Mayor added successfully", "mayor": new_mayor})


@app.route("/admins", methods=["GET"])
def get_admins():
    """List all admin users."""
    admins = [u for u in users if u["user_type"] == "admin"]
    return jsonify({"admins": admins})


# -----------------------------
# Mayor Routes
# -----------------------------

@app.route("/mayor/dashboard", methods=["GET", "OPTIONS"])
def mayor_dashboard():
    if request.method == "OPTIONS":
        return jsonify({"status": "ok"}), 200
    """Get mayor dashboard statistics."""
    try:
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        # Get application statistics
        cur.execute("SELECT status, COUNT(*) as count FROM application GROUP BY status")
        app_stats = cur.fetchall()
        
        # Get renewal statistics
        cur.execute("SELECT status, COUNT(*) as count FROM renew GROUP BY status")
        renewal_stats = cur.fetchall()
        
        cur.close()
        conn.close()
        
        # Process statistics
        stats = {
            "total_new": sum(s['count'] for s in app_stats),
            "approved_new": next((s['count'] for s in app_stats if s['status'] == 'approved'), 0),
            "pending_new": next((s['count'] for s in app_stats if s['status'] == 'pending'), 0),
            "rejected_new": next((s['count'] for s in app_stats if s['status'] == 'rejected'), 0),
            "total_renewals": sum(s['count'] for s in renewal_stats),
            "approved_renewals": next((s['count'] for s in renewal_stats if s['status'] == 'approved'), 0),
            "pending_renewals": next((s['count'] for s in renewal_stats if s['status'] == 'pending'), 0),
            "rejected_renewals": next((s['count'] for s in renewal_stats if s['status'] == 'rejected'), 0),
        }
        
        return jsonify(stats)
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/mayor/scholars", methods=["GET"])
def view_scholars():
    """View all scholars."""
    return jsonify({"scholars": students})


@app.route("/mayor/records", methods=["GET"])
def scholar_records():
    """Get scholar records."""
    return jsonify({"records": scholarship_records})


# -----------------------------
# Student/Scholar Routes
# -----------------------------

@app.route('/students', methods=['GET'])
def get_students():
    """Get all students."""
    return jsonify({"students": students})


@app.route('/student/<int:user_id>', methods=['GET'])
def get_student_by_id(user_id):
    """Get specific student details."""
    student = next((s for s in students if s["id"] == user_id), None)
    
    if student:
        return jsonify({"student": student})
    return jsonify({"error": "Student not found"}), 404


@app.route("/student/profile/<int:user_id>", methods=["GET"])
def get_student_profile(user_id):
    """Get student profile."""
    user = next((u for u in users if u["user_id"] == user_id), None)
    student = next((s for s in students if s["id"] == user_id), None)
    
    if user:
        profile = {
            "user_id": user["user_id"],
            "name": user["name"],
            "email": user["email"],
            "user_type": user["user_type"]
        }
        if student:
            profile.update({
                "course": student.get("course"),
                "year": student.get("year")
            })
        return jsonify({"profile": profile})
    return jsonify({"error": "User not found"}), 404


@app.route('/add_student', methods=['POST'])
def add_student():
    """Add new student."""
    data = request.get_json()
    name = data.get('name')
    email = data.get('email')
    course = data.get('course', '')
    year = data.get('year', 1)
    
    if not name or not email:
        return jsonify({"error": "Name and email are required"}), 400
    
    new_id = max([s['id'] for s in students], default=0) + 1
    new_student = {
        "id": new_id,
        "name": name,
        "email": email,
        "course": course,
        "year": year
    }
    
    students.append(new_student)
    return jsonify({"message": "Student added successfully", "student": new_student})


# -----------------------------
# Scholarship Application Routes
# -----------------------------

@app.route("/scholarship/apply", methods=["POST", "OPTIONS"])
def apply_scholarship():
    if request.method == "OPTIONS":
        return jsonify({"status": "ok"}), 200
    """Submit scholarship application."""
    data = request.get_json()
    user_id = data.get("student_id")
    student_name = data.get("student_name")
    
    if not user_id or not student_name:
        return jsonify({"error": "Student ID and name are required"}), 400
    
    try:
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        name_parts = student_name.split()
        first_name = name_parts[0] if len(name_parts) > 0 else ''
        last_name = name_parts[-1] if len(name_parts) > 1 else ''
        
        cur.execute(
            """INSERT INTO application (user_id, first_name, last_name, year_applied, status) 
               VALUES (%s, %s, %s, %s, %s) RETURNING application_id""",
            (user_id, first_name, last_name, datetime.datetime.now().year, 'pending')
        )
        app_id = cur.fetchone()['application_id']
        conn.commit()
        cur.close()
        conn.close()
        
        return jsonify({"message": "Application submitted successfully", "application": {"app_id": app_id}})
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/scholarship/renew", methods=["POST", "OPTIONS"])
def renew_scholarship():
    if request.method == "OPTIONS":
        return jsonify({"status": "ok"}), 200
    """Submit scholarship renewal."""
    data = request.get_json()
    user_id = data.get("student_id")
    student_name = data.get("student_name")
    
    if not user_id or not student_name:
        return jsonify({"error": "Student ID and name are required"}), 400
    
    try:
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        name_parts = student_name.split()
        first_name = name_parts[0] if len(name_parts) > 0 else ''
        last_name = name_parts[-1] if len(name_parts) > 1 else ''
        
        cur.execute("SELECT application_id FROM application WHERE user_id = %s LIMIT 1", (user_id,))
        app = cur.fetchone()
        app_id = app['application_id'] if app else 1
        
        cur.execute(
            """INSERT INTO renew (application_id, user_id, first_name, last_name, status) 
               VALUES (%s, %s, %s, %s, %s) RETURNING renewal_id""",
            (app_id, user_id, first_name, last_name, 'Pending')
        )
        renewal_id = cur.fetchone()['renewal_id']
        conn.commit()
        cur.close()
        conn.close()
        
        return jsonify({"message": "Renewal application submitted successfully", "application": {"renewal_id": renewal_id}})
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/applications/student/<int:student_id>", methods=["GET", "OPTIONS"])
def get_student_applications(student_id):
    if request.method == "OPTIONS":
        return jsonify({"status": "ok"}), 200
    """Get applications for a specific student."""
    try:
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute(
            """SELECT application_id, user_id as student_id, 
               CONCAT(first_name, ' ', last_name) as student_name, 
               status, submission_date as date 
               FROM application WHERE user_id = %s""",
            (student_id,)
        )
        apps = cur.fetchall()
        cur.close()
        conn.close()
        
        result = [{
            'app_id': app['application_id'],
            'student_id': app['student_id'],
            'student_name': app['student_name'],
            'status': app['status'],
            'date': app['date'].strftime('%Y-%m-%d') if app['date'] else ''
        } for app in apps]
        
        return jsonify({"applications": result})
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/applications", methods=["GET"])
def get_all_applications():
    """Get all applications."""
    return jsonify({"applications": applications})


@app.route("/applications/pending", methods=["GET"])
def get_pending():
    """Get pending applications."""
    pending = [a for a in applications if a["status"] == "Pending"]
    return jsonify({"pending_applications": pending})


@app.route("/application/<int:app_id>/status", methods=["PUT", "OPTIONS"])
def update_application_status(app_id):
    if request.method == "OPTIONS":
        return jsonify({"status": "ok"}), 200
    """Update application status."""
    data = request.get_json()
    new_status = data.get("status")
    
    if not new_status:
        return jsonify({"error": "Status is required"}), 400
    
    try:
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        cur.execute(
            "UPDATE application SET status = %s WHERE application_id = %s RETURNING *",
            (new_status.lower(), app_id)
        )
        updated_app = cur.fetchone()
        
        if not updated_app:
            cur.close()
            conn.close()
            return jsonify({"error": "Application not found"}), 404
        
        conn.commit()
        cur.close()
        conn.close()
        
        return jsonify({"message": "Application status updated", "application": dict(updated_app)})
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/mayor/applications/approve/<int:app_id>", methods=["POST", "OPTIONS"])
def approve_application(app_id):
    if request.method == "OPTIONS":
        return jsonify({"status": "ok"}), 200
    """Approve scholarship application."""
    data = {"status": "approved"}
    request.get_json = lambda: data
    return update_application_status(app_id)


@app.route("/mayor/applications/reject/<int:app_id>", methods=["POST", "OPTIONS"])
def reject_application(app_id):
    if request.method == "OPTIONS":
        return jsonify({"status": "ok"}), 200
    """Reject scholarship application."""
    data = {"status": "rejected"}
    request.get_json = lambda: data
    return update_application_status(app_id)


@app.route("/mayor/applications", methods=["GET", "OPTIONS"])
def get_mayor_applications():
    if request.method == "OPTIONS":
        return jsonify({"status": "ok"}), 200
    """Get all applications for mayor view."""
    try:
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute(
            """SELECT application_id, user_id, first_name, middle_name, last_name, 
               student_id, course, year_level, gwa, status, submission_date 
               FROM application ORDER BY submission_date DESC"""
        )
        apps = cur.fetchall()
        cur.close()
        conn.close()
        
        return jsonify({"applications": [dict(app) for app in apps]})
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/application/<int:app_id>/archive", methods=["PUT", "OPTIONS"])
def archive_application(app_id):
    if request.method == "OPTIONS":
        return jsonify({"status": "ok"}), 200
    """Archive an application."""
    try:
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        cur.execute(
            "UPDATE application SET archived = TRUE WHERE application_id = %s RETURNING *",
            (app_id,)
        )
        updated_app = cur.fetchone()
        
        if not updated_app:
            cur.close()
            conn.close()
            return jsonify({"error": "Application not found"}), 404
        
        conn.commit()
        cur.close()
        conn.close()
        
        return jsonify({"message": "Application archived", "application": dict(updated_app)})
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/renewal/<int:renewal_id>/archive", methods=["PUT", "OPTIONS"])
def archive_renewal(renewal_id):
    if request.method == "OPTIONS":
        return jsonify({"status": "ok"}), 200
    """Archive a renewal."""
    try:
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        cur.execute(
            "UPDATE renew SET archived = TRUE WHERE renewal_id = %s RETURNING *",
            (renewal_id,)
        )
        updated_renewal = cur.fetchone()
        
        if not updated_renewal:
            cur.close()
            conn.close()
            return jsonify({"error": "Renewal not found"}), 404
        
        conn.commit()
        cur.close()
        conn.close()
        
        return jsonify({"message": "Renewal archived", "renewal": dict(updated_renewal)})
    except Exception as e:
        return jsonify({"error": str(e)}), 500


# -----------------------------
# Renewal Status Routes
# -----------------------------

@app.route("/renewal/status", methods=["GET", "OPTIONS"])
def get_renewal_status():
    if request.method == "OPTIONS":
        return jsonify({"status": "ok"}), 200
    """Get renewal open/closed status."""
    try:
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("SELECT is_open FROM renewal_settings WHERE id = 1")
        result = cur.fetchone()
        cur.close()
        conn.close()
        
        is_open = result['is_open'] if result else False
        return jsonify({"is_open": is_open})
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/renewal/status", methods=["PUT", "OPTIONS"])
def update_renewal_status():
    if request.method == "OPTIONS":
        return jsonify({"status": "ok"}), 200
    """Update renewal open/closed status."""
    data = request.get_json()
    is_open = data.get("is_open")
    
    if is_open is None:
        return jsonify({"error": "is_open field is required"}), 400
    
    try:
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        cur.execute(
            """INSERT INTO renewal_settings (id, is_open, updated_at) 
               VALUES (1, %s, NOW()) 
               ON CONFLICT (id) DO UPDATE SET is_open = %s, updated_at = NOW()
               RETURNING *""",
            (is_open, is_open)
        )
        result = cur.fetchone()
        conn.commit()
        cur.close()
        conn.close()
        
        return jsonify({"message": "Renewal status updated", "is_open": result['is_open']})
    except Exception as e:
        return jsonify({"error": str(e)}), 500


if __name__ == "__main__":
    app.run(debug=True, host='0.0.0.0', port=5000)