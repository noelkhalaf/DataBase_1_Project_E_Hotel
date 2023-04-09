import mysql.connector
import random
import string
from include import *
from datetime import date

host = 'localhost'
user = 'root'           # Modify this field
passwd = 'password'     # Modify this field
database = 'e_hotels'

class EHotels:
    def __init__(self, host, user, passwd, database):
        self.host = host
        self.user = user
        self.passwd = passwd
        self.database = database
        self.connect()
        self.connectDB()

    def connect(self):
        self.db = mysql.connector.connect(
                host=self.host,
                user=self.user,
                passwd=self.passwd,
        )
        self.resetCursor()

    def connectDB(self):
        self.execute("CREATE DATABASE IF NOT EXISTS e_hotels")
        self.execute("USE e_hotels")
        self.db = mysql.connector.connect(
                host=self.host,
                user=self.user,
                passwd=self.passwd,
                database=self.database
        )
        self.resetCursor()

    def checkConnection(self):
        if not self.db.is_connected():
            self.db.connect()
        self.resetCursor()

    def resetCursor(self):
        self.cursor = self.db.cursor(buffered=True, dictionary=True)

    def execute(self, query):
        self.cursor.execute(query)
        self.commit()

    def commit(self):
        self.db.commit()

    def fetchone(self):
        return self.cursor.fetchone()

    def fetchall(self):
        return self.cursor.fetchall()

    def getTable(self, *args, **kwargs):
        selected = '*' if not args else ','.join(list(filter(None, args)))
        conditions = self.getSimpleConditions(kwargs.copy())
        if conditions: conditions = f'WHERE {conditions}'
        if kwargs.get('distinct'):
            query = f'SELECT DISTINCT {selected} FROM {kwargs.get("table")} {conditions}'
        else:
            query = f'SELECT {selected} FROM {kwargs.get("table")} {conditions}'
        self.execute(query)
        if kwargs.get('fetchall'):
            return self.fetchall()
        else:
            return self.fetchone()

    def getSimpleConditions(self, dict, var=''):
        dict.pop('table', None)
        dict.pop('fetchall', None)
        dict.pop('distinct', None)
        if not dict: return ''
        conditions_pairs = []
        for attribute, value in dict.items():
            if value:
                if var:
                    conditions_pairs.append(f'{var}.{attribute} = \"{value}\"')
                else:
                    conditions_pairs.append(f'{attribute} = \"{value}\"')
        conditions = self.joinConditions(conditions_pairs)
        return conditions

    def joinConditions(self, conditions_lst):
        conditions = ' AND '.join(list(filter(None, conditions_lst)))
        return conditions

    def getAvailableRooms(self, start_date, end_date, room_capacity, city, hotel_chain, category, total_no_rooms, min_price, max_price, hotel_name, individually=False):
        dict_simple = {
            'r.capacity': room_capacity,
            'h.city': city,
            'hc.chain_name': hotel_chain,
            'h.category': category,
            'h.num_rooms': total_no_rooms,
            'h.hotel_name': hotel_name,
        }
        
        simple_conditions = self.getSimpleConditions(dict_simple)
        price_condition = self.getPriceCondition(min_price, max_price)
        date_conditions = self.getDateConditions(start_date, end_date)
        conditions = self.joinConditions([simple_conditions, price_condition, date_conditions])
        if conditions: conditions = f'WHERE {conditions}'

        if individually:
            query1 = f"""
                SELECT r.room_num, r.capacity, r.view_type, r.price
                FROM HOTEL_CHAIN hc
                JOIN HOTEL h ON hc.chain_name = h.chain_name
                JOIN ROOM r ON h.hotel_name = r.hotel_name
                {conditions}
            """
            self.execute(query1)
            results_individual = self.fetchall()
            if hotel_name:
                query2 = f"""
                    SELECT ra.room_num, ra.amenity
                    FROM ROOM_AMENITY ra
                    JOIN HOTEL ho ON ra.hotel_name = ho.hotel_name
                    WHERE ho.hotel_name = "{hotel_name}"
                    AND ra.room_num IN (
                        SELECT r.room_num
                        FROM HOTEL_CHAIN hc
                        JOIN HOTEL h ON hc.chain_name = h.chain_name
                        JOIN ROOM r ON h.hotel_name = r.hotel_name
                        {conditions}
                    )
                """
                self.execute(query2)
                results_amenities = self.fetchall()
                results_appended = self.appendRoomAmenities(results_individual, results_amenities)
                return results_appended
            return results_individual
        
        query = f"""
            SELECT h.city, hc.chain_name, h.hotel_name, h.category, COUNT(r.room_num) AS available_rooms
            FROM HOTEL_CHAIN hc
            JOIN HOTEL h ON hc.chain_name = h.chain_name
            JOIN ROOM r ON h.hotel_name = r.hotel_name
            {conditions}
            GROUP BY h.city, hc.chain_name, h.hotel_name, h.category
        """
        self.execute(query)
        results = self.fetchall()
        return results

    def getEmployeeRooms(self, employee_id, end_date, room_capacity, view_type, min_price, max_price, start_date=str(date.today())):
        hotel_name = self.getTable('hotel_name', table=employee_t, employee_id=employee_id)
        dict_simple = {
            'roo.hotel_name': hotel_name,
            'roo.capacity': room_capacity,
            'roo.view_type': view_type,
        }

        simple_conditions = self.getSimpleConditions(dict_simple, var='roo')
        wrapped_simple_conditions = f"""
            (vc.hotel_name, vc.room_num) IN (
                SELECT roo.hotel_name, roo.room_num
                FROM ROOM roo
                WHERE {simple_conditions}
            )
        """
        price_condition = self.getPriceCondition(min_price, max_price)
        date_conditions = self.getDateConditions(start_date, end_date)
        conditions = self.joinConditions([wrapped_simple_conditions, price_condition, date_conditions])
        if conditions: conditions = f'WHERE {conditions}'

        query = f"""
            SELECT vc.*
            FROM view_capacity vc
            {conditions}
        """
        self.execute(query)
        results = self.fetchall()
        return results

    def getPriceCondition(self, low, high, hvar='h', rvar='r'):
        condition = ''
        if low and high:
            condition = f"""
                ({hvar}.hotel_name, {rvar}.room_num) IN (
                    SELECT ro.hotel_name, ro.room_num
                    FROM ROOM ro
                    WHERE ro.price BETWEEN {low} AND {high}
                )
            """
        elif low and not high:
            condition = f"""
                ({hvar}.hotel_name, {rvar}.room_num) IN (
                    SELECT ro.hotel_name, ro.room_num
                    FROM ROOM ro
                    WHERE ro.price >= {low}
                )
            """
        elif not low and high:
            condition = f"""
                ({hvar}.hotel_name, {rvar}.room_num) IN (
                    SELECT ro.hotel_name, ro.room_num
                    FROM ROOM ro
                    WHERE ro.price <= {high}
                )
            """
        return condition

    def getDateConditions(self, start_date, end_date, hvar='h', rvar='r'):
        condition = ''
        if start_date and end_date:
            condition = f"""
                ({hvar}.hotel_name, {rvar}.room_num) NOT IN (
                    SELECT re.hotel_name, re.room_num
                    FROM RENTAL re
                    WHERE "{start_date}" < re.check_out_date
                    UNION
                    SELECT bo.hotel_name, bo.room_num
                    FROM BOOKING bo
                    WHERE bo.exp_check_in_date <= "{start_date}" AND "{start_date}" < bo.exp_check_out_date
                    OR bo.exp_check_in_date < "{end_date}" AND "{end_date}" <= bo.exp_check_out_date
                    OR "{start_date}" <= bo.exp_check_in_date AND bo.exp_check_in_date < "{end_date}"
                    OR "{start_date}" < bo.exp_check_out_date AND bo.exp_check_out_date <= "{end_date}"
                )
            """
        elif start_date and not end_date:
            condition = f"""
                ({hvar}.hotel_name, {rvar}.room_num) NOT IN (
                    SELECT re.hotel_name, re.room_num
                    FROM RENTAL re
                    WHERE "{start_date}" < re.check_out_date
                    UNION
                    SELECT bo.hotel_name, bo.room_num
                    FROM BOOKING bo
                    WHERE bo.exp_check_in_date <= "{start_date}" AND "{start_date}" < bo.exp_check_out_date
                )
            """
        elif not start_date and end_date:
            condition = f"""
                ({hvar}.hotel_name, {rvar}.room_num) NOT IN (
                    SELECT re.hotel_name, re.room_num
                    FROM RENTAL re
                    WHERE "{end_date}" <= re.check_out_date
                    UNION
                    SELECT bo.hotel_name, bo.room_num
                    FROM BOOKING bo
                    WHERE bo.exp_check_in_date < "{end_date}" AND "{end_date}" <= bo.exp_check_out_date
                )
            """
        return condition

    def appendRoomAmenities(self, available_rooms, room_amenities):
        for room_a in available_rooms:
            amenities = []
            for room_b in room_amenities:
                if room_a['room_num'] == room_b['room_num']:
                    amenities.append(room_b['amenity'])
            room_a['amenities'] = amenities
        return available_rooms

