from flask import Flask, request, render_template, redirect, url_for, flash, Response, session
from decimal import Decimal
import secrets
import json
import datetime
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
            return redirect(url_for('adminHome'))
        else:
            flash('Incorrect admin credentials')
    
    return render_template('index.html')

@app.route('/adminHome', methods=['GET'])
def adminHome():
    if request.method == 'GET':
        eHotels.checkConnection()
        employee_list = eHotels.getEmployees()
        customer_list = eHotels.getTable(table=customer_t, fetchall=True)
        room_list = eHotels.getTable(table=room_t, fetchall=True)
        hotel_list = eHotels.getTable(table=hotel_t, fetchall=True)
        chain_list = eHotels.getTable(table=hotel_chain_t, fetchall=True)

        return render_template('admin_Home.html', employee_list=employee_list, customer_list=customer_list, room_list=room_list, hotel_list=hotel_list, chain_list=chain_list)

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
        if not(start_date or end_date or room_capacity or city or hotel_chain or category or total_no_rooms or min_price or max_price or hotel_name):
            available_rooms = eHotels.getAvailableRooms(start_date, end_date, room_capacity, city, hotel_chain, category, total_no_rooms, min_price, max_price, hotel_name, default=True)
        else:
            available_rooms = eHotels.getAvailableRooms(start_date, end_date, room_capacity, city, hotel_chain, category, total_no_rooms, min_price, max_price, hotel_name)
        return render_template('customerRoomSearch.html', list_of_cities=sorted(list_of_cities, key=lambda x: x['city']), available_rooms=available_rooms, max_room_price=max_room_price)

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
        if not(start_date or end_date or room_capacity or city or hotel_chain or category or total_no_rooms or min_price or max_price or hotel_name):
            available_rooms = eHotels.getAvailableRooms(start_date, end_date, room_capacity, city, hotel_chain, category, total_no_rooms, min_price, max_price, hotel_name, default=True)
        else:
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
        bookings = eHotels.getTable(table=booking_t, username=username,fetchall=True)
        return render_template('myBookings.html', bookings=bookings)

@app.route('/roomDetails', methods=['GET'])
def roomDetails():
    hotel_name = request.args.get('hotel_name')
    room_num = request.args.get('room_num')
    
    if not hotel_name or not room_num:
        return  Response(response=json.dumps({'error': 'Invalid input parameters'}), status=400, mimetype='application/json')
    
    try:
        eHotels.checkConnection()
        details = eHotels.getRoomDetails(hotel_name, room_num)
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
            eHotels.archiveBooking(booking_id)
            return Response(response=json.dumps({'message': 'Booking cancellation successful'}), status=200, mimetype='application/json')
    except Exception as e:
        print(e)
        return Response(response=json.dumps({'error': 'Internal server error'}), status=500, mimetype='application/json')


@app.route('/employeeCustomerSearch', methods=['GET', 'POST'])
def employeeCustomerSearch():
    show_rental = request.args.get('show-rentals-bookings', 'Bookings')

    employee_id = session.get('employee_id')
    username = request.form.get('customer_username', '')
    date_placed = request.form.get('placed_date', '')
    start_date = request.form.get('check_in_date', '')
    end_date = request.form.get('check_out_date', '')

    eHotels.checkConnection()
    if show_rental == 'Bookings':
        customerRooms = eHotels.getEmployeeCustomers(employee_id, username, date_placed, start_date, end_date)
    
    return render_template('employeeCustomerSearch.html', customerRooms=customerRooms, show_rental=show_rental)

@app.route('/searchEmployeeCustomers', methods=['GET'])
def searchEmployeeCustomers():
    employee_id = session.get('employee_id')
    username = request.args.get('username')
    date_placed = request.args.get('date_placed')
    check_in_date = request.args.get('check_in_date')
    check_out_date = request.args.get('check_out_date')
    show_rentals_bookings = request.args.get('show_rentals_bookings')
    
    try:
        eHotels.checkConnection()
        if show_rentals_bookings == 'Rentals':
            customerRooms = eHotels.getEmployeeCustomers(employee_id, username, date_placed, check_in_date, check_out_date, rentals=True)
        elif show_rentals_bookings == 'Bookings':
            customerRooms = eHotels.getEmployeeCustomers(employee_id, username, date_placed, check_in_date, check_out_date)
        response = json.dumps(customerRooms, default=lambda x: str(x) if isinstance(x, Decimal) else x.strftime('%Y-%m-%d') if isinstance(x, datetime.date) else str(x))
        return Response(response=response, status=200, mimetype='application/json')
    except Exception as e:
        print(e)
        return Response(response=json.dumps({'error': 'Internal server error'}), status=500, mimetype='application/json')

