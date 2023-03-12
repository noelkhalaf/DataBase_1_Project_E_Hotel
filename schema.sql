DROP TABLE IF EXISTS HOTEL_CHAIN;
DROP TABLE IF EXISTS CENTRAL_OFFICE;
DROP TABLE IF EXISTS CUSTOMER;
DROP TABLE IF EXISTS HOTEL;
DROP TABLE IF EXISTS ROOM;
DROP TABLE IF EXISTS EMPLOYEE;
DROP TABLE IF EXISTS EMPLOYEE_POSITION
DROP TABLE IF EXISTS ROOM_AMENITY
DROP TABLE IF EXISTS RENTAL;
DROP TABLE IF EXISTS RENTAL_ARCHIVE;
DROP TABLE IF EXISTS BOOKING;
DROP TABLE IF EXISTS BOOKING_ARCHIVE;

CREATE TABLE IF NOT EXISTS HOTEL_CHAIN (
	chain_id CHAR(5),
    name VARCHAR(30) NOT NULL,
    num_hotels INTEGER,
    email VARCHAR(30),
    phone_number VARCHAR(20),
    PRIMARY KEY (chain_id)
);

CREATE TABLE IF NOT EXISTS CENTRAL_OFFICE ( -- Added
	chain_id CHAR(5),
    address VARCHAR(30),
    PRIMARY KEY (chain_id, address),
    FOREIGN KEY (chain_id) REFERENCES HOTEL_CHAIN (chain_id)
);

CREATE TABLE IF NOT EXISTS CUSTOMER (
	customer_id CHAR(5),
    sxn CHAR(9),
    first_name VARCHAR(30) NOT NULL,
    last_name VARCHAR(30) NOT NULL,
    address VARCHAR(30),
    registration_date DATE NOT NULL,
    PRIMARY KEY (customer_id)
);

