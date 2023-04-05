import mysql.connector

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
        selected = '*' if not args else ','.join(args)
        conditions = 'WHERE ' + self.getSimpleConditions(kwargs.copy())
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
            if value is not None:
                conditions_pairs.append(f'{attribute} = \"{value}\"')
        conditions = self.joinConditions(conditions_pairs)
        return conditions
    
    def joinConditions(self, conditions_lst):
        conditions = ' AND '.join(conditions_lst)
        return conditions
    
    def getAvailableRooms(self, start_date, end_date, room_capacity, city, hotel_chain, category, total_no_rooms, min_price='0', max_price='500'):

        # if no start_date and no end_date
        #   no condition
        # elif start_date and no end_date
        #   check start_date not between start_date and end_date of any bookings, check start_date not before end_date of any rentings
        # elif no start_date and end_date
        #   check end_date not between start_date and end_date of any bookings, check end_date not before end_date of any rentings
        # elif start_date and end_date
        #   check start_date not between start_date and end_date of any bookings, check start_date not before end_date of any rentings
        #   check end_date not between start_date and end_date of any bookings
        #   check start_date of any bookings not between start_date and end_date
        #   check end_date of any bookings not between start_date and end_date
        #
        # room_capacity = room_capacity
        # city = city
        # hotel_chain = hotel_chain
        # category = category
        # total_no_rooms = total_no_rooms
        # price BETWEEN min_price and max_price

        dict_simple = {
            'r.capacity': room_capacity,
            'h.city': city,
            'var.chain_name': hotel_chain,
            'h.category': category,
            'h.num_rooms': total_no_rooms,
        }

        price_condition = self.getRangeCondition('r.price', min_price, max_price)
        simple_conditions = self.getSimpleConditions(dict_simple)
        complex_conditions = ''
        
        conditions = self.joinConditions([price_condition, simple_conditions, complex_conditions])

        query = f"""
            SELECT var.city, var.chain_name, var.hotel_name, var.category, COUNT(r.available) AS available_rooms
            FROM view_available_rooms var
            JOIN HOTEL h ON var.hotel_name = h.hotel_name
            JOIN ROOM r ON h.hotel_id = r.hotel_id
            WHERE {conditions}
            GROUP BY var.city, var.chain_name, var.hotel_name, var.category;
        """

    def getRangeCondition(self, attribute, low, high):
        condition = f'{attribute} BETWEEN {low} AND {high}'
        return condition

    def insertCustomer(self, sxn, fname, lname, address, username, password):
        self.cursor.execute('INSERT INTO CUSTOMER VALUES (NULL, %s, %s, %s, %s, CURDATE(), %s, %s)', (sxn, fname, lname, address, username, password, ))

eHotels = EHotels(host, user, passwd, database)