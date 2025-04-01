from app import app, db
from flask import render_template, jsonify, request, redirect, url_for, flash, session
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError
from app.database import get_db_connection
import mysql.connector
from mysql.connector import Error
from datetime import datetime

def handle_database_error(e):
    """Handle database errors and return appropriate error message"""
    error_message = str(e)
    if "Access denied" in error_message:
        return "Access denied to the database. Please check your credentials."
    elif "Connection refused" in error_message:
        return "Could not connect to the database server. Please check if the server is running."
    elif "Unknown database" in error_message:
        return "The specified database does not exist."
    else:
        return "An error occurred while connecting to the database."

@app.route('/')
def welcome():
    return render_template('welcome.html')

@app.route('/test-connection')
def test_connection():
    try:
        # Get database connection
        conn = get_db_connection()
        cursor = conn.cursor()

        # Test connection by getting list of tables
        cursor.execute("SHOW TABLES")
        tables = [table[0] for table in cursor.fetchall()]

        # Close database connection
        cursor.close()
        conn.close()

        # Store connection status in session
        session['db_connected'] = True

        return jsonify({
            'status': 'success',
            'message': 'Database connection successful',
            'tables': tables
        })
    except Exception as e:
        error_message = handle_database_error(e)
        return jsonify({
            'status': 'error',
            'message': error_message
        }), 500

@app.route('/tables')
def index():
    # Check if database is connected
    if not session.get('db_connected'):
        return redirect(url_for('welcome'))

    try:
        # Get database connection
        conn = get_db_connection()
        cursor = conn.cursor()

        # Get list of tables and their record counts
        cursor.execute("SHOW TABLES")
        tables = []
        for table in cursor.fetchall():
            table_name = table[0]
            print(f"Processing table: {table_name}")  # Debug log
            cursor.execute(f"SELECT COUNT(*) FROM {table_name}")
            record_count = cursor.fetchone()[0]
            print(f"Record count for {table_name}: {record_count}")  # Debug log
            tables.append({
                'name': table_name,
                'record_count': record_count
            })

        print(f"Total tables found: {len(tables)}")  # Debug log
        print(f"Tables data: {tables}")  # Debug log

        # Close database connection
        cursor.close()
        conn.close()

        return render_template('index.html', tables=tables)
    except Exception as e:
        # Log the error
        print(f"Database connection error: {str(e)}")
        # Clear connection status
        session.pop('db_connected', None)
        # Return error template with detailed message
        return render_template('error.html', 
                             error="Database Connection Error",
                             details=str(e),
                             back_url=url_for('welcome'))

