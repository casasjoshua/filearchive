# 📁 File Archiving System

The **File Archiving System** is a web-based application designed to organize, manage, and retrieve digital files efficiently. Built using **Django** and **MySQL**, it features user role management, file categorization, archiving capabilities, and an admin dashboard. It also uses advanced SQL features like Stored Procedures, Triggers, Views, Common Table Expressions (CTEs), and Transactions to enhance performance and maintain data integrity.

---

## ✅ Features
- File Upload and Archiving
- User Registration and Role Management
- Category-based File Organization
- Search and Filter Functionality
- Dashboard with Summary Counts
- Advanced SQL Integration (Stored Procedures, Triggers, CTEs, etc.)

---

## 🚀 Installation Instructions

### 1. Clone the repository
```bash
git clone https://github.com/your-username/file-archiving-system.git
cd file-archiving-system

```
2. Set up a virtual environment (optional but recommended)
```
python -m venv venv
# Windows
venv\Scripts\activate
# macOS/Linux
source venv/bin/activate

```
3. Install the dependencies
```
pip install -r requirements.txt


```
4. Configure your database (MySQL)
```
Create a MySQL database (e.g., filearchive_db)

Update your Django settings.py with your DB credentials

```
5. Apply migrations
```
python manage.py migrate

```
6. Run the development server
```
python manage.py runserver


```
⚙️ Deployment Notes
Local deployment is fully supported.

Ensure your database server is running.

You may upload the system to GitHub and configure it for platforms like PythonAnywhere, Heroku, or Render.

Be sure to include your .env file (or set environment variables) for production deployment.



🧾 Dependencies
Listed in requirements.txt. Install using:
pip install -r requirements.txt



🧠 Authors and Contributors
Submitted by:
Joshua P. Casas
MSIT
EVSU


Submitted to:
Jessie Paragas, DIT
Advance Database Instructor
EVSU




---

Let me know if you want it customized with your actual GitHub link, contributor names, or deployment platform!