CREATE TABLE IF NOT EXISTS EMPLOYEE (
	employee_id CHAR(5),
    chain_id CHAR(5),
	sxn CHAR(9),
    first_name VARCHAR(30) NOT NULL,
    last_name VARCHAR(30) NOT NULL,
    address VARCHAR(30),
    PRIMARY KEY (employee_id),
    FOREIGN KEY (chain_id) REFERENCES HOTEL_CHAIN (chain_id)
		ON DELETE CASCADE
		ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS EMPLOYEE_POSITION ( -- Added
	employee_id CHAR(5),
    position VARCHAR(20),
    PRIMARY KEY (employee_id, position),
    FOREIGN KEY (employee_id) REFERENCES EMPLOYEE (employee_id)
);

CREATE TABLE IF NOT EXISTS HOTEL (
	chain_id CHAR(5),
	hotel_id CHAR(5),
    manager_id CHAR(5) NOT NULL,
    name VARCHAR(30) NOT NULL,
    rating ENUM('1-star', '2-star', '3-star', '4-star', '5-star'),
    num_rooms INTEGER,
    city VARCHAR(30) NOT NULL, -- Added
    address VARCHAR(30),
    email VARCHAR(30),
    phone_number VARCHAR(20) NOT NULL,
    PRIMARY KEY (chain_id, hotel_id),	-- Modified for chain_id
    FOREIGN KEY (chain_id) REFERENCES HOTEL_CHAIN (chain_id)
    	ON DELETE CASCADE
		ON UPDATE CASCADE,
    FOREIGN KEY (manager_id) REFERENCES EMPLOYEE (employee_id)
);

ALTER TABLE EMPLOYEE
ADD COLUMN hotel_id CHAR(5);
ALTER TABLE EMPLOYEE
ADD FOREIGN KEY (hotel_id) REFERENCES HOTEL (hotel_id)
	ON DELETE CASCADE
	ON UPDATE CASCADE;

CREATE TABLE IF NOT EXISTS ROOM (
	hotel_id CHAR(5),
    room_num INTEGER,
    price DECIMAL(15,2) NOT NULL,
    capacity INTEGER NOT NULL CHECK (1<=capacity<=6), -- Modified
    view_type ENUM('sea view', 'mountain view') NOT NULL,
    can_extend BOOL NOT NULL,
    has_problems BOOL NOT NULL,
    PRIMARY KEY (hotel_id, room_num),
    FOREIGN KEY (hotel_id) REFERENCES HOTEL (hotel_id)
		ON DELETE CASCADE
		ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS ROOM_AMENITY ( -- Added
	hotel_id CHAR(5),
    room_num INTEGER,
    amenity VARCHAR(30),
    PRIMARY KEY (hotel_id, room_num, amenity),
    FOREIGN KEY (hotel_id, room_num) REFERENCES ROOM (hotel_id, room_num)
);

CREATE TABLE IF NOT EXISTS RENTAL (
	rental_id CHAR(5),
    customer_id CHAR(5) NOT NULL,
    hotel_name VARCHAR(30) NOT NULL,
    room_num INTEGER NOT NULL,
    capacity INTEGER NOT NULL CHECK (1<=capacity<=6), -- Modified
    rental_rate DECIMAL(15,2) NOT NULL,
    additional_charges DECIMAL(15,2),
    check_in_date DATETIME NOT NULL,
    check_out_date DATETIME,
    check_in_e_id CHAR(5) NOT NULL,
    check_out_e_id CHAR(5),
    PRIMARY KEY (rental_id),
    FOREIGN KEY (customer_id) REFERENCES CUSTOMER (customer_id),
    FOREIGN KEY (check_in_e_id) REFERENCES EMPLOYEE (employee_id),
    FOREIGN KEY (check_out_e_id) REFERENCES EMPLOYEE (employee_id)
);

CREATE TABLE IF NOT EXISTS RENTAL_ARCHIVE (
	rental_id CHAR(5),
    customer_id CHAR(5) NOT NULL,
    hotel_name VARCHAR(30) NOT NULL,
    room_num INTEGER NOT NULL,
    capacity INTEGER NOT NULL CHECK (1<=capacity<=6), -- Modified
    rental_rate DECIMAL(15,2) NOT NULL,
    additional_charges DECIMAL(15,2) NOT NULL,
    check_in_date DATETIME NOT NULL,
    check_out_date DATETIME NOT NULL,
    check_in_e_id CHAR(5) NOT NULL,
    check_out_e_id CHAR(5) NOT NULL,
    PRIMARY KEY (rental_id),
    FOREIGN KEY (customer_id) REFERENCES CUSTOMER (customer_id),
    FOREIGN KEY (check_in_e_id) REFERENCES EMPLOYEE (employee_id),
    FOREIGN KEY (check_out_e_id) REFERENCES EMPLOYEE (employee_id)
);

CREATE TABLE IF NOT EXISTS BOOKING (
	booking_id CHAR(5),
    customer_id CHAR(5) NOT NULL,
    hotel_name VARCHAR(30) NOT NULL,
    room_num INTEGER NOT NULL,
    capacity INTEGER NOT NULL CHECK (1<=capacity<=6), -- Modified
    place_date DATETIME NOT NULL,
    exp_check_in_date DATETIME NOT NULL,
    exp_check_out_date DATETIME NOT NULL,
    PRIMARY KEY (booking_id),
    FOREIGN KEY (customer_id) REFERENCES CUSTOMER (customer_id)
);

CREATE TABLE IF NOT EXISTS BOOKING_ARCHIVE (
	booking_id CHAR(5),
    customer_id CHAR(5) NOT NULL,
    hotel_name VARCHAR(30) NOT NULL,
    room_num INTEGER NOT NULL,
    capacity INTEGER NOT NULL CHECK (1<=capacity<=6), -- Modified
    place_date DATETIME NOT NULL,
    exp_check_in_date DATETIME NOT NULL,
    exp_check_out_date DATETIME NOT NULL,
    PRIMARY KEY (booking_id),
    FOREIGN KEY (customer_id) REFERENCES CUSTOMER (customer_id)
);