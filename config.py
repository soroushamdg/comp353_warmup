import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

class Config:
    # Database configuration
    DB_HOST = os.getenv('DB_HOST', 'zqc353.encs.concordia.ca')
    DB_USER = os.getenv('DB_USER', 'zqc353_4')
    DB_PASSWORD = os.getenv('DB_PASSWORD', 'blackcat')
    DB_NAME = os.getenv('DB_NAME', 'zqc353_4')
    DB_PORT = int(os.getenv('DB_PORT', '3306'))
    
    # Flask configuration
    SECRET_KEY = os.getenv('SECRET_KEY', 'dev')
    SQLALCHEMY_DATABASE_URI = f'mysql+pymysql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}'
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    SQLALCHEMY_ECHO = True  # Enable SQL query logging 