@app.route('/checkIn', methods=['POST'])
def checkIn():
    employee_id = session.get('employee_id')
    booking_id = request.form.get('booking-id-hidden')
    print(employee_id)
    print(booking_id)

    if not(employee_id or booking_id):
        flash('Invalid input parameters')

    try:
        eHotels.checkConnection()
        if eHotels.checkInBooking(employee_id, booking_id):
            flash('Check In Succesful!')
            return redirect(url_for('employeeCustomerSearch'))
    except Exception as e:
        print(e)
        flash('Internal server error')

@app.route('/checkOut', methods=['POST'])
def checkOut():
    employee_id = session.get('employee_id')
    rental_id = request.args.get('rental_id')

    print(employee_id)
    print(rental_id)

    if not(employee_id or rental_id):
        return  Response(response=json.dumps({'error': 'Invalid input parameters'}), status=400, mimetype='application/json')
    
    try:
        eHotels.checkConnection()
        if eHotels.checkOut(employee_id, rental_id): 
            return Response(response=json.dumps({'message': 'Check Out Successful!'}), status=200, mimetype='application/json')
    except Exception as e:
        print(e)
        return Response(response=json.dumps({'error': 'Internal server error'}), status=500, mimetype='application/json')



@app.route('/employeeRoomSearch', methods=['GET', 'POST'])
def employeeRoomSearch():
    employee_id = session.get('employee_id')
    check_out_date = request.form.get('check_out_date', '')
    min_price = request.form.get('min_price', '')
    max_price = request.form.get('max_price', '')
    room_capacity = request.form.get('room_capacity', '')
    view_type = request.form.get('view_type', '')

    eHotels.checkConnection()
    available_rooms = eHotels.getEmployeeRooms(employee_id, check_out_date, room_capacity, view_type, min_price, max_price)
    max_room_price = eHotels.getTable('MAX(price)', table=room_t)
    return render_template('employeeRoomSearch.html', available_rooms=available_rooms, max_room_price=max_room_price)
    
@app.route('/searchEmployeeRooms', methods=['GET'])
def searchEmployeeRooms():
    employee_id = session.get('employee_id')
    check_out_date = request.args.get('check_out_date')
    room_capacity = request.args.get('room_capacity')
    view_type = request.args.get('view_type')
    min_price = request.args.get('min_price')
    max_price = request.args.get('max_price')
    
    try:
        eHotels.checkConnection()
        available_rooms = eHotels.getEmployeeRooms(employee_id, check_out_date, room_capacity, view_type, min_price, max_price)
        response = json.dumps(available_rooms, default=lambda x: str(x) if isinstance(x, Decimal) else x)
        return Response(response=response, status=200, mimetype='application/json')
    except Exception as e:
        print(e)
        return Response(response=json.dumps({'error': 'Internal server error'}), status=500, mimetype='application/json')


@app.route('/rentRoomNoBooking', methods=['POST'])
def rentRoomNoBooking():
    employee_id = session.get('employee_id')
    username = request.form.get('customer_username')
    check_out_date = request.form.get('check_out_date_hidden')
    chain_name = request.form.get('chain_name_hidden')
    hotel_name = request.form.get('hotel_name_hidden')
    room_num = request.form.get('room_num_hidden')
    capacity = request.form.get('capacity_hidden')
    rental_rate = request.form.get('price_hidden')

    try:
        eHotels.checkConnection()
        if eHotels.checkInNoBooking(employee_id, username, chain_name, hotel_name, room_num, capacity, rental_rate, check_out_date):
            flash(f'Rental of room number: {room_num} at {hotel_name} is successful')
            return redirect(url_for('employeeRoomSearch'))
    except Exception as e:
        print(e)
    
