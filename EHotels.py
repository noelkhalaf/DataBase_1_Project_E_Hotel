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
        query = f'SELECT {selected} FROM {kwargs.get("table")} {conditions}'
        self.execute(query)
        if kwargs.get('fetchall'):
            return self.fetchall()
        else:
            return self.fetchone()
    
    def getSimpleConditions(self, dict):
        dict.pop('table', None)
        dict.pop('fetchall', None)
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
            'var.chain_name': hotel_chain,
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
                self.print_fetchall(results_appended, name='Available Rooms')
                return results_appended
            return results_individual
        
        query = f"""
            SELECT var.city, var.chain_name, var.hotel_name, var.category, COUNT(r.room_num) AS available_rooms
            FROM view_available_rooms var
            JOIN HOTEL h ON var.hotel_name = h.hotel_name
            JOIN ROOM r ON h.hotel_id = r.hotel_id
            {conditions}
            GROUP BY var.city, var.chain_name, var.hotel_name, var.category
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
        start=0
        for room_a in available_rooms:
            amenities = []
            for i in range(start, len(room_amenities)):
                if room_a['room_num'] < room_amenities[i]['room_num']:
                    break
                elif room_a['room_num'] == room_amenities[i]['room_num']:
                    amenities.append(room_amenities[i]['amenity'])
            start=i
            room_a['amenities'] = amenities
        return available_rooms

    def generateCharKey(self, length):
        characters = string.ascii_uppercase + string.digits
        random_string = ''.join(random.choices(characters, k=length))
        return random_string

    def insertHotelChain(self, chain_name, email, phone_number):
        while True:
            chain_id = self.generateCharKey(5)
            self.getTable('chain_id', table=hotel_chain_t)
            if self.fetchone is None:
                break
        self.cursor.execute('INSERT INTO HOTEL_CHAIN VALUES (%s, %s, 0, %s, %s)', (chain_id, chain_name, email, phone_number, ))

    def insertCentralOffice(self, chain_name, email, phone_number):
        self.execute('SELECT * FROM HOTEL_CHAIN WHERE chain_id = %s', (chain_id, ))
        self.cursor.execute('INSERT INTO HOTEL_CHAIN VALUES (%s, %s, 0, %s, %s)', (chain_id, chain_name, email, phone_number, ))

    def insertCustomer(self, sxn, fname, lname, address, username, password):
        self.cursor.execute('INSERT INTO CUSTOMER VALUES (NULL, %s, %s, %s, %s, CURDATE(), %s, %s)', (sxn, fname, lname, address, username, password, ))

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