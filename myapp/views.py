from django.contrib.auth.decorators import login_required
from django.shortcuts import render, redirect
from django.contrib import messages
from django.contrib.auth import login as auth_login
from django.db import connection
from django.contrib.auth.hashers import check_password, make_password
from .models import User, FileArchive, FileCategory
from django.http import HttpResponse
from django.views.decorators.http import require_http_methods
import traceback
from django.core.files.storage import default_storage
from django.views.decorators.http import require_POST
from django.shortcuts import get_object_or_404
from collections import namedtuple


def register_view(request):
    if request.method == 'POST':
        username = request.POST.get('username')
        email = request.POST.get('email')
        raw_password = request.POST.get('password')
        hashed_password = make_password(raw_password)

        with connection.cursor() as cursor:
            # Declare message to be captured from the stored procedure
            message = ''
            cursor.callproc('RegisterUser', [username, email, hashed_password, message])
            cursor.execute("SELECT @_RegisterUser_3")  # Fetch OUT parameter (0-based index)
            message = cursor.fetchone()[0]

        if message == 'Account created successfully.':
            messages.success(request, message)
            return redirect('login')  # Replace with your login view's URL name
        else:
            messages.error(request, message)

    return render(request, 'register.html')

def login_view(request):
    if request.method == 'POST':
        email = request.POST.get('email')
        password_input = request.POST.get('password')

        with connection.cursor() as cursor:
            cursor.callproc("AuthenticateUser", [email])
            result = cursor.fetchall()

        if result:
            user_id, username, password_hash, is_active, is_admin = result[0]
            if check_password(password_input, password_hash):
                request.session['user_id'] = user_id
                request.session['username'] = username
                request.session['is_admin'] = is_admin

                # ✅ Call stored procedure to log login
                with connection.cursor() as cursor:
                    cursor.callproc("LogUserLogin", [user_id, username, email])

                if is_admin:
                    return redirect('admin_dashboard_view')
                else:
                    return redirect('user_dashboard_view')
            else:
                messages.error(request, 'Invalid email or password')
        else:
            messages.error(request, 'Invalid email or password')

    return render(request, 'index.html')


def admin_dashboard_view(request):
    if not request.session.get('user_id') or not request.session.get('is_admin'):
        messages.error(request, 'Access denied.')
        return redirect('login')

    return render(request, 'administrator/index.html')

def user_dashboard_view(request):
    if not request.session.get('user_id') or request.session.get('is_admin'):
        messages.error(request, 'Access denied.')
        return redirect('login')

    return render(request, 'user/index.html')

def logout_view(request):
    request.session.flush()
    return redirect('login')

@require_http_methods(["GET", "POST"])
def upload_file_view(request):
    user_id = request.session.get('user_id')
    if not user_id:
        messages.error(request, 'You must be logged in to upload files.')
        return redirect('login')

    categories = FileCategory.objects.all()
    files = FileArchive.objects.all()

    if request.method == 'POST':
        file = request.FILES.get('file')
        original_filename = request.POST.get('original_filename')
        description = request.POST.get('description', '')
        category_id = request.POST.get('category_id')

        if not all([file, original_filename, category_id]):
            messages.error(request, 'Please fill in all required fields.')
        else:
            try:
                # ✅ Save file to storage
                file_path = default_storage.save(f'archives/{file.name}', file)
                file_path = file_path.replace('\\', '/')  # Normalize path for MySQL

                # ✅ Call stored procedure with all 6 arguments
                with connection.cursor() as cursor:
                    cursor.callproc('log_file_upload', [
                        int(user_id),
                        int(category_id),
                        file_path,
                        original_filename,
                        description,
                        False  # is_public default
                    ])

                messages.success(request, 'File uploaded successfully.')
                return redirect('file_archive_view')

            except Exception as e:
                messages.error(request, f'Error uploading file: {str(e)}')

    return render(request, 'administrator/file-archive.html', {
        'categories': categories,
        'files': files
    })


def file_archive_view(request):
    files = FileArchive.objects.all()
    categories = FileCategory.objects.all()

    return render(request, 'administrator/file-archive.html', {
        'files': files,
        'categories': categories
    })

@require_POST
def delete_file_view(request, file_id):
    user_id = request.session.get('user_id')
    if not user_id:
        messages.error(request, 'You must be logged in to delete files.')
        return redirect('login')

    file = get_object_or_404(FileArchive, id=file_id)

    try:
        # ✅ Delete file from storage
        file.file.delete()

        # ✅ Delete database record — this will trigger MySQL's BEFORE DELETE trigger
        file.delete()

        messages.success(request, 'File deleted successfully (trigger logged).')
    except Exception as e:
        messages.error(request, f'Error deleting file: {e}')

    return redirect('file_archive_view')


