import mysql.connector

host = 'localhost'
user = 'root'
passwd = 'password'
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
        self.cursor = self.db.cursor()

    def closeCursor(self):
        self.cursor.close()

    def execute(self, query):
        self.cursor.execute(query)
        self.commit()

    def commit(self):
        self.db.commit()

    def fetchone(self):
        return self.cursor.fetchone()

    def getTable(self, *args, **kwargs):
        selected = '*' if not args else ','.join(args)
        conditions = '' if not kwargs else self.getConditions(kwargs)
        query = f'SELECT {selected} FROM {kwargs["table"]} {conditions}'
        self.execute(query)
        return self.fetchone()

    def insertCustomer(self, sxn, fname, lname, address, username, password):
        self.cursor.execute('INSERT INTO CUSTOMER VALUES (NULL, %s, %s, %s, %s, CURDATE(), %s, %s)', (sxn, fname, lname, address, username, password, ))
    
    def getConditions(self, dict):
        conditions_pairs = []
        for attribute, value in dict.items():
            if value is not None and attribute != 'table':
                conditions_pairs.append(f'{attribute} = \"{value}\"')
        conditions = 'WHERE '+ ' AND '.join(conditions_pairs)
        return conditions

eHotels = EHotels(host, user, passwd, database)