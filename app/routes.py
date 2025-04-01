from app import app, db
from flask import render_template, jsonify
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError

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
def index():
    try:
        # Query to get all table names
        result = db.session.execute(text("SHOW TABLES"))
        tables = [row[0] for row in result]
        return render_template('index.html', tables=tables)
    except SQLAlchemyError as e:
        error_message = handle_database_error(e)
        return render_template('error.html', error_message=error_message), 500

@app.route('/table/<table_name>')
def table_view(table_name):
    try:
        # Get column names
        columns_result = db.session.execute(text(f"SHOW COLUMNS FROM {table_name}"))
        columns = [row[0] for row in columns_result]
        
        # Get table data
        data_result = db.session.execute(text(f"SELECT * FROM {table_name}"))
        data = [row for row in data_result]
        
        return render_template('table_view.html', 
                             table_name=table_name,
                             columns=columns,
                             data=data)
    except SQLAlchemyError as e:
        error_message = handle_database_error(e)
        return render_template('error.html', error_message=error_message), 500

@app.route('/test-connection')
def test_connection():
    try:
        # Query to get all table names
        result = db.session.execute(text("SHOW TABLES"))
        tables = [row[0] for row in result]
        return jsonify({
            'status': 'success',
            'message': 'Database connection successful',
            'tables': tables
        })
    except SQLAlchemyError as e:
        error_message = handle_database_error(e)
        return jsonify({
            'status': 'error',
            'message': error_message
        }), 500 