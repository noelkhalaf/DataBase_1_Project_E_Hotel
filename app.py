from flask import *
import mysql.connector

app = Flask(__name__)

db = mysql.connector.connect(
    host='localhost',
    user='root',
    passwd='root',
    database='e-hotels'
)

cursor = db.cursor()

@app.route('/', methods=['GET'])
def index():
    return render_template('index.html')
    
@app.route('/employee/', methods=['GET'])
def employee_page():
    return render_template('employee.html')

@app.route('/customer/', methods=['GET'])
def customer_page():
    return render_template('customer.html')

if __name__ == '__main__':
    app.run(port=7777)