### INSERTS ###

    def insertHotelChain(self, chain_name, email='', phone_number=''):
        result_hc = self.getTable(table=hotel_chain_t, chain_name=chain_name)
        if result_hc is not None:
            print(f'Hotel chain {chain_name} already exists')
            return
        try:
            self.cursor.execute('INSERT INTO HOTEL_CHAIN VALUES (%s, 0, %s, %s)', (chain_name, email, phone_number, ))
        except Exception as e:
            print('Error:', e)
        else:
            return chain_name

    def insertCentralOffice(self, chain_name, address):
        result_hc = self.getTable(table=hotel_chain_t, chain_name=chain_name)
        if result_hc is None:
            print(f'Chain name {chain_name} does not exist')
            return
        result_co = self.getTable(table=central_office_t, chain_name=chain_name, address=address)
        if result_co is not None:
            print(f'Central office of hotel chain {chain_name} at {address} already exists')
            return
        try:
            self.cursor.execute('INSERT INTO CENTRAL_OFFICE VALUES (%s, %s)', (chain_name, address, ))
        except Exception as e:
            print('Error:', e)
        else:
            return chain_name, address

    def insertCustomer(self, username, password, fname, lname, sxn, address):
        result_c = self.getTable(table=customer_t, username=username)
        if result_c is not None:
            print(f'The username {username} is already taken')
            return
        try:
            self.cursor.execute('INSERT INTO CUSTOMER VALUES (%s, %s, %s, %s, %s, %s, CURDATE())', (username, password, fname, lname, sxn, address, ))
        except Exception as e:
            print('Error:', e)
        else:
            return username

    def insertEmployee(self, chain_name, hotel_name, fname, lname, sxn, address=''):
        result_hc = self.getTable(table=hotel_chain_t, chain_name=chain_name)
        if result_hc is None:
            print(f'Hotel chain {chain_name} does not exist')
            return
        chain_name_h, result_h = self.getTable('chain_name', 'hotel_name', table=hotel_t, hotel_name=hotel_name)
        if result_h is None:
            print(f'Hotel name {hotel_name} does not exist')
            return
        if chain_name != chain_name_h:
            print(f'Hotel {hotel_name} belongs to chain {chain_name_h} not {chain_name}')
            return
        result_e = self.getTable(table=employee_t, sxn=sxn)
        if result_e is not None:
            print(f'Employee with sxn {sxn} already exists')
            return
        employee_id = self.genEmployeeKey()
        try:
            self.cursor.execute('INSERT INTO EMPLOYEE VALUES (%s, %s, %s, %s, %s, %s, %s)', (employee_id, chain_name, fname, lname, sxn, address, hotel_name, ))
        except Exception as e:
            print('Error:', e)
        else:
            return employee_id

    def insertHotel(self, hotel_name, chain_name, city, mgr_fname, mgr_lname, category='', hotel_address='', email='', phone_number='', mgr_sxn='', mgr_address=''):
        result_hc = self.getTable(table=hotel_chain_t, chain_name=chain_name)
        if result_hc is None:
            print(f'Chain name {chain_name} does not exist')
            return
        result_h = self.getTable(table=hotel_t, hotel_name=hotel_name)
        if result_h is not None:
            print(f'Hotel {hotel_name} under hotel chain {chain_name} already exists')
            return
        manager_id = self.insertEmployee(hotel_name, mgr_fname, mgr_lname, mgr_sxn, mgr_address)
        try:
            self.cursor.execute('INSERT INTO HOTEL VALUES (%s, %s, %s, %s, 0, %s, %s, %s, %s)', (hotel_name, chain_name, manager_id, category, city, hotel_address, email, phone_number, ))
        except Exception as e:
            print('Error:', e)
        else:
            return hotel_name, manager_id

    def insertEmployeePosition(self, employee_id, position):
        result_e = self.getTable(table=employee_t, employee_id=employee_id)
        if result_e is None:
            print(f'Employee with id {employee_id} does not exist')
            return
        result_ep = self.getTable(table=employee_pos_t, employee_id=employee_id, position=position)
        if result_ep is not None:
            print(f'Employee {employee_id} already has position {position}')
            return
        try:
            self.cursor.execute('INSERT INTO EMPLOYEE_POSITION VALUES (%s, %s)', (employee_id, position, ))
        except Exception as e:
            print('Error:', e)
        else:
            return employee_id, position

    def insertRoom(self, hotel_name, room_num, price, capacity, view_type, can_extend, has_problems, available):
        result_h = self.getTable(table=hotel_t, hotel_name=hotel_name)
        if result_h is None:
            print(f'Hotel name {hotel_name} does not exist')
            return
        result_r = self.getTable(table=room_t, hotel_name=hotel_name, room_num=room_num)
        if result_r is not None:
            print(f'Hotel {hotel_name} already has room number {room_num}')
            return
        try:
            self.cursor.execute('INSERT INTO ROOM VALUES (%s, %s, %s, %s, %s, %s, %s, %s)', (hotel_name, room_num, price, capacity, view_type, can_extend, has_problems, available, ))
        except Exception as e:
            print('Error:', e)
        else:
            return hotel_name, room_num

    def insertRoomAmenity(self, hotel_name, room_num, amenity):
        result_h = self.getTable(table=hotel_t, hotel_name=hotel_name)
        if result_h is None:
            print(f'Hotel name {hotel_name} does not exist')
            return
        result_r = self.getTable(table=room_t, hotel_name=hotel_name, room_num=room_num)
        if result_r is None:
            print(f'Hotel {hotel_name} does not have a room number {room_num}')
            return
        result_ra = self.getTable(table=room_amenity_t, hotel_name=hotel_name, room_num=room_num, amenity=amenity)
        if result_ra is not None:
            print(f'Room {room_num} in hotel {hotel_name} already includes {amenity} amenity')
            return
        try:
            self.cursor.execute('INSERT INTO ROOM_AMENITY VALUES (%s, %s, %s)', (hotel_name, room_num, amenity, ))
        except Exception as e:
            print('Error:', e)
        else:
            return hotel_name, room_num, amenity

    def insertBooking(self, username, chain_name, hotel_name, room_num, capacity, exp_check_in_date, exp_check_out_date):
        result_c = self.getTable(table=customer_t, username=username)
        if result_c is None:
            print(f'The username {username} does not exist')
            return
        result_hc = self.getTable(table=hotel_chain_t, chain_name=chain_name)
        if result_hc is None:
            print(f'Chain name {chain_name} does not exist')
            return
        result_h = self.getTable(table=hotel_t, hotel_name=hotel_name)
        if result_h is None:
            print(f'Hotel name {hotel_name} does not exist')
            return
        result_r = self.getTable(table=room_t, hotel_name=hotel_name, room_num=room_num)
        if result_r is None:
            print(f'Room number {room_num} does not exist in hotel {hotel_name}')
            return
        booking_id = self.genBookingKey()
        try:
            self.cursor.execute('INSERT INTO BOOKING VALUES (%s, %s, %s, %s, %s, %s, CURDATE(), %s, %s)', (booking_id, username, chain_name, hotel_name, room_num, capacity, exp_check_in_date, exp_check_out_date, ))
        except Exception as e:
            print('Error:', e)
        else:
            return booking_id
        
    def insertBookingArchive(self, booking_id):
        result_b = self.getTable(table=booking_t, booking_id=booking_id)
        if result_b is None:
            print(f'Booking with id {booking_id} does not exist')
            return
        result_ba = self.getTable(table=booking_arch_t, booking_id=booking_id)
        if result_ba is not None:
            print(f'Booking archive with id {booking_id} already exists')
            return
        try:
            self.cursor.execute('INSERT INTO BOOKING_ARCHIVE VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)', (booking_id, result_b[1], result_b[2], result_b[3], result_b[4], result_b[5], result_b[6], result_b[7], ))
        except Exception as e:
            print('Error:', e)
        else:
            return booking_id

    def insertRental(self, username, chain_name, hotel_name, room_num, capacity, rental_rate, check_in_date, check_out_date, check_in_e_sxn, additional_charges='0'):
        result_c = self.getTable(table=customer_t, username=username)
        if result_c is None:
            print(f'The username {username} does not exist')
            return
        result_hc = self.getTable(table=hotel_chain_t, chain_name=chain_name)
        if result_hc is None:
            print(f'Chain name {chain_name} does not exist')
            return
        chain_name_h, result_h = self.getTable('chain_name', 'hotel_name', table=hotel_t, hotel_name=hotel_name)
        if result_h is None:
            print(f'Hotel name {hotel_name} does not exist')
            return
        if chain_name != chain_name_h:
            print(f'Hotel {hotel_name} belongs to chain {chain_name_h} not {chain_name}')
            return
        result_r = self.getTable(table=room_t, hotel_name=hotel_name, room_num=room_num)
        if result_r is None:
            print(f'Room number {room_num} does not exist in hotel {hotel_name}')
            return
        result_e = self.getTable(table=employee_t, sxn=check_in_e_sxn)
        if result_e is None:
            print(f'Employee with sxn {check_in_e_sxn} does not exist')
            return
        rental_id = self.genRentalKey()
        try:
            self.cursor.execute('INSERT INTO RENTAL VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, NULL)', (rental_id, username, chain_name, hotel_name, room_num, capacity, rental_rate, additional_charges, check_in_date, check_out_date, check_in_e_sxn, ))
        except Exception as e:
            print('Error:', e)
        else:
            return rental_id

    def insertRentalArchive(self, rental_id):
        result_r = self.getTable(table=rental_t, rental_id=rental_id)
        if result_r is None:
            print(f'Rental with id {rental_id} does not exist')
            return
        result_ra = self.getTable(table=rental_arch_t, rental_id=rental_id)
        if result_ra is not None:
            print(f'Rental archive with id {rental_id} already exists')
            return
        try:
            self.cursor.execute('INSERT INTO RENTAL_ARCHIVE VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)', (rental_id, result_r[1], result_r[2], result_r[3], result_r[4], result_r[5], result_r[6], result_r[7], result_r[8], result_r[9], result_r[10], ))
        except Exception as e:
            print('Error:', e)
        else:
            return rental_id

