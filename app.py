from flask import Flask, request, render_template, redirect, url_for, flash, Response, session, jsonify, make_response
from decimal import Decimal
import secrets
import json
from EHotels import eHotels
from include import *

app = Flask(__name__)
app.secret_key = secrets.token_hex(16)

@app.before_request
def clearSession():
    if request.endpoint == 'index':
        session.clear()

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/adminSignIn', methods=['GET', 'POST'])
def adminSignIn():
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']

        eHotels.checkConnection()
        if username == 'admin' and password == 'admin':
            return render_template('admin_Home.html')
        else:
            flash('Incorrect username or password')
    
    return render_template('index.html')

@app.route('/customerSignIn', methods=['GET', 'POST'])
def customerSignIn():
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']

        eHotels.checkConnection()
        if eHotels.getTable(table=customer_t, username=username, password=password):
            session['username'] = username
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
            session['employee_id'] = employee_id
            return redirect(url_for('employeeRoomSearch'))
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
            eHotels.insertCustomer(username, password, fname, lname, sxn, address)
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
        max_room_price = eHotels.getTable('MAX(price)', table=room_t)
        available_rooms = eHotels.getAvailableRooms(start_date, end_date, room_capacity, city, hotel_chain, category, total_no_rooms, min_price, max_price, hotel_name)
        return render_template('customerRoomSearch.html', list_of_cities=sorted(list_of_cities, key=lambda x: x['city']), available_rooms=available_rooms, max_room_price=max_room_price )

@app.route('/searchRooms', methods=['GET'])
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

    try: 
        eHotels.checkConnection()
        available_rooms = eHotels.getAvailableRooms(start_date, end_date, room_capacity, city, hotel_chain, category, total_no_rooms, min_price, max_price, hotel_name)
        response = json.dumps(available_rooms)
        return Response(response=response, status=200, mimetype='application/json')
    except Exception as e:
        print(e)
        return Response(response=json.dumps({'error': 'Internal server error'}), status=500, mimetype='application/json')

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
    
    try:
        eHotels.checkConnection()
        available_rooms = eHotels.getAvailableRooms(start_date, end_date, room_capacity, city, hotel_chain, category, total_no_rooms, min_price, max_price, hotel_name, individually=True)
        response = json.dumps(available_rooms, default=lambda x: str(x) if isinstance(x, Decimal) else x)
        return Response(response=response, status=200, mimetype='application/json')
    except Exception as e:
        print(e)
        return Response(response=json.dumps({'error': 'Internal server error'}), status=500, mimetype='application/json')


@app.route('/bookRoom', methods=['POST'])
def bookRoom():
    username = session.get('username')
    chain_name = request.args.get('chain_name')
    hotel_name = request.args.get('hotel_name')
    room_num = request.args.get('room_num')
    capacity = request.args.get('capacity')
    start_date = request.args.get('start_date')
    end_date = request.args.get('end_date')

    if not username or not chain_name or not hotel_name or not room_num or not capacity or not start_date or not end_date:
        return Response(response=json.dumps({'error': 'Invalid input parameters'}), status=400, mimetype='application/json')
    
    try:
        eHotels.checkConnection()
        if eHotels.insertBooking(username, chain_name, hotel_name, room_num, capacity, start_date, end_date):
            return Response(response=json.dumps({'message': 'Booking successful'}), status=200, mimetype='application/json')
    except Exception as e:
        print(e)
        return Response(response=json.dumps({'error': 'Internal server error'}), status=500, mimetype='application/json')

@app.route('/myBookings', methods=['GET'])
def myBookings():
    username = session.get('username')
    if username:
        eHotels.checkConnection()
        bookings = eHotels.getTable(table=booking_t, fetchall=True)
        print(bookings)
        return render_template('myBookings.html', bookings=bookings)

@app.route('/myBookingDetails', methods=['GET'])
def myBookingDetails():
    hotel_name = request.args.get('hotel_name')
    room_num = request.args.get('room_num')
    
    if not hotel_name or not room_num:
        return  Response(response=json.dumps({'error': 'Invalid input parameters'}), status=400, mimetype='application/json')
    
    try:
        eHotels.checkConnection()
        details = eHotels.getTable(table=room_t, room_num=room_num, hotel_name=hotel_name)
        response = json.dumps(details, default=lambda x: str(x) if isinstance(x, Decimal) else x)
        return Response(response=response, status=200, mimetype='application/json')
    except Exception as e:
        print(e)
        return Response(response=json.dumps({'error': 'Internal server error'}), status=500, mimetype='application/json')
    
@app.route('/cancelBooking', methods=['DELETE'])
def cancelBooking():
    booking_id = request.args.get('booking_id')

    if not booking_id:
        return  Response(response=json.dumps({'error': 'Invalid input parameters'}), status=400, mimetype='application/json')
    
    try:
        eHotels.checkConnection()
        if eHotels.deleteBooking(booking_id):
            return Response(response=json.dumps({'message': 'Booking cancellation successful'}), status=200, mimetype='application/json')
    except Exception as e:
        print(e)
        return Response(response=json.dumps({'error': 'Internal server error'}), status=500, mimetype='application/json')


@app.route('/employeeCustomerSearch', methods=['GET'])
def employeeCustomerSearch():
    return render_template('employeeCustomerSearch.html')

@app.route('/employeeRoomSearch', methods=['GET'])
def employeeRoomSearch():
    employee_id = session.get('employee_id')
    check_out_date = request.form.get('check_out_date', '')
    min_price = request.form.get('min_price', '')
    max_price = request.form.get('max_price', '')
    room_capacity = request.form.get('room_capacity', '')
    view_type = request.form.get('view_type', '')

    eHotels.checkConnection()
    if request.method == 'GET':
        available_rooms = eHotels.getEmployeeRooms(employee_id, check_out_date, room_capacity, view_type, min_price, max_price)
        print(available_rooms)
        max_room_price = eHotels.getTable('MAX(price)', table=room_t)
        return render_template('employeeRoomSearch.html', available_rooms=available_rooms, max_room_price=max_room_price)

if __name__ == '__main__':
    app.run(debug=True, port=7777)