@app.route('/submitEmployee', methods=['POST'])
def submitEmployee():
    modal_action = request.form.get('modal_action')

    chain_name = request.form.get('employee_chain_name')
    hotel_name = request.form.get('employee_hotel_name')
    fname = request.form.get('employee_fname')
    lname = request.form.get('employee_lname')
    sxn = request.form.get('employee_sxn')
    address = request.form.get('employee_address', '')
    positions = request.form.get('employee_positions')

    try:
        if modal_action == 'create':
            eHotels.checkConnection()
            msg, _, = eHotels.insertEmployee(chain_name, hotel_name, fname, lname, sxn, address, positions)
        elif modal_action == 'update':
            employee_id = request.form.get('employee-id-hidden')
            msg, _ = eHotels.updateEmployee(employee_id, chain_name, hotel_name, fname, lname, sxn, address=address, positions=positions)
        flash(msg)
    except Exception as e:
        print(e)
    return redirect(url_for('adminHome'))

@app.route('/submitCustomer', methods=['POST'])
def submitCustomer():
    modal_action = request.form.get('modal_action')

    username = request.form.get('customer_username')
    password = request.form.get('customer_password')
    fname = request.form.get('customer_fname')
    lname = request.form.get('customer_lname')
    sxn = request.form.get('customer_sxn')
    address = request.form.get('customer_address')

    try:
        if modal_action == 'create':
            eHotels.checkConnection()
            msg, _ = eHotels.insertCustomer(username, password, fname, lname, sxn, address)
        elif modal_action == 'update':
            customer_id = request.form.get('customer-id-hidden')
            msg, _ = eHotels.updateCustomer(customer_id, username, password, fname, lname, sxn, address)
        flash(msg)
    except Exception as e:
        print(e)
    return redirect(url_for('adminHome'))

@app.route('/submitRoom', methods=['POST'])
def submitRoom():
    modal_action = request.form.get('modal_action')

    hotel_name = request.form.get('room_hotel_name')
    room_num = request.form.get('room_number')
    price = request.form.get('room_price')
    capacity = request.form.get('room_capacity')
    view_type = request.form.get('room_view_type')
    can_extend = request.form.get('room_extend', '0')
    has_problems = request.form.get('room_problems', '0')
    available =  request.form.get('room_available', '0')
    amenities = request.form.get('room_amenities')

    try:
        if modal_action == 'create':
            eHotels.checkConnection()
            msg, _ = eHotels.insertRoom(hotel_name, room_num, price, capacity, view_type, can_extend, has_problems, available, amenities)
        elif modal_action == 'update':
            room_id = request.form.get('room-id-hidden')
            old_hotel_name = request.form.get('old-hotel-name')
            old_room_num = request.form.get('old-room-num')
            msg, _ = eHotels.updateRoom(room_id, hotel_name, room_num, price, capacity, view_type, can_extend, has_problems, available, old_hotel_name, old_room_num, amenities)
        flash(msg)
    except Exception as e:
        print(e)
    return redirect(url_for('adminHome'))

@app.route('/createHotel', methods=['POST'])
def createHotel():
    hotel_name = request.form.get('hotel_name')
    chain_name = request.form.get('hotel_chain_name')
    category = request.form.get('hotel_category')
    city = request.form.get('hotel_city')
    hotel_address = request.form.get('hotel_address', '')
    email = request.form.get('hotel_eaddress', '')
    phone_number = request.form.get('hotel_phone_number')

    mgr_fname = request.form.get('manager_fname')
    mgr_lname = request.form.get('manager_lname')
    mgr_sxn = request.form.get('manager_sxn')
    mgr_address = request.form.get('manager_address')

    try:
        eHotels.checkConnection()
        msg, _ = eHotels.insertHotel(hotel_name, chain_name, city, mgr_fname, mgr_lname, category, hotel_address, email, phone_number, mgr_sxn, mgr_address)
        flash(msg)
    except Exception as e:
        print(e)
    return redirect(url_for('adminHome'))

@app.route('/updateHotel', methods=['POST'])
def updateHotel():
    hotel_name = request.form.get('hotel_update_name')
    chain_name = request.form.get('hotel_update_chain_name')
    category = request.form.get('hotel_update_category')
    city = request.form.get('hotel_update_city')
    hotel_address = request.form.get('hotel_update_address', '')
    email = request.form.get('hotel_update_eaddress', '')
    phone_number = request.form.get('hotel_update_phone_number')
    mgr_id = request.form.get('hotel_update_manager_id')

    hotel_id = request.form.get('hotel-id-hidden')

    try:
        msg, _ = eHotels.updateHotel(hotel_id, hotel_name, chain_name, mgr_id, category, city, hotel_address, email, phone_number)
        flash(msg)
    except Exception as e:
        print(e)
    return redirect(url_for('adminHome'))

