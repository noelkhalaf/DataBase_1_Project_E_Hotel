from flask import Flask, request, render_template, redirect, url_for, flash, Response
from decimal import Decimal
import secrets
import json
from EHotels import eHotels
from include import *

app = Flask(__name__)
app.secret_key = secrets.token_hex(16)

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/customerSignIn', methods=['GET', 'POST'])
def customerSignIn():
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']

        eHotels.checkConnection()
        if eHotels.getTable(table=customer_t, username=username, password=password):
            flash(f'Login success! Welcome {username}!')
            return redirect(url_for('customerRoomSearch'))
        else:
            flash('Incorrect username or password')

    return render_template('index.html')

@app.route('/employeeSignIn', methods=['GET', 'POST'])
def employeeSignIn():
    if request.method == 'POST':
        employee_id = request.form['employee_id']
        fname = request.form['fname']

        eHotels.checkConnection()
        if eHotels.getTable(table=employee_t, employee_id=employee_id, first_name=fname):
            flash(f'Login success! Welcome {fname}!')
            # return redirect(url_for('employeeRoomSearch'))
        else:
            flash('Incorrect id or first name')

    return render_template('index.html')

@app.route('/customerSignUp', methods=['GET', 'POST'])
def customerSignUp():
    if request.method == 'POST':
        username = request.form['username']
        sxn = request.form['sxn']
        fname = request.form['fname']
        lname = request.form['lname']
        address = request.form['address']
        password = request.form['password']

        eHotels.checkConnection()
        if eHotels.getTable(table=customer_t, username=username):
            flash(f'Customer with username {username} already exists')
        else:
            eHotels.insertCustomer(username, password, sxn, fname, lname, address)
            flash(f'Customer with username {username} created successfully!')
            return redirect(url_for('customerSignIn'))

    return render_template('customerSignUp.html')

@app.route('/customerRoomSearch', methods=['GET'])
def customerRoomSearch():
    start_date = request.form.get('start_date', '')
    end_date = request.form.get('end_date', '')
    room_capacity = request.form.get('room_capacity', '')
    city = request.form.get('city', '')
    hotel_chain = request.form.get('hotel_chain', '')
    category = request.form.get('category', '')
    total_no_rooms = request.form.get('total_no_rooms', '')
    min_price = request.form.get('min_price', '')
    max_price = request.form.get('max_price', '')
    hotel_name = ''
    
    eHotels.checkConnection()
    if request.method == 'GET':     
        list_of_cities = eHotels.getTable('city', table=hotel_t, fetchall=True, distinct=True)
        available_rooms = eHotels.getAvailableRooms(start_date, end_date, room_capacity, city, hotel_chain, category, total_no_rooms, min_price, max_price, hotel_name)
        return render_template('customerRoomSearch.html', list_of_cities=sorted(list_of_cities, key=lambda x: x['city']), available_rooms=available_rooms)

@app.route('/searchRooms', methods=['POST'])
def searchRooms():
    start_date = request.args.get('start_date')
    end_date = request.args.get('end_date')
    room_capacity = request.args.get('room_capacity')
    city = request.args.get('city')
    hotel_chain = request.args.get('hotel_chain')
    category = request.args.get('category')
    total_no_rooms = request.args.get('total_no_rooms')
    min_price = request.args.get('min_price')
    max_price = request.args.get('max_price')
    hotel_name = ''

    eHotels.checkConnection()
    available_rooms = eHotels.getAvailableRooms(start_date, end_date, room_capacity, city, hotel_chain, category, total_no_rooms, min_price, max_price, hotel_name)

    response = json.dumps(available_rooms)
    return Response(response=response, status=200, mimetype='application/json')


@app.route('/availableRooms', methods=['GET'])
def availableRooms():
    start_date = request.args.get('start_date')
    end_date = request.args.get('end_date')
    room_capacity = request.args.get('room_capacity')
    city = request.args.get('city')
    hotel_chain = request.args.get('hotel_chain')
    category = request.args.get('category')
    total_no_rooms = request.args.get('total_no_rooms')
    min_price = request.args.get('min_price')
    max_price = request.args.get('max_price')
    hotel_name = request.args.get('hotel_name')

    eHotels.checkConnection()
    available_rooms = eHotels.getAvailableRooms(start_date, end_date, room_capacity, city, hotel_chain, category, total_no_rooms, min_price, max_price, hotel_name, individually=True)
    
    response = json.dumps(available_rooms, default=lambda x: str(x) if isinstance(x, Decimal) else x)
    return Response(response=response, status=200, mimetype='application/json')

# @app.route('/bookRoom', methods=['POST'])
# def bookRoom():
#     if request.method == 'POST':


if __name__ == '__main__':
    app.run(debug=True, port=7777)