### DELETES ###

    def deleteHotelChain(self, chain_name):
        result_hc = self.getTable(table=hotel_chain_t, chain_name=chain_name)
        if result_hc is None:
            print(f'Hotel chain {chain_name} does not exist')
            return
        try:
            self.cursor.execute('DELETE FROM HOTEL_CHAIN WHERE chain_name = %s', (chain_name, ))
        except Exception as e:
            print('Error:', e)
        else:
            return True

    def deleteCentralOffice(self, chain_name, address):
        result_hc = self.getTable(table=hotel_chain_t, chain_name=chain_name)
        if result_hc is None:
            print(f'Hotel chain {chain_name} does not exist')
            return
        result_co = self.getTable(table=central_office_t, chain_name=chain_name, address=address)
        if result_co is None:
            print(f'Central office for chain {chain_name} at {address} does not exist')
            return
        try:
            self.cursor.execute('DELETE FROM CENTRAL_OFFICE WHERE chain_name = %s AND address = %s', (chain_name, address, ))
        except Exception as e:
            print('Error:', e)
        else:
            return True

    def deleteCustomer(self, username):
        result_c = self.getTable(table=customer_t, username=username)
        if result_c is None:
            print(f'Customer with username {username} does not exist')
            return
        try:
            self.cursor.execute('DELETE FROM CUSTOMER WHERE username = %s', (username, ))
        except Exception as e:
            print('Error:', e)
        else:
            return True

    def deleteEmployee(self, employee_id):
        result_e = self.getTable(table=employee_t, employee_id=employee_id)
        if result_e is None:
            print(f'Employee with id {employee_id} does not exist')
            return
        try:
            self.cursor.execute('DELETE FROM EMPLOYEE WHERE employee_id = %s', (employee_id, ))
        except Exception as e:
            print('Error:', e)
        else:
            return True

    def deleteHotel(self, hotel_name):
        result_h = self.getTable(table=hotel_t, hotel_name=hotel_name)
        if result_h is None:
            print(f'Hotel name {hotel_name} does not exist')
            return
        try:
            self.cursor.execute('DELETE FROM HOTEL WHERE hotel_name = %s', (hotel_name, ))
        except Exception as e:
            print('Error:', e)
        else:
            return True

    def deleteEmployeePosition(self, employee_id, position):
        result_e = self.getTable(table=employee_t, employee_id=employee_id)
        if result_e is None:
            print(f'Employee with id {employee_id} does not exist')
            return
        result_ep = self.getTable(table=employee_pos_t, employee_id=employee_id, position=position)
        if result_ep is None:
            print(f'Employee with id {employee_id} does not work as {position}')
            return
        try:
            self.cursor.execute('DELETE FROM EMPLOYEE_POSITION WHERE employee_id = %s AND position = %s', (employee_id, position, ))
        except Exception as e:
            print('Error:', e)
        else:
            return True

    def deleteRoom(self, hotel_name, room_num):
        result_h = self.getTable(table=hotel_t, hotel_name=hotel_name)
        if result_h is None:
            print(f'Hotel name {hotel_name} does not exist')
            return
        result_r = self.getTable(table=room_t, hotel_name=hotel_name, room_num=room_num)
        if result_r is None:
            print(f'Room number {room_num} does not exist in hotel {hotel_name}')
            return
        try:
            self.cursor.execute('DELETE FROM ROOM WHERE hotel_name = %s AND room_num = %s', (hotel_name, room_num, ))
        except Exception as e:
            print('Error:', e)
        else:
            return True

    def deleteRoomAmenity(self, hotel_name, room_num, amenity):
        result_h = self.getTable(table=hotel_t, hotel_name=hotel_name)
        if result_h is None:
            print(f'Hotel name {hotel_name} does not exist')
            return
        result_r = self.getTable(table=room_t, hotel_name=hotel_name, room_num=room_num)
        if result_r is None:
            print(f'Room number {room_num} does not exist in hotel {hotel_name}')
            return
        result_ra = self.getTable(table=room_amenity_t, hotel_name=hotel_name, room_num=room_num, amenity=amenity)
        if result_ra is None:
            print(f'Room {room_num} at {hotel_name} does not have {amenity}')
            return
        try:
            self.cursor.execute('DELETE FROM ROOM_AMENITY WHERE hotel_name = %s AND room_num = %s AND amenity = %s', (hotel_name, room_num, amenity, ))
        except Exception as e:
            print('Error:', e)
        else:
            return True

    def deleteBooking(self, booking_id):
        result_b = self.getTable(table=booking_t, booking_id=booking_id)
        if result_b is None:
            print(f'Booking with id {booking_id} does not exist')
            return
        try:
            self.cursor.execute('DELETE FROM BOOKING WHERE booking_id = %s', (booking_id, ))
        except Exception as e:
            print('Error:', e)
        else:
            return True
    
    def deleteRental(self, rental_id):
        result_r = self.getTable(table=rental_t, rental_id=rental_id)
        if result_r is None:
            print(f'Rental with id {result_r} does not exist')
            return
        try:
            self.cursor.execute('DELETE FROM RENTAL WHERE result_r = %s', (rental_id, ))
        except Exception as e:
            print('Error:', e)
        else:
            return True

