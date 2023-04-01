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

@app.route('/')
def index():
    return render_template('index.html')
    
@app.route('/employee')
def employee():
    return render_template('employee.html')

@app.route('/customer')
def customer():
    return render_template('customer.html')

@app.route('/customerSignIn', methods=['GET', 'POST'])
def customerSignIn():
    msg = ''
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']
        cursor.execute('SELECT * FROM CUSTOMER WHERE username = % s AND password = % s', (username, password, ))
        customer = cursor.fetchone()
        if customer:
            msg = 'Login success !'
            return render_template('index.html', msg = msg)
        else:
            msg = 'Incorrect username or password'
    return render_template('customer_signin.html', msg = msg)

@app.route('/employeeSignIn', methods=['GET', 'POST'])
def emplyeeSignIn():
    msg = ''
    if request.method == 'POST':
        employee_id = request.form['employee_id']
        fname = request.form['fname']
        cursor.execute('SELECT * FROM EMPLOYEE WHERE employee_id = % s AND first_name = % s', (employee_id, fname, ))
        employee = cursor.fetchone()
        if employee:
            msg = 'Login success !'
            return render_template('index.html', msg = msg)
        else:
            msg = 'Incorrect id or first name'
    return render_template('employee_signin.html', msg = msg)

@app.route('/customerSignUp', methods=['GET', 'POST'])
def customerSignUp():
    msg = ''
    if request.method == 'POST':
        username = request.form['username']
        sxn = request.form['sxn']
        fname = request.form['fname']
        lname = request.form['lname']
        address = request.form['address']
        password = request.form['password']
        cursor.execute('SELECT * FROM CUSTOMER WHERE username = % s', (username, ))
        customer = cursor.fetchone()
        if not customer:
            cursor.execute('INSERT INTO CUSTOMER VALUES (NULL, %s, %s, % s, % s, % s, % s, CURDATE())', (username, password, sxn, fname, lname, address, ))
            db.commit()
            msg = 'Customer created successfully !'
        else:
            msg = 'Customer already exists'
    return render_template('customer_signup.html', msg = msg)

if __name__ == '__main__':
    app.run(debug=True, port=7777)