@app.route('/table/<table_name>')
def table_view(table_name):
    # Check if database is connected
    if not session.get('db_connected'):
        return redirect(url_for('welcome'))

    try:
        # Get database connection
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)

        # Get column names and types
        cursor.execute(f"SHOW COLUMNS FROM {table_name}")
        columns = cursor.fetchall()
        column_names = [col['Field'] for col in columns]
        column_types = {col['Field']: col['Type'] for col in columns}
        
        # Get auto-increment columns
        auto_increment_columns = [col['Field'] for col in columns if col.get('Extra') == 'auto_increment']

        # Get foreign key information
        cursor.execute(f"""
            SELECT 
                COLUMN_NAME,
                REFERENCED_TABLE_NAME,
                REFERENCED_COLUMN_NAME
            FROM information_schema.KEY_COLUMN_USAGE
            WHERE TABLE_SCHEMA = DATABASE()
            AND TABLE_NAME = %s
            AND REFERENCED_TABLE_NAME IS NOT NULL
        """, [table_name])
        foreign_keys = cursor.fetchall()
        foreign_key_info = {fk['COLUMN_NAME']: {
            'table': fk['REFERENCED_TABLE_NAME'],
            'column': fk['REFERENCED_COLUMN_NAME']
        } for fk in foreign_keys}

        # Get search and sort parameters
        search = request.args.get('search', '')
        sort_by = request.args.get('sort_by', '')
        sort_order = request.args.get('sort_order', 'asc')
        page = int(request.args.get('page', 1))
        per_page = 10

        # Build the base query
        query = f"SELECT * FROM {table_name}"
        count_query = f"SELECT COUNT(*) as total FROM {table_name}"
        params = []

        # Add search condition if search parameter is provided
        if search:
            search_conditions = []
            for col in column_names:
                search_conditions.append(f"{col} LIKE %s")
                params.append(f"%{search}%")
            query += " WHERE " + " OR ".join(search_conditions)
            count_query += " WHERE " + " OR ".join(search_conditions)

        # Add sorting if sort parameter is provided
        if sort_by and sort_by in column_names:
            query += f" ORDER BY {sort_by} {sort_order}"

        # Add pagination
        query += " LIMIT %s OFFSET %s"
        params.extend([per_page, (page - 1) * per_page])

        # Get total count
        cursor.execute(count_query, params[:-2] if search else [])
        total_records = cursor.fetchone()['total']
        total_pages = (total_records + per_page - 1) // per_page

        # Get data for current page
        cursor.execute(query, params)
        records = cursor.fetchall()

        # Close database connection
        cursor.close()
        conn.close()

        # If it's an AJAX request, return only the table content
        if request.headers.get('X-Requested-With') == 'XMLHttpRequest':
            return jsonify({
                'status': 'success',
                'html': render_template('table_content.html',
                                     table_name=table_name,
                                     records=records,
                                     column_names=column_names,
                                     column_types=column_types,
                                     foreign_key_info=foreign_key_info,
                                     auto_increment_columns=auto_increment_columns,
                                     search=search,
                                     sort_by=sort_by,
                                     sort_order=sort_order,
                                     page=page,
                                     total_pages=total_pages,
                                     total_records=total_records,
                                     per_page=per_page,
                                     min=min,
                                     max=max)
            })

        # For regular request, return full page
        return render_template('table_view.html',
                             table_name=table_name,
                             records=records,
                             column_names=column_names,
                             column_types=column_types,
                             foreign_key_info=foreign_key_info,
                             auto_increment_columns=auto_increment_columns,
                             search=search,
                             sort_by=sort_by,
                             sort_order=sort_order,
                             page=page,
                             total_pages=total_pages,
                             total_records=total_records,
                             per_page=per_page,
                             min=min,
                             max=max)

    except Exception as e:
        # Log the error
        print(f"Error in table_view: {str(e)}")
        # Return error template with detailed message
        return render_template('error.html',
                             error="Database Error",
                             details=str(e),
                             back_url=url_for('index'))

@app.route('/table/<table_name>/add', methods=['GET', 'POST'])
def add_record(table_name):
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        if request.method == 'POST':
            # Get column names and types
            cursor.execute(f"SHOW COLUMNS FROM {table_name}")
            columns = [col['Field'] for col in cursor.fetchall()]
            
            # Build INSERT query
            placeholders = ', '.join(['%s'] * len(columns))
            query = f"INSERT INTO {table_name} ({', '.join(columns)}) VALUES ({placeholders})"
            
            # Get values from form, using None for missing fields
            values = []
            for col in columns:
                value = request.form.get(col)
                values.append(None if value is None or value.strip() == '' else value)
            
            # Execute query
            cursor.execute(query, values)
            conn.commit()
            
            return jsonify({
                'status': 'success',
                'message': 'Record added successfully'
            })
        
        # GET request - show form
        cursor.execute(f"SHOW COLUMNS FROM {table_name}")
        columns = [col['Field'] for col in cursor.fetchall()]
        column_types = {col['Field']: col['Type'] for col in cursor.fetchall()}
        
        cursor.close()
        conn.close()
        
        return render_template('add_record.html',
                             table_name=table_name,
                             columns=columns,
                             column_types=column_types)
    except Error as e:
        return jsonify({
            'status': 'error',
            'message': str(e)
        }), 500