@app.route('/submitHotelChain', methods=['POST'])
def submitHotelChain():
    modal_action = request.form.get('modal_action')

    chain_name = request.form.get('chain_name_input')
    email = request.form.get('hotel_chain_eaddress', '')
    phone_number = request.form.get('hotel_chain_phone_number', '')

    try:
        if modal_action == 'create':
            eHotels.checkConnection()
            msg, _, = eHotels.insertHotelChain(chain_name, email, phone_number)
        elif modal_action == 'update':
            chain_id = request.form.get('chain-id-hidden')
            msg, _ = eHotels.updateHotelChain(chain_id, chain_name, email, phone_number)
        flash(msg)
    except Exception as e:
        print(e)
    return redirect(url_for('adminHome'))

@app.route('/deleteEmployee', methods=['DELETE'])
def deleteEmployee():
    employee_id = request.args.get('employee_id')

    if not employee_id:
        return  Response(response=json.dumps({'error': 'Invalid input parameters'}), status=400, mimetype='application/json')
    
    try:
        eHotels.checkConnection()
        msg, passed = eHotels.deleteEmployee(employee_id)
        flash(msg) # Doesn't work
        if passed:
            return Response(response=json.dumps({'message': 'Employee deletion successful'}), status=200, mimetype='application/json')
    except Exception as e:
        print(e)
        return Response(response=json.dumps({'error': 'Internal server error'}), status=500, mimetype='application/json')
    
@app.route('/deleteCustomer', methods=['DELETE'])
def deleteCustomer():
    username = request.args.get('username')

    if not username:
        return  Response(response=json.dumps({'error': 'Invalid input parameters'}), status=400, mimetype='application/json')
    
    try:
        eHotels.checkConnection()
        if eHotels.deleteCustomer(username):
            return Response(response=json.dumps({'message': 'Customer deletion successful'}), status=200, mimetype='application/json')
    except Exception as e:
        print(e)
        return Response(response=json.dumps({'error': 'Internal server error'}), status=500, mimetype='application/json')
    
@app.route('/deleteRoom', methods=['DELETE'])
def deleteRoom():
    hotel_name = request.args.get('hotel_name')
    room_num = request.args.get('room_num')

    if not hotel_name or not room_num:
        return  Response(response=json.dumps({'error': 'Invalid input parameters'}), status=400, mimetype='application/json')
    
    try:
        eHotels.checkConnection()
        if eHotels.deleteRoom(hotel_name, room_num):
            return Response(response=json.dumps({'message': 'Room deletion successful'}), status=200, mimetype='application/json')
    except Exception as e:
        print(e)
        return Response(response=json.dumps({'error': 'Internal server error'}), status=500, mimetype='application/json')
    
@app.route('/deleteHotel', methods=['DELETE'])
def deleteHotel():
    hotel_name = request.args.get('hotel_name')

    if not hotel_name:
        return  Response(response=json.dumps({'error': 'Invalid input parameters'}), status=400, mimetype='application/json')
    
    try:
        eHotels.checkConnection()
        if eHotels.deleteHotel(hotel_name):
            return Response(response=json.dumps({'message': 'Hotel deletion successful'}), status=200, mimetype='application/json')
    except Exception as e:
        print(e)
        return Response(response=json.dumps({'error': 'Internal server error'}), status=500, mimetype='application/json')

@app.route('/deleteHotelChain', methods=['DELETE'])
def deleteHotelChain():
    chain_name = request.args.get('chain_name')

    if not chain_name:
        return  Response(response=json.dumps({'error': 'Invalid input parameters'}), status=400, mimetype='application/json')
    
    try:
        eHotels.checkConnection()
        if eHotels.deleteHotelChain(chain_name):
            return Response(response=json.dumps({'message': 'Hotel Chain deletion successful'}), status=200, mimetype='application/json')
    except Exception as e:
        print(e)
        return Response(response=json.dumps({'error': 'Internal server error'}), status=500, mimetype='application/json')

if __name__ == '__main__':
    app.run(debug=True, port=7777)