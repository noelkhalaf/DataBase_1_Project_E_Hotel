import mysql.connector
import os

host = 'localhost'
user = 'root'
passwd = os.environ.get('MYSQL_PASSWD')
database = 'e_hotels'

class EHotels:
    def __init__(self, host, user, passwd, database):
        self.host = host
        self.user = user
        self.passwd = passwd
        self.database = database
        self.db = mysql.connector.connect(
                host=host,
                user=user,
                passwd=passwd,
                database=database
            )
        self.cursor = self.db.cursor()

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
        self.commit()
    
    def getConditions(self, dict):
        conditions_pairs = []
        for attribute, value in dict.items():
            if value is not None and attribute != 'table':
                conditions_pairs.append(f'{attribute} = \"{value}\"')
        conditions = 'WHERE '+ ' AND '.join(conditions_pairs)
        return conditions

eHotels = EHotels(host, user, passwd, database)