@app.route('/table/<table_name>/edit/<id>', methods=['GET', 'POST'])
def edit_record(table_name, id):
    conn = None
    cursor = None
    try:
        print(f"Attempting to edit record {id} from table {table_name}")  # Debug log
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        if request.method == 'POST':
            # Get column names and types
            cursor.execute(f"SHOW COLUMNS FROM {table_name}")
            columns = [col['Field'] for col in cursor.fetchall()]
            
            # Build UPDATE query
            set_clause = ', '.join([f"{col} = %s" for col in columns])
            query = f"UPDATE {table_name} SET {set_clause} WHERE {columns[0]} = %s"
            
            # Get values from form, using None for missing fields
            values = []
            for col in columns:
                value = request.form.get(col)
                values.append(None if value is None or value.strip() == '' else value)
            values.append(id)
            
            print(f"Executing UPDATE query: {query}")  # Debug log
            print(f"With values: {values}")  # Debug log
            
            # Execute query
            cursor.execute(query, values)
            conn.commit()
            
            return jsonify({
                'status': 'success',
                'message': 'Record updated successfully'
            })
        
        # GET request - get record data
        cursor.execute(f"SHOW COLUMNS FROM {table_name}")
        columns = cursor.fetchall()
        primary_key = columns[0]['Field']
        
        print(f"Primary key column: {primary_key}")  # Debug log
        
        query = f"SELECT * FROM {table_name} WHERE {primary_key} = %s"
        print(f"Executing SELECT query: {query}")  # Debug log
        print(f"With id: {id}")  # Debug log
        
        cursor.execute(query, [id])
        record = cursor.fetchone()
        
        if not record:
            print(f"No record found with id {id}")  # Debug log
            return jsonify({
                'status': 'error',
                'message': f'Record with ID {id} not found'
            }), 404
        
        print(f"Found record: {record}")  # Debug log
        
        return jsonify({
            'status': 'success',
            'record': record
        })
        
    except Error as e:
        print(f"Database error in edit_record: {str(e)}")  # Debug log
        return jsonify({
            'status': 'error',
            'message': f'Database error: {str(e)}'
        }), 500
    except Exception as e:
        print(f"Unexpected error in edit_record: {str(e)}")  # Debug log
        return jsonify({
            'status': 'error',
            'message': f'Unexpected error: {str(e)}'
        }), 500
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()

@app.route('/table/<table_name>/delete/<id>', methods=['POST'])
def delete_record(table_name, id):
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # Get primary key column name
        cursor.execute(f"SHOW COLUMNS FROM {table_name}")
        primary_key = cursor.fetchone()[0]
        
        # Execute DELETE query
        cursor.execute(f"DELETE FROM {table_name} WHERE {primary_key} = %s", [id])
        conn.commit()
        
        if request.headers.get('X-Requested-With') == 'XMLHttpRequest':
            return jsonify({
                'status': 'success',
                'message': 'Record deleted successfully'
            })
        
        flash('Record deleted successfully', 'success')
        return redirect(url_for('table_view', table_name=table_name))
    except Error as e:
        if request.headers.get('X-Requested-With') == 'XMLHttpRequest':
            return jsonify({
                'status': 'error',
                'message': str(e)
            }), 500
        return render_template('error.html', error=str(e))

@app.route('/table/<table_name>/record/<id>')
def get_record_details(table_name, id):
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        # Get column names
        cursor.execute(f"SHOW COLUMNS FROM {table_name}")
        columns = cursor.fetchall()
        primary_key = columns[0]['Field']
        
        # Get record data
        query = f"SELECT * FROM {table_name} WHERE {primary_key} = %s"
        cursor.execute(query, [id])
        record = cursor.fetchone()
        
        if not record:
            return jsonify({
                'status': 'error',
                'message': 'Record not found'
            }), 404
        
        # Convert record to a dictionary with string keys
        record_dict = {}
        for key, value in record.items():
            # Convert datetime objects to strings if present
            if isinstance(value, datetime):
                value = value.strftime('%Y-%m-%d %H:%M:%S')
            record_dict[str(key)] = value
        
        cursor.close()
        conn.close()
        
        return jsonify({
            'status': 'success',
            'record': record_dict
        })
    except Exception as e:
        print(f"Error in get_record_details: {str(e)}")  # Debug log
        return jsonify({
            'status': 'error',
            'message': str(e)
        }), 500 