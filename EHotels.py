import mysql.connector
import random
import string
from include import *

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
    
    def getSimpleConditions(self, dict):
        dict.pop('table', None)
        dict.pop('fetchall', None)
        dict.pop('distinct', None)
        if not dict: return ''
        conditions_pairs = []
        for attribute, value in dict.items():
            if value:
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
                JOIN HOTEL h ON hc.chain_id = h.chain_id
                JOIN ROOM r ON h.hotel_id = r.hotel_id
                {conditions}
            """
            self.execute(query1)
            results_individual = self.fetchall()
            if hotel_name:
                query2 = f"""
                    SELECT ra.room_num, ra.amenity
                    FROM ROOM_AMENITY ra
                    JOIN HOTEL ho ON ra.hotel_id = ho.hotel_id
                    WHERE ho.hotel_name = "{hotel_name}"
                    AND ra.room_num IN (
                        SELECT r.room_num
                        FROM HOTEL_CHAIN hc
                        JOIN HOTEL h ON hc.chain_id = h.chain_id
                        JOIN ROOM r ON h.hotel_id = r.hotel_id
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
            JOIN HOTEL h ON hc.chain_id = h.chain_id
            JOIN ROOM r ON h.hotel_id = r.hotel_id
            {conditions}
            GROUP BY h.city, hc.chain_name, h.hotel_name, h.category
        """
        self.execute(query)
        results = self.fetchall()
        return results

    def getPriceCondition(self, low, high):
        condition = ''
        if low and high:
            condition = f'r.price BETWEEN {low} AND {high}'
        elif low and not high:
            condition = f'r.price >= {low}'
        elif not low and high:
            condition = f'r.price <= {high}'
        return condition

    def getDateConditions(self, start_date, end_date):
        condition = ''
        if start_date and end_date:
            condition = f"""
                (var.hotel_name, r.room_num) NOT IN (
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
                (var.hotel_name, r.room_num) NOT IN (
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
                (var.hotel_name, r.room_num) NOT IN (
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
        result = self.getTable(table=hotel_chain_t, chain_name=chain_name)
        if result is not None:
            print(f'Hotel chain {chain_name} already exists')
            return
        chain_id = self.genHotelChainKey()
        try:
            self.cursor.execute('INSERT INTO HOTEL_CHAIN VALUES (%s, %s, 0, %s, %s)', (chain_id, chain_name, email, phone_number, ))
        except Exception as e:
            print('Error:', e)
        else:
            return chain_id

    def insertCentralOffice(self, chain_name, address):
        chain_id = self.getTable('chain_id', table=hotel_chain_t, chain_name=chain_name)
        if chain_id is None:
            print(f'Chain name {chain_name} does not exist')
            return
        result = self.getTable(table=central_office_t, chain_id=chain_id, address=address)
        if result is not None:
            print(f'Central office of hotel chain {chain_name} at {address} already exists')
            return
        try:
            self.cursor.execute('INSERT INTO CENTRAL_OFFICE VALUES (%s, %s)', (chain_id, address, ))
        except Exception as e:
            print('Error:', e)
        else:
            return chain_id, address

    def insertCustomer(self, sxn, fname, lname, address, username, password):
        result = self.getTable(table=customer_t, username=username)
        if result is not None:
            print(f'The username {username} is already taken')
            return
        try:
            self.cursor.execute('INSERT INTO CUSTOMER VALUES (NULL, %s, %s, %s, %s, CURDATE(), %s, %s)', (sxn, fname, lname, address, username, password, ))
        except Exception as e:
            print('Error:', e)
        else:
            return username
        
    def insertEmployee(self, hotel_name, fname, lname, sxn='', address=''):
        chain_id, hotel_id = self.getTable('chain_id', 'hotel_id', table=hotel_t, hotel_name=hotel_name)
        if hotel_id is None:
            print(f'Hotel name {hotel_name} does not exist')
            return
        result = self.getTable(table=employee_t, sxn=sxn)
        if result is not None:
            print(f'Employee with sxn {sxn} already exists')
            return
        employee_id = self.genEmployeeKey()
        try:
            self.cursor.execute('INSERT INTO EMPLOYEE VALUES (%s, %s, %s, %s, %s, %s, %s)', (employee_id, chain_id, sxn, fname, lname, address, hotel_id, ))
        except Exception as e:
            print('Error:', e)
        else:
            return employee_id

    def insertHotel(self, hotel_name, chain_name, city, mgr_fname, mgr_lname, category='', hotel_address='', email='', phone_number='', mgr_sxn='', mgr_address=''):
        chain_id = self.getTable('chain_id', table=hotel_chain_t, chain_name=chain_name)
        if chain_id is None:
            print(f'Chain name {chain_name} does not exist')
        result = self.getTable(table=hotel_t, chain_id=chain_id, hotel_name=hotel_name)
        if result is not None:
            print(f'Hotel {hotel_name} under hotel chain {chain_name} already exists')
        manager_id = self.insertEmployee(hotel_name, mgr_fname, mgr_lname, mgr_sxn, mgr_address)
        hotel_id = self.genHotelKey()
        try:
            self.cursor.execute('INSERT INTO HOTEL VALUES (%s, %s, %s, %s, %s, 0, %s, %s, %s, %s)', (hotel_id, chain_id, manager_id, hotel_name, category, city, hotel_address, email, phone_number, ))
        except Exception as e:
            print('Error:', e)
        else:
            return hotel_id

    def insertEmployeePosition(self, employee_id, position, hotel_name):
        employee_id = self.getTable(table=employee_t, employee_id=employee_id)
        if hotel_id is None:
            print(f'Employee {employee_id} does not exist')
            return
        hotel_id = self.getTable('hotel_id', table=hotel_t, hotel_name=hotel_name)
        if hotel_id is None:
            print(f'Hotel name {hotel_name} does not exist')
            return
        result = self.getTable(table=central_office_t, employee_id=employee_id, position=position)
        if result is not None:
            print(f'Employee {employee_id} already has position {position}')
            return
        try:
            self.cursor.execute('INSERT INTO EMPLOYEE_POSITION VALUES (%s, %s, %s)', (employee_id, position, hotel_id, ))
        except Exception as e:
            print('Error:', e)
        else:
            return employee_id, position
        
    def insertRoom(self, hotel_name, room_num, price, capacity, view_type, can_extend, has_problems, available):
        hotel_id = self.getTable('hotel_id', table=hotel_t, hotel_name=hotel_name)
        if hotel_id is None:
            print(f'Hotel name {hotel_name} does not exist')
            return
        result = self.getTable(table=room_t, hotel_id=hotel_id, room_num=room_num)
        if result is not None:
            print(f'Hotel {hotel_name} already has room number {room_num}')
            return
        try:
            self.cursor.execute('INSERT INTO ROOM VALUES (%s, %s, %s, %s, %s, %s, %s, %s)', (hotel_id, room_num, price, capacity, view_type, can_extend, has_problems, available, ))
        except Exception as e:
            print('Error:', e)
        else:
            return hotel_id, room_num

    def insertRoomAmenity(self, hotel_name, room_num, amenity):
        hotel_id = self.getTable('hotel_id', table=hotel_t, hotel_name=hotel_name)
        if hotel_id is None:
            print(f'Hotel name {hotel_name} does not exist')
            return
        result1 = self.getTable(table=room_t, hotel_id=hotel_id, room_num=room_num)
        if result1 is None:
            print(f'Hotel {hotel_name} does not have a room number {room_num}')
            return
        result2 = self.getTable(table=room_amenity_t, hotel_id=hotel_id, room_num=room_num,amenity=amenity)
        if result2 is not None:
            print(f'Room {room_num} in hotel {hotel_name} already includes {amenity} amenity')
            return
        try:
            self.cursor.execute('INSERT INTO ROOM VALUES (%s, %s, %s)', (hotel_id, room_num, amenity, ))
        except Exception as e:
            print('Error:', e)
        else:
            return hotel_id, room_num, amenity

### KEYGENS ###

    def genHotelChainKey(self):
        while True:
            chain_id = self.generateCharKey(5)
            if self.getTable('chain_id', table=hotel_chain_t, chain_id=chain_id) is None:
                break
        return chain_id

    def genEmployeeKey(self):
        while True:
            employee_id = self.generateCharKey(5)
            if self.getTable('employee_id', table=employee_t, employee_id=employee_id) is None:
                break
        return employee_id
    
    def genHotelKey(self):
        while True:
            hotel_id = self.generateCharKey(5)
            if self.getTable('hotel_id', table=hotel_t, hotel_id=hotel_id) is None:
                break
        return hotel_id

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