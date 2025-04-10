from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from dotenv import load_dotenv
import os
from config import Config
import re

# Load environment variables
load_dotenv()

# Initialize Flask app
app = Flask(__name__)

# Configure app
app.config.from_object(Config)

# Initialize SQLAlchemy
db = SQLAlchemy(app)

# Custom Jinja filter to format titles
@app.template_filter('format_title')
def format_title(value):
    if '_' in value:
        return ' '.join(word.capitalize() for word in value.split('_'))
    elif re.match(r'^[a-z]+([A-Z][a-z]*)*$', value):
        return re.sub(r'([a-z])([A-Z])', r'\1 \2', value).title()
    return value

# Import routes after app is created to avoid circular imports
from app import routes 