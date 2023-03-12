from flask import *
import mysql.connector

app = Flask(__name__)

db = mysql.connector.connect(
    host='localhost',
    user='root',
    passwd='root',
    database='e_hotels'
)

cursor = db.cursor()

# cursor.execute("CREATE DATABASE IF NOT EXISTS e_hotels")

with open('schema.sql', 'r') as f:
    db._execute_query(f.read())

@app.route('/', methods=['GET'])
def index():
    return render_template('index.html')
    
@app.route('/employee/', methods=['GET'])
def employee_page():
    return render_template('index.html')

@app.route('/customer/', methods=['GET'])
def customer_page():
    return render_template('index.html')

if __name__ == '__main__':
    app.run(port=7777)