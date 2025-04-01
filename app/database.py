import mysql.connector
from mysql.connector import Error
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

def get_db_connection():
    """Create a database connection"""
    try:
        print(f"Attempting to connect to database at {os.getenv('DB_HOST')}:{os.getenv('DB_PORT')}")
        
        connection = mysql.connector.connect(
            host=os.getenv('DB_HOST'),
            user=os.getenv('DB_USER'),
            password=os.getenv('DB_PASSWORD'),
            database=os.getenv('DB_NAME'),
            port=int(os.getenv('DB_PORT')),
            connection_timeout=10,
            use_pure=True
        )
        
        if connection.is_connected():
            db_info = connection.get_server_info()
            cursor = connection.cursor()
            cursor.execute('SELECT DATABASE()')
            db_name = cursor.fetchone()[0]
            cursor.close()
            print(f"Successfully connected to MySQL Database {db_name} (version {db_info})")
            return connection
            
    except Error as e:
        print("Error connecting to MySQL Database:", str(e))
        print(f"Host: {os.getenv('DB_HOST')}")
        print(f"User: {os.getenv('DB_USER')}")
        print(f"Database: {os.getenv('DB_NAME')}")
        print(f"Port: {os.getenv('DB_PORT')}")
        raise 