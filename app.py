from flask import *
import mysql.connector
from EHotels import eHotels
from include import *
import os

app = Flask(__name__)

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

        eHotels.checkConnection()
        if eHotels.getTable(table=customer_t, username=username, password=password):
            msg = f'Login success! Welcome {username}!'
            return render_template('index.html', msg = msg)
        else:
            msg = 'Incorrect username or password'
        eHotels.closeCursor()

    return render_template('customer_signin.html', msg = msg)

@app.route('/employeeSignIn', methods=['GET', 'POST'])
def employeeSignIn():
    msg = ''
    if request.method == 'POST':
        employee_id = request.form['employee_id']
        fname = request.form['fname']

        eHotels.checkConnection()
        if eHotels.getTable(table=employee_t, employee_id=employee_id, first_name=fname):
            msg = f'Login success! Welcome {fname}!'
            return render_template('index.html', msg = msg)
        else:
            msg = 'Incorrect id or first name'
        eHotels.closeCursor()

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

        eHotels.checkConnection()
        if eHotels.getTable(table=customer_t, username=username):
            msg = f'Customer with username {username} already exists'
        else:
            eHotels.insertCustomer(sxn, fname, lname, address, username, password)
            msg = f'Customer with username {username} created successfully!'
        eHotels.closeCursor()

    return render_template('customer_signup.html', msg=msg)

@app.route('/viewRooms', methods=['GET', 'POST'])
def viewRooms():
    if request.method == 'POST':
        # start_date = request.form['start_date']
        # end_date = request.form['end_date']
        # room_capacity = request.form['room_capacity']
        # city = request.form['city']
        # hotel_chain = request.form['hotel_chain']
        # category = request.form['category']
        # total_no_rooms = request.form['total_no_rooms']
        # price = request.form['price']
        return redirect(url_for('index)'))
    
    return render_template('view_rooms.html')

if __name__ == '__main__':
    app.run(debug=True, port=7777)