@require_POST
def edit_file_view(request, file_id):
    user_id = request.session.get('user_id')
    if not user_id:
        messages.error(request, 'You must be logged in to edit files.')
        return redirect('login')

    category_id = request.POST.get('category_id')
    original_filename = request.POST.get('original_filename')
    description = request.POST.get('description')
    is_public = request.POST.get('is_public') == 'on'

    try:
        with connection.cursor() as cursor:
            cursor.callproc('update_file_record', [
                int(file_id),
                int(category_id),
                original_filename,
                description,
                is_public
            ])
        messages.success(request, 'File updated successfully.')
    except Exception as e:
        messages.error(request, f'Error updating file: {e}')

    return redirect('file_archive_view')

# Utility function to convert raw SQL results into namedtuples for easier access in templates
def namedtuplefetchall(cursor):
    """
    Convert all rows from a database cursor into a list of namedtuples.
    This allows accessing columns by name (e.g., user.username instead of user[1]).
    """
    desc = cursor.description  # Get metadata about result columns
    nt_result = namedtuple('User', [col[0] for col in desc])  # Create a namedtuple class using column names
    return [nt_result(*row) for row in cursor.fetchall()]  # Return list of namedtuple records

# View to retrieve and display all users using a stored procedure
def user_list_view(request):
    """
    Calls the MySQL stored procedure 'get_all_users' to fetch user records,
    processes the result into namedtuples, and renders them in a template.
    """
    with connection.cursor() as cursor:
        cursor.callproc('get_all_users')  # Call the stored procedure
        users = namedtuplefetchall(cursor)  # Convert result to list of namedtuples

    # Render the template with the list of users
    return render(request, 'administrator/list-users.html', {'users': users})


@require_POST
def add_user_view(request):
    # Retrieve form data from POST request
    username = request.POST['username']
    email = request.POST['email']
    password = request.POST['password']
    first_name = request.POST.get('first_name', '')  # Optional
    last_name = request.POST.get('last_name', '')    # Optional
    is_admin = int(request.POST.get('is_admin', 0))  # Cast to 0 or 1 (False or True)

    try:
        # Use a stored procedure to insert the user into the database
        with connection.cursor() as cursor:
            cursor.callproc('insert_user', [username, email, password, first_name, last_name, is_admin])
        
        # Success message
        messages.success(request, 'User added successfully!')
    
    except Exception as e:
        # Error message if something goes wrong
        messages.error(request, f"Error adding user: {e}")

    # Redirect to user list view (where the message should be displayed)
    return redirect('user_list_view')

# ------------------------
# EDIT USER VIEW
# ------------------------
@require_POST
def edit_user_view(request):
    """
    Handles POST request to update user data using a stored procedure.
    Requires the user ID and fields to update.
    """
    try:
        # Extract form data from POST request
        user_id = int(request.POST['user_id'])
        username = request.POST['username']
        email = request.POST['email']
        first_name = request.POST.get('first_name', '')
        last_name = request.POST.get('last_name', '')
        is_admin = int(request.POST.get('is_admin', 0))  # 1 = admin, 0 = not admin

        # Call stored procedure to update the user
        with connection.cursor() as cursor:
            cursor.callproc('update_user', [
                user_id,
                username,
                email,
                first_name,
                last_name,
                is_admin
            ])

        messages.success(request, 'User updated successfully!')
    except Exception as e:
        # Catch errors and send error message
        messages.error(request, f"Error updating user: {e}")

    # Redirect back to user list view
    return redirect('user_list_view')


# ------------------------
# DELETE USER VIEW
# ------------------------
@require_POST
def delete_user_view(request):
    """
    Handles POST request to delete a user using a stored procedure.
    Requires user ID to delete.
    """
    try:
        # Ensure 'user_id' key exists in POST (fixes MultiValueDictKeyError)
        user_id = int(request.POST.get('user_id'))

        # Call stored procedure to delete the user
        with connection.cursor() as cursor:
            cursor.callproc('delete_user', [user_id])

        messages.success(request, 'User deleted successfully!')
    except Exception as e:
        messages.error(request, f"Error deleting user: {e}")

    return redirect('user_list_view')


# Helper to convert cursor result to namedtuples for easier access
def namedtuplefetchall(cursor):
    """
    Converts all rows from a cursor into namedtuples so you can access columns by name.
    """
    desc = cursor.description
    nt_result = namedtuple('DashboardCounts', [col[0] for col in desc])
    return [nt_result(*row) for row in cursor.fetchall()]

def admin_dashboard_view(request):
    # Call stored procedure to get total counts for dashboard
    with connection.cursor() as cursor:
        cursor.callproc('get_dashboard_counts')  # Custom stored procedure in DB
        result = namedtuplefetchall(cursor)[0]   # Get the first (and only) result row

    # Fetch the 5 most recent uploaded files for recent activity section
    recent_files = FileArchive.objects.select_related('category').order_by('-uploaded_at')[:5]

    # Render the dashboard template with total counts and recent uploads
    return render(request, 'administrator/index.html', {
        'users_total': result.users_total,          # Total number of users from SP
        'files_total': result.files_total,          # Total number of files from SP
        'categories_total': result.categories_total,# Total number of categories from SP
        'recent_files': recent_files,               # Latest 5 uploaded files
    })