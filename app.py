from flask import Flask, request, render_template, redirect, url_for, flash
import secrets
from EHotels import eHotels
from include import *

app = Flask(__name__)
app.secret_key = secrets.token_hex(16)

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/customerSignIn', methods=['GET', 'POST'])
def customerSignIn():
    msg = ''
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']

        eHotels.checkConnection()
        if eHotels.getTable(table=customer_t, username=username, password=password):
            flash(f'Login success! Welcome {username}!')
            return redirect(url_for('customerRoomSearch'))
        else:
            msg = 'Incorrect username or password'

    return render_template('index.html', msg = msg)

@app.route('/employeeSignIn', methods=['GET', 'POST'])
def employeeSignIn():
    msg = ''
    if request.method == 'POST':
        employee_id = request.form['employee_id']
        fname = request.form['fname']

        eHotels.checkConnection()
        if eHotels.getTable(table=employee_t, employee_id=employee_id, first_name=fname):
            msg = f'Login success! Welcome {fname}!'
            # return redirect(url_for('employeeRoomSearch'))
        else:
            msg = 'Incorrect id or first name'

    return render_template('index.html', msg = msg)

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
            flash(f'Customer with username {username} created successfully!')
            return redirect(url_for('customerSignIn'))

    return render_template('customerSignUp.html', msg=msg)

@app.route('/customerRoomSearch', methods=['GET', 'POST'])
def customerRoomSearch():
    eHotels.checkConnection()
    list_of_cities = eHotels.getTable('city', table=hotel_t, fetchall=True)
    if request.method == 'POST':
        start_date = request.form['start_date']
        # end_date = request.form['end_date']
        # room_capacity = request.form['room_capacity']
        # city = request.form['city']
        # hotel_chain = request.form['hotel_chain']
        # category = request.form['category']
        # total_no_rooms = request.form['total_no_rooms']
        # price = request.form['price']
        # return redirect(url_for('index)'))

    return render_template('customerRoomSearch.html', list_of_cities=sorted(list_of_cities, key=lambda x: x['city']))

if __name__ == '__main__':
    app.run(debug=True, port=7777)