### UPDATES ###

    def updateHotelChain(self, chain_id, chain_name, email, phone_number):
        result_hc_id = self.getTable(table=hotel_chain_t, chain_id=chain_id)
        if result_hc_id is None:
            print(f'Hotel chain with id {chain_id} does not exist')
            return
        result_hc_n = self.getTable(table=hotel_chain_t, chain_name=chain_name)
        if result_hc_n is not None:
            print(f'Hotel chain {chain_name} already exists')
            return
        try:
            self.cursor.execute("""
                UPDATE HOTEL_CHAIN
                SET chain_name = %s, email = %s, phone_number = %s
                WHERE chain_id = %s
                """, (chain_name, email, phone_number, chain_id, ))
        except Exception as e:
            print('Error:', e)
        else:
            return True

    def updateCentralOffice(self, central_office_id, chain_name, address):
        result_hc = self.getTable(table=hotel_chain_t, chain_name=chain_name)
        if result_hc is None:
            print(f'Hotel chain {chain_name} does not exist')
            return
        result_co_id = self.getTable(table=central_office_t, central_office_id=central_office_id)
        if result_co_id is None:
            print(f'Central office with id {central_office_id} does not exist')
            return
        result_co_a = self.getTable(table=central_office_t, chain_name=chain_name, address=address)
        if result_co_a is not None:
            print(f'Central office for chain {chain_name} at {address} already exists')
            return
        try:
            self.cursor.execute("""
                UPDATE CENTRAL_OFFICE
                SET chain_name = %s, address = %s,
                WHERE central_office_id = %s
                """, (chain_name, address, central_office_id, ))
        except Exception as e:
            print('Error:', e)
        else:
            return True

    def updateCustomer(self, customer_id, username, password, fname, lname, sxn, address):
        result_c_id,  = self.getTable(table=customer_t, customer_id=customer_id)
        if result_c_id is None:
            print(f'Customer with id {customer_id} does not exist')
            return
        result_c_u = self.getTable(table=customer_t, username=username)
        if result_c_u is not None:
            print(f'The username {username} is already taken')
            return
        try:
            self.cursor.execute("""
                UPDATE CUSTOMER
                SET username = %s, password = %s, first_name = %s, last_name = %s, sxn = %s, address = %s
                WHERE customer_id = %s
                """, (username, password, fname, lname, sxn, address, customer_id, ))
        except Exception as e:
            print('Error:', e)
        else:
            return True

    def updateEmployee(self, employee_id, chain_name, hotel_name, fname, lname, sxn, address):
        result_e = self.getTable(table=employee_t, employee_id=employee_id)
        if result_e is None:
            print(f'Employee with id {employee_id} does not exist')
            return
        result_hc = self.getTable(table=hotel_chain_t, chain_name=chain_name)
        if result_hc is None:
            print(f'Hotel chain {chain_name} does not exist')
            return
        chain_name_h, result_h = self.getTable('chain_name', 'hotel_name', table=hotel_t, hotel_name=hotel_name)
        if result_h is None:
            print(f'Hotel name {hotel_name} does not exist')
            return
        if chain_name != chain_name_h:
            print(f'Hotel {hotel_name} belongs to chain {chain_name_h} not {chain_name}')
            return
        result_e = self.getTable(table=employee_t, sxn=sxn)
        if result_e is not None:
            print(f'Employee with sxn {sxn} already exists')
            return
        try:
            self.cursor.execute("""
                UPDATE EMPLOYEE
                SET chain_name = %s, hotel_name = %s, first_name = %s, last_name = %s, sxn = %s, address = %s
                WHERE employee_id = %s
                """, (chain_name, hotel_name, fname, lname, sxn, address, employee_id, ))
        except Exception as e:
            print('Error:', e)
        else:
            return True

    def updateHotel(self, hotel_id, hotel_name, chain_name, manager_id, category, city, address, email, phone_number):
        result_hc = self.getTable(table=hotel_chain_t, chain_name=chain_name)
        if result_hc is None:
            print(f'Chain name {chain_name} does not exist')
            return
        result_e = self.getTable(table=employee_t, employee_id=manager_id)
        if result_e is None:
            print(f'Employee with id {manager_id} does not exist')
            return
        result_h_id = self.getTable(table=hotel_t, hotel_id=hotel_id)
        if result_h_id is None:
            print(f'Hotel with id {hotel_name} does not exist')
            return
        result_h_n = self.getTable(table=hotel_t, hotel_name=hotel_name)
        if result_h_n is not None:
            print(f'Hotel {hotel_name} under hotel chain {chain_name} already exists')
            return
        try:
            self.cursor.execute("""
                UPDATE HOTEL
                SET hotel_name = %s, chain_name = %s, manager_id = %s, category = %s, city = %s, address = %s, email = %s, phone_number = %s
                WHERE hotel_id = %s
                """, (hotel_name, chain_name, manager_id, category, city, address, email, phone_number, hotel_id, ))
        except Exception as e:
            print('Error:', e)
        else:
            return True

    def updateEmployeePosition(self, employee_position_id, employee_id, position):
        result_e = self.getTable(table=employee_t, employee_id=employee_id)
        if result_e is None:
            print(f'Employee with id {employee_id} does not exist')
            return
        result_ep_id = self.getTable(table=employee_pos_t, employee_position_id=employee_position_id)
        if result_ep_id is None:
            print(f'Employee position with id {employee_position_id} does not exist')
            return
        result_ep_p = self.getTable(table=employee_pos_t, employee_id=employee_id, position=position)
        if result_ep_p is not None:
            print(f'Employee {employee_id} already has position {position}')
            return
        try:
            self.cursor.execute("""
                UPDATE EMPLOYEE_POSITION
                SET employee_id = %s, position = %s
                WHERE employee_position_id = %s
                """, (employee_id, position, employee_position_id, ))
        except Exception as e:
            print('Error:', e)
        else:
            return True

    def updateRoom(self, room_id, hotel_name, room_num, price, capacity, view_type, can_extend, has_problems, available):
        result_h = self.getTable(table=hotel_t, hotel_name=hotel_name)
        if result_h is None:
            print(f'Hotel name {hotel_name} does not exist')
            return
        result_r_id = self.getTable(table=room_t, room_id=room_id)
        if result_r_id is None:
            print(f'Room with id {room_id} does not exist')
            return
        result_r_n = self.getTable(table=room_t, hotel_name=hotel_name, room_num=room_num)
        if result_r_n is not None:
            print(f'Hotel {hotel_name} already has room number {room_num}')
            return
        try:
            self.cursor.execute("""
                UPDATE ROOM
                SET hotel_name = %s, room_num = %s, price = %s, capacity = %s, view_type = %s, can_extend = %s, has_problems = %s, available = %s
                WHERE room_id = %s
                """, (hotel_name, room_num, price, capacity, view_type, can_extend, has_problems, available, room_id, ))
        except Exception as e:
            print('Error:', e)
        else:
            return True

    def updateRoomAmenity(self, room_amenity_id, hotel_name, room_num, amenity):
        result_h = self.getTable(table=hotel_t, hotel_name=hotel_name)
        if result_h is None:
            print(f'Hotel name {hotel_name} does not exist')
            return
        result_r = self.getTable(table=room_t, hotel_name=hotel_name, room_num=room_num)
        if result_r is None:
            print(f'Hotel {hotel_name} does not have a room number {room_num}')
            return
        result_ra_id = self.getTable(table=room_amenity_t, room_amenity_id=room_amenity_id)
        if result_ra_id is None:
            print(f'Room amenity id {room_amenity_id} does not exist')
            return
        result_ra_a = self.getTable(table=room_amenity_t, hotel_name=hotel_name, room_num=room_num, amenity=amenity)
        if result_ra_a is not None:
            print(f'Room {room_num} in hotel {hotel_name} already includes {amenity} amenity')
            return
        try:
            self.cursor.execute("""
                UPDATE ROOM_AMENITY
                SET hotel_name = %s, room_num = %s, amenity = %s
                WHERE room_amenity_id = %s
                """, (hotel_name, room_num, amenity, room_amenity_id, ))
        except Exception as e:
            print('Error:', e)
        else:
            return True

    def updateBooking(self, booking_id, username, chain_name, hotel_name, room_num, capacity, exp_check_in_date, exp_check_out_date):
        result_b = self.getTable(table=booking_t, hotel_name=hotel_name, room_num=room_num)
        if result_b is None:
            print(f'Booking with id {booking_id} does not exist')
            return
        result_c = self.getTable(table=customer_t, username=username)
        if result_c is None:
            print(f'The username {username} does not exist')
            return
        result_hc = self.getTable(table=hotel_chain_t, chain_name=chain_name)
        if result_hc is None:
            print(f'Hotel chain {chain_name} does not exist')
            return
        chain_name_h, result_h = self.getTable('chain_name', 'hotel_name', table=hotel_t, hotel_name=hotel_name)
        if result_h is None:
            print(f'Hotel name {hotel_name} does not exist')
            return
        if chain_name != chain_name_h:
            print(f'Hotel {hotel_name} belongs to chain {chain_name_h} not {chain_name}')
            return
        result_r = self.getTable(table=room_t, hotel_name=hotel_name, room_num=room_num)
        if result_r is None:
            print(f'Room number {room_num} does not exist in hotel {hotel_name}')
            return
        try:
            self.cursor.execute("""
                UPDATE BOOKING
                SET username = %s, chain_name = %s, hotel_name = %s, room_num = %s, capacity = %s, exp_check_in_date = %s, exp_check_out_date = %s
                WHERE booking_id = %s
                """, (username, chain_name, hotel_name, room_num, capacity, exp_check_in_date, exp_check_out_date, booking_id, ))
        except Exception as e:
            print('Error:', e)
        else:
            return True

    def updateRental(self, rental_id, username, chain_name, hotel_name, room_num, capacity, rental_rate, additional_charges, check_in_date, check_out_date, check_in_e_sxn, check_out_e_sxn):
        result_re = self.getTable(table=rental_t, rental_id=rental_id)
        if result_re is None:
            print(f'Rental with id {rental_id} does not exist')
            return
        result_c = self.getTable(table=customer_t, username=username)
        if result_c is None:
            print(f'The username {username} does not exist')
            return
        result_hc = self.getTable(table=hotel_chain_t, chain_name=chain_name)
        if result_hc is None:
            print(f'Chain name {chain_name} does not exist')
            return
        chain_name_h, result_h = self.getTable('chain_name', 'hotel_name', table=hotel_t, hotel_name=hotel_name)
        if result_h is None:
            print(f'Hotel name {hotel_name} does not exist')
            return
        if chain_name != chain_name_h:
            print(f'Hotel {hotel_name} belongs to chain {chain_name_h} not {chain_name}')
            return
        result_r = self.getTable(table=room_t, hotel_name=hotel_name, room_num=room_num)
        if result_r is None:
            print(f'Room number {room_num} does not exist in hotel {hotel_name}')
            return
        result_e_in = self.getTable(table=employee_t, sxn=check_in_e_sxn)
        if result_e_in is None:
            print(f'Employee with sxn {check_in_e_sxn} does not exist')
            return
        result_e_out = self.getTable(table=employee_t, sxn=check_out_e_sxn)
        if result_e_out is None:
            print(f'Employee with sxn {check_out_e_sxn} does not exist')
            return
        try:
            self.cursor.execute("""
                UPDATE RENTAL
                SET username = %s, chain_name = %s, hotel_name = %s, room_num = %s, capacity = %s, rental_rate = %s, additional_charges = %s,
                check_in_date = %s, check_out_date = %s, check_in_e_sxn = %s, check_out_e_sxn = %s
                WHERE rental_id = %s
                """, (username, chain_name, hotel_name, room_num, capacity, rental_rate, additional_charges, check_in_date, check_out_date, check_in_e_sxn, check_out_e_sxn, rental_id, ))
        except Exception as e:
            print('Error:', e)
        else:
            return True

### KEYGENS ###

    def genEmployeeKey(self):
        while True:
            employee_id = self.generateCharKey(5)
            if self.getTable('employee_id', table=employee_t, employee_id=employee_id) is None:
                break
        return employee_id

    def genBookingKey(self):
        while True:
            booking_id = self.generateCharKey(5)
            if (self.getTable('booking_id', table=booking_t, booking_id=booking_id) is None) and (self.getTable('booking_id', table=booking_arch_t, booking_id=booking_id) is None):
                break
        return booking_id

    def genRentalKey(self):
        while True:
            rental_id = self.generateCharKey(5)
            if (self.getTable('rental_id', table=rental_t, rental_id=rental_id) is None) and (self.getTable('rental_id', table=rental_arch_t, rental_id=rental_id) is None):
                break
        return rental_id

    def generateCharKey(self, length):
        characters = string.ascii_uppercase + string.digits
        random_string = ''.join(random.choices(characters, k=length))
        return random_string

### MISC ###

    def print_fetchall(self, result, name=None):
        if name is not None: print(str(name)+' = ', end='')
        print('[')
        for i, item in enumerate(result):
            print(' {['+str(i)+']')
            for item, amount in item.items():
                print("     {}: {},".format(item, amount))
            print(' },')
        print(']')

eHotels = EHotels(host, user, passwd, database)