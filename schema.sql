-- DROP TABLE IF EXISTS HOTEL_CHAIN;
-- DROP TABLE IF EXISTS CENTRAL_OFFICE;
-- DROP TABLE IF EXISTS CUSTOMER;
-- DROP TABLE IF EXISTS HOTEL;
-- DROP TABLE IF EXISTS ROOM;
-- DROP TABLE IF EXISTS EMPLOYEE;
-- DROP TABLE IF EXISTS EMPLOYEE_POSITION;
-- DROP TABLE IF EXISTS ROOM_AMENITY;
-- DROP TABLE IF EXISTS RENTAL;
-- DROP TABLE IF EXISTS RENTAL_ARCHIVE;
-- DROP TABLE IF EXISTS BOOKING;
-- DROP TABLE IF EXISTS BOOKING_ARCHIVE;

CREATE TABLE IF NOT EXISTS HOTEL_CHAIN (
	chain_id CHAR(5) NOT NULL,
    chain_name VARCHAR(30) NOT NULL,
    num_hotels INTEGER,
    email VARCHAR(30),
    phone_number VARCHAR(20),
    PRIMARY KEY (chain_id)
);

CREATE TABLE IF NOT EXISTS CENTRAL_OFFICE ( -- Added
    address VARCHAR(30),
    chain_id CHAR(5) NOT NULL,
    PRIMARY KEY (chain_id, address),
    FOREIGN KEY (chain_id) REFERENCES HOTEL_CHAIN (chain_id)
		ON DELETE CASCADE
		ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS CUSTOMER (
    customer_id INT AUTO_INCREMENT NOT NULL,
    sxn CHAR(9) NOT NULL,
    first_name VARCHAR(30) NOT NULL,
    last_name VARCHAR(30) NOT NULL,
    address VARCHAR(30) NOT NULL,
    registration_date DATE NOT NULL,
    username VARCHAR(30) UNIQUE NOT NULL,
    password VARCHAR(30) NOT NULL,
    PRIMARY KEY (customer_id)
);

CREATE TABLE IF NOT EXISTS EMPLOYEE (
	employee_id CHAR(5) NOT NULL,
    chain_id CHAR(5),
	sxn CHAR(9),
    first_name VARCHAR(30) NOT NULL,
    last_name VARCHAR(30) NOT NULL,
    address VARCHAR(30),
    PRIMARY KEY (employee_id),
    FOREIGN KEY (chain_id) REFERENCES HOTEL_CHAIN (chain_id)
		ON DELETE SET NULL
		ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS HOTEL (
	hotel_id CHAR(5) NOT NULL,
    chain_id CHAR(5) NOT NULL,
    manager_id CHAR(5) NOT NULL,
    hotel_name VARCHAR(30) NOT NULL,
    category ENUM('1-star', '2-star', '3-star', '4-star', '5-star'),
    num_rooms INTEGER,
    city VARCHAR(30) NOT NULL, -- Added
    address VARCHAR(30),
    email VARCHAR(30),
    phone_number VARCHAR(20) NOT NULL,
    PRIMARY KEY (hotel_id),	-- Modified for chain_id
    FOREIGN KEY (chain_id) REFERENCES HOTEL_CHAIN (chain_id)
    	ON DELETE CASCADE
		ON UPDATE CASCADE,
    FOREIGN KEY (manager_id) REFERENCES EMPLOYEE (employee_id)
);
CREATE INDEX index_hotel_id ON HOTEL (hotel_id);

CREATE TRIGGER increment_num_hotels
AFTER INSERT ON HOTEL
FOR EACH ROW
UPDATE HOTEL_CHAIN
SET num_hotels = num_hotels + 1
WHERE chain_id = NEW.chain_id;

CREATE TRIGGER decrement_num_hotels
AFTER DELETE ON HOTEL
FOR EACH ROW
UPDATE HOTEL_CHAIN
SET num_hotels = num_hotels - 1
WHERE chain_id = OLD.chain_id;

ALTER TABLE EMPLOYEE
ADD COLUMN hotel_id CHAR(5);
ALTER TABLE EMPLOYEE
ADD FOREIGN KEY (hotel_id) REFERENCES HOTEL (hotel_id)
	ON DELETE SET NULL
	ON UPDATE CASCADE;

CREATE TABLE IF NOT EXISTS EMPLOYEE_POSITION ( -- Added
	employee_id CHAR(5) NOT NULL,
    position VARCHAR(20) NOT NULL,
    hotel_id CHAR(5) NOT NULL,
    PRIMARY KEY (employee_id, position),
    FOREIGN KEY (employee_id) REFERENCES EMPLOYEE (employee_id),
    FOREIGN KEY (hotel_id) REFERENCES HOTEL (hotel_id)
		ON DELETE CASCADE
		ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS ROOM (
	hotel_id CHAR(5) NOT NULL,
    room_num INTEGER NOT NULL,
    price DECIMAL(15,2) NOT NULL,
    capacity INTEGER NOT NULL CHECK (1<=capacity<=6), -- Modified
    view_type ENUM('sea view', 'mountain view') NOT NULL,
    can_extend BOOL NOT NULL,
    has_problems BOOL NOT NULL,
    available BOOL NOT NULL,
    PRIMARY KEY (hotel_id, room_num), -- Modified
    FOREIGN KEY (hotel_id) REFERENCES HOTEL (hotel_id)
		ON DELETE CASCADE
		ON UPDATE CASCADE
);

CREATE TRIGGER increment_num_rooms
AFTER INSERT ON ROOM
FOR EACH ROW
UPDATE HOTEL
SET num_rooms = num_rooms + 1
WHERE hotel_id = NEW.hotel_id;

CREATE TRIGGER decrement_num_rooms
AFTER DELETE ON ROOM
FOR EACH ROW
UPDATE HOTEL
SET num_rooms = num_rooms - 1
WHERE hotel_id = OLD.hotel_id;

CREATE TABLE IF NOT EXISTS ROOM_AMENITY ( -- Added
	hotel_id CHAR(5) NOT NULL,
    room_num INTEGER NOT NULL,
    amenity VARCHAR(30) NOT NULL,
    PRIMARY KEY (hotel_id, room_num, amenity), -- Modified
    FOREIGN KEY (hotel_id, room_num) REFERENCES ROOM (hotel_id, room_num) -- Modified
		ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS RENTAL (
	rental_id CHAR(5) NOT NULL,
    customer_id INT NOT NULL,
    chain_name VARCHAR(30) NOT NULL, -- Added
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
	rental_id CHAR(5) NOT NULL,
    customer_id INT NOT NULL,
    chain_name VARCHAR(30) NOT NULL, -- Added
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
	booking_id CHAR(5) NOT NULL,
    customer_id INT NOT NULL,
    chain_name VARCHAR(30) NOT NULL, -- Added
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
	booking_id CHAR(5) NOT NULL,
    customer_id INT NOT NULL,
    chain_name VARCHAR(30) NOT NULL, -- Added
    hotel_name VARCHAR(30) NOT NULL,
    room_num INTEGER NOT NULL,
    capacity INTEGER NOT NULL CHECK (1<=capacity<=6), -- Modified
    place_date DATETIME NOT NULL,
    exp_check_in_date DATETIME NOT NULL,
    exp_check_out_date DATETIME NOT NULL,
    PRIMARY KEY (booking_id),
    FOREIGN KEY (customer_id) REFERENCES CUSTOMER (customer_id)
);

CREATE VIEW view_available_rooms AS
SELECT h.city, hc.chain_name, h.hotel_name, h.category, COUNT(r.available) AS available_rooms
FROM HOTEL_CHAIN hc
JOIN HOTEL h ON hc.chain_id = h.chain_id
JOIN ROOM r ON h.hotel_id = r.hotel_id
GROUP BY h.city, hc.chain_name, h.hotel_id, h.hotel_name, h.category, r.available
HAVING r.available = TRUE;

CREATE VIEW view_capacity AS
SELECT h.hotel_name, r.room_num, r.capacity
FROM HOTEL h
JOIN ROOM r ON h.hotel_id = r.hotel_id;

INSERT INTO HOTEL_CHAIN (chain_id, chain_name, num_hotels, email, phone_number)
VALUES
('0000A', 'Hilton', 0, 'support@hilton.com', '(364) 744-9920'),
('0000B', 'Hyatt', 0, 'support@hyatt.com', '(654) 440-5155'),
('0000C', 'Marriott', 0, 'support@marriott.com', '(839) 385-3736'),
('0000D', 'IHG', 0, 'support@ihg.com', '(211) 732-6435'),
('0000E', 'Wyndham', 0, 'support@wyndham.com', '(848) 818-8802');

INSERT INTO CENTRAL_OFFICE (chain_id, address)
VALUES
('0000A', '1957 Mulberry Street'),
('0000A', '4158 Philli Lane'),
('0000B', '1715 Hinkle Deegan Lake Road'),
('0000B', '2869 Round Table Drive'),
('0000C', '2296 Murry Street'),
('0000C', '1844 Dovetail Estates'),
('0000D', '2017 Scott Street'),
('0000D', '1737 Confederate Drive'),
('0000E', '4249 Tea Berry Lane'),
('0000E', '4709 Spring Avenue');

INSERT INTO EMPLOYEE (employee_id, chain_id, sxn, first_name, last_name)
VALUES
('A1001', '0000A', '479429054', 'Philip', 'Prince'),
('A1002', '0000A', '582321848', 'Carrie', 'Parker'),
('A1003', '0000A', '774770919', 'Julio', 'Bush'),
('A2001', '0000A', '674462475', 'Wade', 'Barron'),
('A2002', '0000A', '725696111', 'Randi', 'Torres'),
('A2003', '0000A', '169421599', 'Scott', 'Decker'),
('A3001', '0000A', '902471674', 'Alexis', 'Mack'),
('A3002', '0000A', '815150416', 'Myron', 'Crawford'),
('A3003', '0000A', '617386070', 'Grover', 'Ponce'),
('A4001', '0000A', '379534394', 'Shelby', 'Shields'),
('A4002', '0000A', '065036758', 'Fred', 'Jacobs'),
('A4003', '0000A', '749778460', 'Mitch', 'Ayala'),
('A5001', '0000A', '149621101', 'Emery', 'Pearson'),
('A5002', '0000A', '875637696', 'Simone', 'Ritter'),
('A5003', '0000A', '235693078', 'Rodger', 'Huerta'),
('A6001', '0000A', '699315056', 'Brendan', 'Sutton'),
('A6002', '0000A', '384668117', 'Lorenzo', 'Nelson'),
('A6003', '0000A', '902793232', 'Loraine', 'Sampson'),
('A7001', '0000A', '392783847', 'Rupert', 'Carroll'),
('A7002', '0000A', '659970521', 'Lynne', 'Reed'),
('A7003', '0000A', '706686398', 'Ray', 'Neal'),
('A8001', '0000A', '199375197', 'Loren', 'Sharp'),
('A8002', '0000A', '863520684', 'Irwin', 'Clay'),
('A8003', '0000A', '194848630', 'Elroy', 'Morris'),

('B1001', '0000B', '336906312', 'Sammy', 'Espinoza'),
('B1002', '0000B', '669576133', 'Weston', 'Sanders'),
('B1003', '0000B', '012889109', 'Merrill', 'Chavez'),
('B2001', '0000B', '769029570', 'Tyree', 'Mays'),
('B2002', '0000B', '793264671', 'Joe', 'Castaneda'),
('B2003', '0000B', '250408229', 'Asa', 'Thornton'),
('B3001', '0000B', '400543538', 'Krystal', 'Ali'),
('B3002', '0000B', '030801064', 'Courtney', 'Mosley'),
('B3003', '0000B', '936745420', 'Marcie', 'Greene'),
('B4001', '0000B', '074641067', 'Roman', 'Gentry'),
('B4002', '0000B', '132787516', 'Adriana', 'Jefferson'),
('B4003', '0000B', '082453927', 'Walton', 'Bradford'),
('B5001', '0000B', '011887518', 'Naomi', 'Maxwell'),
('B5002', '0000B', '769290236', 'Harold', 'Ellison'),
('B5003', '0000B', '020787061', 'Tessa', 'Phillips'),
('B6001', '0000B', '066493934', 'Sylvia', 'Hooper'),
('B6002', '0000B', '101094449', 'Amos', 'Lane'),
('B6003', '0000B', '490457708', 'Jesus', 'Avery'),
('B7001', '0000B', '715956156', 'Judith', 'Leonard'),
('B7002', '0000B', '014392377', 'Etta', 'Carter'),
('B7003', '0000B', '607939014', 'Oscar', 'Guerra'),
('B8001', '0000B', '546353364', 'Mabel', 'Salazar'),
('B8002', '0000B', '225492882', 'Leo', 'Mcgee'),
('B8003', '0000B', '562416783', 'Kelly', 'Buchanan'),

('C1001', '0000C', '166778493', 'Darius', 'Dickerson'),
('C1002', '0000C', '527955918', 'Maricela', 'Villarreal'),
('C1003', '0000C', '512345389', 'Dario', 'Cooper'),
('C2001', '0000C', '305642101', 'Duncan', 'Mclaughlin'),
('C2002', '0000C', '321501398', 'Elsie', 'Cross'),
('C2003', '0000C', '457636987', 'Wilda', 'Barker'),
('C3001', '0000C', '112426733', 'Wilbert', 'Tapia'),
('C3002', '0000C', '995622754', 'Marsha', 'Schmitt'),
('C3003', '0000C', '869744903', 'Jacklyn', 'Sloan'),
('C4001', '0000C', '552894605', 'Ellen', 'Whitney'),
('C4002', '0000C', '608765417', 'Al', 'Weaver'),
('C4003', '0000C', '616414308', 'Debbie', 'Salazar'),
('C5001', '0000C', '094221257', 'Sheena', 'Burns'),
('C5002', '0000C', '451007389', 'Colette', 'Mccarty'),
('C5003', '0000C', '700026563', 'Lakisha', 'Wilkerson'),
('C6001', '0000C', '877874181', 'Laura', 'Mejia'),
('C6002', '0000C', '900812957', 'Gene', 'Haas'),
('C6003', '0000C', '322436140', 'Sanford', 'Sexton'),
('C7001', '0000C', '917520714', 'Zachery', 'Bond'),
('C7002', '0000C', '649028751', 'Cathleen', 'Heath'),
('C7003', '0000C', '224930891', 'Alberta', 'Patterson'),
('C8001', '0000C', '658285028', 'Mohammed', 'Mccarty'),
('C8002', '0000C', '858583228', 'Lena', 'Cummings'),
('C8003', '0000C', '488269073', 'Manuel', 'Stark'),

('D1001', '0000D', '951699547', 'Esther', 'Gibson'),
('D1002', '0000D', '411957491', 'Mabel', 'Burgess'),
('D1003', '0000D', '523813333', 'Carlton', 'Bullock'),
('D2001', '0000D', '171175592', 'Janelle', 'Quinn'),
('D2002', '0000D', '628369156', 'Rupert', 'George'),
('D2003', '0000D', '978193820', 'Salvatore', 'Yang'),
('D3001', '0000D', '049110350', 'Adolfo', 'Montgomery'),
('D3002', '0000D', '595804419', 'Maritza', 'Underwood'),
('D3003', '0000D', '619931744', 'Carla', 'Travis'),
('D4001', '0000D', '565322077', 'Lonny', 'Deleon'),
('D4002', '0000D', '389369474', 'Jessie', 'Marquez'),
('D4003', '0000D', '225938036', 'Jewell', 'Monroe'),
('D5001', '0000D', '667560276', 'Andreas', 'Hogan'),
('D5002', '0000D', '281491464', 'Cleveland', 'Huynh'),
('D5003', '0000D', '995554411', 'Christian', 'Wiggins'),
('D6001', '0000D', '251379703', 'Gail', 'Gail'),
('D6002', '0000D', '358279012', 'Kim', 'Fernandez'),
('D6003', '0000D', '490270976', 'Carmella', 'Ellis'),
('D7001', '0000D', '715160800', 'Blanche', 'Lee'),
('D7002', '0000D', '388114991', 'Will', 'Whitehead'),
('D7003', '0000D', '272168321', 'Sandy', 'Mathews'),
('D8001', '0000D', '774460068', 'Stephanie', 'Hendrix'),
('D8002', '0000D', '183837745', 'Felton', 'Salas'),
('D8003', '0000D', '975911194', 'Brock', 'Mcclain'),

('E1001', '0000E', '435231065', 'Wilton', 'Ramsey'),
('E1002', '0000E', '621186925', 'Bennett', 'Booth'),
('E1003', '0000E', '100677677', 'Ester', 'Allison'),
('E2001', '0000E', '611653969', 'Tamra', 'Nguyen'),
('E2002', '0000E', '891393213', 'Lesley', 'Mclaughlin'),
('E2003', '0000E', '272582394', 'Barney', 'Glover'),
('E3001', '0000E', '535725140', 'Hai', 'Mathews'),
('E3002', '0000E', '565129529', 'Stuart', 'Wyatt'),
('E3003', '0000E', '377075033', 'Helena', 'Adams'),
('E4001', '0000E', '715768576', 'Darrin', 'Briggs'),
('E4002', '0000E', '177292303', 'Carly', 'Salinas'),
('E4003', '0000E', '524916451', 'Herminia', 'Malone'),
('E5001', '0000E', '426387062', 'Patrice', 'Mercer'),
('E5002', '0000E', '120564656', 'Louis', 'Conway'),
('E5003', '0000E', '698638401', 'Jarod', 'Watson'),
('E6001', '0000E', '076844624', 'Chrystal', 'Ballard'),
('E6002', '0000E', '486076589', 'Sergio', 'Vega'),
('E6003', '0000E', '186815281', 'Gilberto', 'Moody'),
('E7001', '0000E', '626534505', 'Aaron', 'Zimmerman'),
('E7002', '0000E', '555970597', 'Trenton', 'Harper'),
('E7003', '0000E', '638036690', 'Aldo', 'Mann'),
('E8001', '0000E', '569604377', 'Hassan', 'Lucas'),
('E8002', '0000E', '060784523', 'Bernard', 'Cain'),
('E8003', '0000E', '578821525', 'Merle', 'Torres');

INSERT INTO HOTEL (hotel_id, chain_id, manager_id, hotel_name, category, num_rooms, city, address, email, phone_number)
VALUES
('A0001', '0000A', 'A1001', 'Canopy', '3-star', 0, 'Lima', '1006 Upland Avenue', 'support@canopy.com', '419-233-9601'),
('A0002', '0000A', 'A2001', 'Conrad Hotel & Resort', '4-star', 0, 'Louisville', '922 Earnhardt Drive', 'support@conrad.com', '502-634-2737'),
('A0003', '0000A', 'A3001', 'Curio Collection', '3-star', 0, 'Milwaukee', '4824 Johnny Lane', 'support@curio.com', '414-332-6767'),
('A0004', '0000A', 'A4001', 'DoubleTree', '3-star', 0, 'San Francisco', '4733 Thompson Drive', 'support@doubletree.com', '747-232-0482'),
('A0005', '0000A', 'A5001', 'Hampton', '3-star', 0, 'Waterproof', '1241 Emerson Road', 'support@hampton.com', '318-749-7831'),
('A0006', '0000A', 'A6001', 'LXR Hotel & Resort', '4-star', 0, 'Louisville', '3431 Cerullo Road', 'support@lxr.com', '502-452-7369'),
('A0007', '0000A', 'A7001', 'Tru', '3-star', 0, 'Tallahassee', '4264 Virgil Street', 'support@tru.com', '850-228-6208'),
('A0008', '0000A', 'A8001', 'Embassy Suite', '5-star', 0, 'New Orleans', '3209 Big Indian', 'support@embassysuites.com', '504-568-9770'),

('B0001', '0000B', 'B1001', 'Hyatt Place', '3-star', 0, 'Fort Lauderdale', '4653 Foley Street', 'support@hyattplace.com', '304-694-1467'),
('B0002', '0000B', 'B2001', 'Spirit Ridge', '3-star', 0, 'Denver', '3718 Stark Hollow Road', 'support@spiritridge.com', '970-812-9599'),
('B0003', '0000B', 'B3001', 'Andaz', '3-star', 0, 'South Boston', '3049 Hinkle Lake Road', 'support@andaz.com', '269-499-9079'),
('B0004', '0000B', 'B4001', 'Park Hyatt', '3-star', 0, 'China Grove', '3812 Kelly Street', 'support@parkhyatt.com', '805-342-8021'),
('B0005', '0000B', 'B5001', 'The Anndore House', '4-star', 0, 'Denver', '1857 Sampson Street', 'support@anndore.com', '477-546-9498'),
('B0006', '0000B', 'B6001', 'Tempe Mission Palms', '4-star', 0, 'Defiance', '539 Hill Street', 'support@tempepalms.com', '771-279-2479'),
('B0007', '0000B', 'B7001', 'The Eliza Jane', '4-star', 0, 'Earlville', '397 Emeral Dreams Drive', 'support@elizajane.com', '334-595-3424'),
('B0008', '0000B', 'B8001', 'The Walper Hotel', '5-star', 0, 'Somerville', '3040 Gerald L. Bates Drive', 'support@walperhotel.com', '530-702-6218'),

('C0001', '0000C', 'C1001', 'AC Hotel', '3-star', 0, 'Westland', '2941 Bombardier Way', 'support@canopy.com', '586-729-3821'),
('C0002', '0000C', 'C2001', 'Autograph Collection', '3-star', 0, 'Ashtabula', '1572 Vineyard Drive', 'support@conrad.com', '440-536-1901'),
('C0003', '0000C', 'C3001', 'City Express', '3-star', 0, 'Tampa', '1197 Collins Street', 'support@curio.com', '813-400-0048'),
('C0004', '0000C', 'C4001', 'Delta Hotel', '3-star', 0, 'Atlanta', '1509 Stroop Hill Road', 'support@doubletree.com', '678-230-8898'),
('C0005', '0000C', 'C5001', 'Courtyard', '4-star', 0, 'Dallas', '4981 Deercove Drive', 'support@hampton.com', '214-552-3542'),
('C0006', '0000C', 'C6001', 'Moxy', '4-star', 0, 'Mira Loma', '4470 Carriage Court', 'support@lxr.com', '951-362-1487'),
('C0007', '0000C', 'C7001', 'Tribute', '4-star', 0, 'Doral', '1534 Warner Street', 'support@tru.com', '305-994-6699'),
('C0008', '0000C', 'C8001', 'EDITION', '5-star', 0, 'Tampa', '4696 Saints Alley', 'support@embassysuites.com', '813-694-0955'),

('D0001', '0000D', 'D1001', 'Ritz-Carlton', '1-star', 0, 'Tempe', '2734 East Avenue', 'support@ritzcarlton.com', '480-355-8447'),
('D0002', '0000D', 'D2001', 'Aman Resort', '1-star', 0, 'Brooklyn', '1499 Redbud Drive', 'support@amanresort.com', '347-890-8363'),
('D0003', '0000D', 'D3001', 'Four Seasons', '2-star', 0, 'Dallas', '2430 Ersel Street', 'support@fourseasons.com', '214-408-6999'),
('D0004', '0000D', 'D4001', 'Candlewood Suite', '2-star', 0, 'Naperville', '4517 Hickman Street', 'support@candlewoodsuite.com', '630-505-2028'),
('D0005', '0000D', 'D5001', 'Vignette', '2-star', 0, 'Graceville', '2431 Virgil Street', 'support@vignette.com', '850-263-5314'),
('D0006', '0000D', 'D6001', 'Kimpton', '2-star', 0, 'La Cygne', '4574 Charter Street', 'support@kimpton.com', '913-757-2423'),
('D0007', '0000D', 'D7001', 'Hotel Indigo', '3-star', 0, 'Princeton', '4568 Sherman Street', 'support@hotelindigo.com', '785-937-3298'),
('D0008', '0000D', 'D8001', 'InterContinetal', '5-star', 0, 'Brooklyn', '584 Pride Avenue', 'support@intercontinetal.com', '718-332-3923'),

('E0001', '0000E', 'E1001', 'AmericInn', '3-star', 0, 'Marion', '1031 Payne Street', 'support@americinn.com', '276-243-8678'),
('E0002', '0000E', 'E2001', 'Baymont', '4-star', 0, 'Wrangle Hill', '3710 Columbia Road', 'support@baymont.com', '302-838-4839'),
('E0003', '0000E', 'E3001', 'Dazzler', '4-star', 0, 'Detroit', '2768 Tuna Street', 'support@dazzler.com', '810-813-9213'),
('E0004', '0000E', 'E4001', 'Esplendor', '4-star', 0, 'New York', '1563 Redbud Drive', 'support@esplendor.com', '347-923-4460'),
('E0005', '0000E', 'E5001', 'Howard Johnson', '4-star', 0, 'Kingsport', '2450 Corbin Branch Road', 'support@howardjohnson.com', '423-502-4598'),
('E0006', '0000E', 'E6001', 'La Quinta', '5-star', 0, 'San Diego', '2575 Willison Street', 'support@laquinta.com', '619-242-8201'),
('E0007', '0000E', 'E7001', 'Origin', '5-star', 0, 'Marion', '3888 Shady Pines Drive', 'support@origin.com', '276-780-1328'),
('E0008', '0000E', 'E8001', 'TRYP', '5-star', 0, 'Mayhill', '1736 Cooks Mine Road', 'support@tryp.com', '505-203-6521');

UPDATE EMPLOYEE SET hotel_id = 'A0001' WHERE employee_id LIKE 'A1%';
UPDATE EMPLOYEE SET hotel_id = 'A0002' WHERE employee_id LIKE 'A2%';
UPDATE EMPLOYEE SET hotel_id = 'A0003' WHERE employee_id LIKE 'A3%';
UPDATE EMPLOYEE SET hotel_id = 'A0004' WHERE employee_id LIKE 'A4%';
UPDATE EMPLOYEE SET hotel_id = 'A0005' WHERE employee_id LIKE 'A5%';
UPDATE EMPLOYEE SET hotel_id = 'A0006' WHERE employee_id LIKE 'A6%';
UPDATE EMPLOYEE SET hotel_id = 'A0007' WHERE employee_id LIKE 'A7%';
UPDATE EMPLOYEE SET hotel_id = 'A0008' WHERE employee_id LIKE 'A8%';

UPDATE EMPLOYEE SET hotel_id = 'B0001' WHERE employee_id LIKE 'B1%';
UPDATE EMPLOYEE SET hotel_id = 'B0002' WHERE employee_id LIKE 'B2%';
UPDATE EMPLOYEE SET hotel_id = 'B0003' WHERE employee_id LIKE 'B3%';
UPDATE EMPLOYEE SET hotel_id = 'B0004' WHERE employee_id LIKE 'B4%';
UPDATE EMPLOYEE SET hotel_id = 'B0005' WHERE employee_id LIKE 'B5%';
UPDATE EMPLOYEE SET hotel_id = 'B0006' WHERE employee_id LIKE 'B6%';
UPDATE EMPLOYEE SET hotel_id = 'B0007' WHERE employee_id LIKE 'B7%';
UPDATE EMPLOYEE SET hotel_id = 'B0008' WHERE employee_id LIKE 'B8%';

UPDATE EMPLOYEE SET hotel_id = 'C0001' WHERE employee_id LIKE 'C1%';
UPDATE EMPLOYEE SET hotel_id = 'C0002' WHERE employee_id LIKE 'C2%';
UPDATE EMPLOYEE SET hotel_id = 'C0003' WHERE employee_id LIKE 'C3%';
UPDATE EMPLOYEE SET hotel_id = 'C0004' WHERE employee_id LIKE 'C4%';
UPDATE EMPLOYEE SET hotel_id = 'C0005' WHERE employee_id LIKE 'C5%';
UPDATE EMPLOYEE SET hotel_id = 'C0006' WHERE employee_id LIKE 'C6%';
UPDATE EMPLOYEE SET hotel_id = 'C0007' WHERE employee_id LIKE 'C7%';
UPDATE EMPLOYEE SET hotel_id = 'C0008' WHERE employee_id LIKE 'C8%';

UPDATE EMPLOYEE SET hotel_id = 'D0001' WHERE employee_id LIKE 'D1%';
UPDATE EMPLOYEE SET hotel_id = 'D0002' WHERE employee_id LIKE 'D2%';
UPDATE EMPLOYEE SET hotel_id = 'D0003' WHERE employee_id LIKE 'D3%';
UPDATE EMPLOYEE SET hotel_id = 'D0004' WHERE employee_id LIKE 'D4%';
UPDATE EMPLOYEE SET hotel_id = 'D0005' WHERE employee_id LIKE 'D5%';
UPDATE EMPLOYEE SET hotel_id = 'D0006' WHERE employee_id LIKE 'D6%';
UPDATE EMPLOYEE SET hotel_id = 'D0007' WHERE employee_id LIKE 'D7%';
UPDATE EMPLOYEE SET hotel_id = 'D0008' WHERE employee_id LIKE 'D8%';

UPDATE EMPLOYEE SET hotel_id = 'E0001' WHERE employee_id LIKE 'E1%';
UPDATE EMPLOYEE SET hotel_id = 'E0002' WHERE employee_id LIKE 'E2%';
UPDATE EMPLOYEE SET hotel_id = 'E0003' WHERE employee_id LIKE 'E3%';
UPDATE EMPLOYEE SET hotel_id = 'E0004' WHERE employee_id LIKE 'E4%';
UPDATE EMPLOYEE SET hotel_id = 'E0005' WHERE employee_id LIKE 'E5%';
UPDATE EMPLOYEE SET hotel_id = 'E0006' WHERE employee_id LIKE 'E6%';
UPDATE EMPLOYEE SET hotel_id = 'E0007' WHERE employee_id LIKE 'E7%';
UPDATE EMPLOYEE SET hotel_id = 'E0008' WHERE employee_id LIKE 'E8%';


INSERT INTO EMPLOYEE_POSITION (employee_id, position, hotel_id)
VALUES
('A1001', 'Manager', 'A0001'),
('A2001', 'Manager', 'A0002'),
('A3001', 'Manager', 'A0003'),
('A4001', 'Manager', 'A0004'),
('A5001', 'Manager', 'A0005'),
('A6001', 'Manager', 'A0006'),
('A7001', 'Manager', 'A0007'),
('A8001', 'Manager', 'A0008'),
('A1002', 'Front Desk Clerk', 'A0001'),
('A2002', 'Front Desk Clerk', 'A0002'),
('A3002', 'Front Desk Clerk', 'A0003'),
('A4002', 'Front Desk Clerk', 'A0004'),
('A5002', 'Front Desk Clerk', 'A0005'),
('A6002', 'Front Desk Clerk', 'A0006'),
('A7002', 'Front Desk Clerk', 'A0007'),
('A8002', 'Front Desk Clerk', 'A0008'),
('A1003', 'Housekeeping', 'A0001'),
('A2003', 'Housekeeping', 'A0002'),
('A3003', 'Housekeeping', 'A0003'),
('A4003', 'Housekeeping', 'A0004'),
('A5003', 'Housekeeping', 'A0005'),
('A6003', 'Housekeeping', 'A0006'),
('A7003', 'Housekeeping', 'A0007'),
('A8003', 'Housekeeping', 'A0008'),

('B1001', 'Manager', 'B0001'),
('B2001', 'Manager', 'B0002'),
('B3001', 'Manager', 'B0003'),
('B4001', 'Manager', 'B0004'),
('B5001', 'Manager', 'B0005'),
('B6001', 'Manager', 'B0006'),
('B7001', 'Manager', 'B0007'),
('B8001', 'Manager', 'B0008'),
('B1002', 'Front Desk Clerk', 'B0001'),
('B2002', 'Front Desk Clerk', 'B0002'),
('B3002', 'Front Desk Clerk', 'B0003'),
('B4002', 'Front Desk Clerk', 'B0004'),
('B5002', 'Front Desk Clerk', 'B0005'),
('B6002', 'Front Desk Clerk', 'B0006'),
('B7002', 'Front Desk Clerk', 'B0007'),
('B8002', 'Front Desk Clerk', 'B0008'),
('B1003', 'Housekeeping', 'B0001'),
('B2003', 'Housekeeping', 'B0002'),
('B3003', 'Housekeeping', 'B0003'),
('B4003', 'Housekeeping', 'B0004'),
('B5003', 'Housekeeping', 'B0005'),
('B7003', 'Housekeeping', 'B0006'),
('B6003', 'Housekeeping', 'B0007'),
('B8003', 'Housekeeping', 'B0008'),

('C1001', 'Manager', 'C0001'),
('C2001', 'Manager', 'C0002'),
('C3001', 'Manager', 'C0003'),
('C4001', 'Manager', 'C0004'),
('C5001', 'Manager', 'C0005'),
('C6001', 'Manager', 'C0006'),
('C7001', 'Manager', 'C0007'),
('C8001', 'Manager', 'C0008'),
('C1002', 'Front Desk Clerk', 'C0001'),
('C2002', 'Front Desk Clerk', 'C0002'),
('C3002', 'Front Desk Clerk', 'C0003'),
('C4002', 'Front Desk Clerk', 'C0004'),
('C5002', 'Front Desk Clerk', 'C0005'),
('C6002', 'Front Desk Clerk', 'C0006'),
('C7002', 'Front Desk Clerk', 'C0007'),
('C8002', 'Front Desk Clerk', 'C0008'),
('C1003', 'Housekeeping', 'C0001'),
('C2003', 'Housekeeping', 'C0002'),
('C3003', 'Housekeeping', 'C0003'),
('C4003', 'Housekeeping', 'C0004'),
('C5003', 'Housekeeping', 'C0005'),
('C6003', 'Housekeeping', 'C0006'),
('C7003', 'Housekeeping', 'C0007'),
('C8003', 'Housekeeping', 'C0008'),

('D1001', 'Manager', 'D0001'),
('D2001', 'Manager', 'D0002'),
('D3001', 'Manager', 'D0003'),
('D4001', 'Manager', 'D0004'),
('D5001', 'Manager', 'D0005'),
('D6001', 'Manager', 'D0006'),
('D7001', 'Manager', 'D0007'),
('D8001', 'Manager', 'D0008'),
('D1002', 'Front Desk Clerk', 'D0001'),
('D2002', 'Front Desk Clerk', 'D0002'),
('D3002', 'Front Desk Clerk', 'D0003'),
('D4002', 'Front Desk Clerk', 'D0004'),
('D5002', 'Front Desk Clerk', 'D0005'),
('D6002', 'Front Desk Clerk', 'D0006'),
('D7002', 'Front Desk Clerk', 'D0007'),
('D8002', 'Front Desk Clerk', 'D0008'),
('D1003', 'Housekeeping', 'D0001'),
('D2003', 'Housekeeping', 'D0002'),
('D3003', 'Housekeeping', 'D0003'),
('D4003', 'Housekeeping', 'D0004'),
('D5003', 'Housekeeping', 'D0005'),
('D6003', 'Housekeeping', 'D0006'),
('D7003', 'Housekeeping', 'D0007'),
('D8003', 'Housekeeping', 'D0008'),

('E1001', 'Manager', 'E0001'),
('E2001', 'Manager', 'E0002'),
('E3001', 'Manager', 'E0003'),
('E4001', 'Manager', 'E0004'),
('E5001', 'Manager', 'E0005'),
('E6001', 'Manager', 'E0006'),
('E7001', 'Manager', 'E0007'),
('E8001', 'Manager', 'E0008'),
('E1002', 'Front Desk Clerk', 'E0001'),
('E2002', 'Front Desk Clerk', 'E0002'),
('E3002', 'Front Desk Clerk', 'E0003'),
('E4002', 'Front Desk Clerk', 'E0004'),
('E5002', 'Front Desk Clerk', 'E0005'),
('E6002', 'Front Desk Clerk', 'E0006'),
('E7002', 'Front Desk Clerk', 'E0007'),
('E8002', 'Front Desk Clerk', 'E0008'),
('E1003', 'Housekeeping', 'E0001'),
('E2003', 'Housekeeping', 'E0002'),
('E3003', 'Housekeeping', 'E0003'),
('E4003', 'Housekeeping', 'E0004'),
('E5003', 'Housekeeping', 'E0005'),
('E6003', 'Housekeeping', 'E0006'),
('E7003', 'Housekeeping', 'E0007'),
('E8003', 'Housekeeping', 'E0008');

INSERT INTO ROOM (hotel_id, room_num, price, capacity, view_type, can_extend, has_problems, available)
VALUES
('A0001', 1, 100.00, 1, 'sea view', TRUE, FALSE, TRUE),
('A0001', 2, 200.00, 2, 'mountain view', FALSE, FALSE, TRUE),
('A0001', 3, 300.00, 3, 'sea view', TRUE, FALSE, TRUE),
('A0001', 4, 400.00, 4, 'mountain view', FALSE, FALSE, TRUE),
('A0001', 5, 500.00, 5, 'sea view', TRUE, FALSE, TRUE),
('A0002', 1, 100.00, 1, 'mountain view', FALSE, FALSE, TRUE),
('A0002', 2, 200.00, 2, 'sea view', TRUE, FALSE, TRUE),
('A0002', 3, 300.00, 3, 'mountain view', FALSE, FALSE, TRUE),
('A0002', 4, 400.00, 4, 'sea view', TRUE, FALSE, TRUE),
('A0002', 5, 500.00, 5, 'mountain view', FALSE, TRUE, TRUE),
('A0003', 1, 100.00, 1, 'sea view', TRUE, FALSE, TRUE),
('A0003', 2, 200.00, 2, 'mountain view', FALSE, FALSE, TRUE),
('A0003', 3, 300.00, 3, 'sea view', TRUE, FALSE, TRUE),
('A0003', 4, 400.00, 4, 'mountain view', FALSE, FALSE, TRUE),
('A0003', 5, 500.00, 5, 'sea view', TRUE, FALSE, TRUE),
('A0004', 1, 100.00, 1, 'mountain view', FALSE, FALSE, TRUE),
('A0004', 2, 200.00, 2, 'sea view', TRUE, FALSE, TRUE),
('A0004', 3, 300.00, 3, 'mountain view', FALSE, FALSE, TRUE),
('A0004', 4, 400.00, 4, 'sea view', TRUE, FALSE, TRUE),
('A0004', 5, 500.00, 5, 'mountain view', FALSE, FALSE, TRUE),
('A0005', 1, 100.00, 1, 'sea view', TRUE, FALSE, TRUE),
('A0005', 2, 200.00, 2, 'mountain view', FALSE, FALSE, TRUE),
('A0005', 3, 300.00, 3, 'sea view', TRUE, FALSE, TRUE),
('A0005', 4, 400.00, 4, 'mountain view', FALSE, FALSE, TRUE),
('A0005', 5, 500.00, 5, 'sea view', TRUE, FALSE, TRUE),
('A0006', 1, 100.00, 1, 'mountain view', FALSE, TRUE, TRUE),
('A0006', 2, 200.00, 2, 'sea view', TRUE, FALSE, TRUE),
('A0006', 3, 300.00, 3, 'mountain view', FALSE, FALSE, TRUE),
('A0006', 4, 400.00, 4, 'sea view', TRUE, FALSE, TRUE),
('A0006', 5, 500.00, 5, 'mountain view', FALSE, FALSE, TRUE),
('A0007', 1, 100.00, 1, 'sea view', TRUE, FALSE, TRUE),
('A0007', 2, 200.00, 2, 'mountain view', FALSE, FALSE, TRUE),
('A0007', 3, 300.00, 3, 'sea view', TRUE, FALSE, TRUE),
('A0007', 4, 400.00, 4, 'mountain view', FALSE, FALSE, TRUE),
('A0007', 5, 500.00, 5, 'sea view', TRUE, FALSE, TRUE),
('A0008', 1, 100.00, 1, 'mountain view', FALSE, FALSE, TRUE),
('A0008', 2, 200.00, 2, 'sea view', TRUE, FALSE, TRUE),
('A0008', 3, 300.00, 3, 'mountain view', FALSE, FALSE, TRUE),
('A0008', 4, 400.00, 4, 'sea view', TRUE, FALSE, TRUE),
('A0008', 5, 500.00, 5, 'mountain view', FALSE, FALSE, TRUE),

('B0001', 1, 100.00, 1, 'sea view', TRUE, FALSE, TRUE),
('B0001', 2, 200.00, 2, 'mountain view', FALSE, FALSE, TRUE),
('B0001', 3, 300.00, 3, 'sea view', TRUE, FALSE, TRUE),
('B0001', 4, 400.00, 4, 'mountain view', FALSE, FALSE, TRUE),
('B0001', 5, 500.00, 5, 'sea view', TRUE, FALSE, TRUE),
('B0002', 1, 100.00, 1, 'mountain view', FALSE, FALSE, TRUE),
('B0002', 2, 200.00, 2, 'sea view', TRUE, FALSE, TRUE),
('B0002', 3, 300.00, 3, 'mountain view', FALSE, FALSE, TRUE),
('B0002', 4, 400.00, 4, 'sea view', TRUE, FALSE, TRUE),
('B0002', 5, 500.00, 5, 'mountain view', FALSE, TRUE, TRUE),
('B0003', 1, 100.00, 1, 'sea view', TRUE, FALSE, TRUE),
('B0003', 2, 200.00, 2, 'mountain view', FALSE, FALSE, TRUE),
('B0003', 3, 300.00, 3, 'sea view', TRUE, FALSE, TRUE),
('B0003', 4, 400.00, 4, 'mountain view', FALSE, FALSE, TRUE),
('B0003', 5, 500.00, 5, 'sea view', TRUE, FALSE, TRUE),
('B0004', 1, 100.00, 1, 'mountain view', FALSE, FALSE, TRUE),
('B0004', 2, 200.00, 2, 'sea view', TRUE, FALSE, TRUE),
('B0004', 3, 300.00, 3, 'mountain view', FALSE, FALSE, TRUE),
('B0004', 4, 400.00, 4, 'sea view', TRUE, FALSE, TRUE),
('B0004', 5, 500.00, 5, 'mountain view', FALSE, FALSE, TRUE),
('B0005', 1, 100.00, 1, 'sea view', TRUE, FALSE, TRUE),
('B0005', 2, 200.00, 2, 'mountain view', FALSE, FALSE, TRUE),
('B0005', 3, 300.00, 3, 'sea view', TRUE, FALSE, TRUE),
('B0005', 4, 400.00, 4, 'mountain view', FALSE, FALSE, TRUE),
('B0005', 5, 500.00, 5, 'sea view', TRUE, FALSE, TRUE),
('B0006', 1, 100.00, 1, 'mountain view', FALSE, FALSE, TRUE),
('B0006', 2, 200.00, 2, 'sea view', TRUE, FALSE, TRUE),
('B0006', 3, 300.00, 3, 'mountain view', FALSE, FALSE, TRUE),
('B0006', 4, 400.00, 4, 'sea view', TRUE, FALSE, TRUE), 
('B0006', 5, 500.00, 5, 'mountain view', FALSE, FALSE, TRUE),
('B0007', 1, 100.00, 1, 'sea view', TRUE, FALSE, TRUE),
('B0007', 2, 200.00, 2, 'mountain view', FALSE, FALSE, TRUE),
('B0007', 3, 300.00, 3, 'sea view', TRUE, FALSE, TRUE), 
('B0007', 4, 400.00, 4, 'mountain view', FALSE, FALSE, TRUE), 
('B0007', 5, 500.00, 5, 'sea view', TRUE, FALSE, TRUE),
('B0008', 1, 100.00, 1, 'mountain view', FALSE, FALSE, TRUE),
('B0008', 2, 200.00, 2, 'sea view', TRUE, FALSE, TRUE),
('B0008', 3, 300.00, 3, 'mountain view', FALSE, FALSE, TRUE), 
('B0008', 4, 400.00, 4, 'sea view', TRUE, FALSE, TRUE),
('B0008', 5, 500.00, 5, 'mountain view', FALSE, FALSE, TRUE),

('C0001', 1, 100.00, 1, 'sea view', TRUE, FALSE, TRUE),
('C0001', 2, 200.00, 2, 'mountain view', FALSE, FALSE, TRUE),
('C0001', 3, 300.00, 3, 'sea view', TRUE, FALSE, TRUE),
('C0001', 4, 400.00, 4, 'mountain view', FALSE, FALSE, TRUE),
('C0001', 5, 500.00, 5, 'sea view', TRUE, FALSE, TRUE),
('C0002', 1, 100.00, 1, 'mountain view', FALSE, TRUE, TRUE),
('C0002', 2, 200.00, 2, 'sea view', TRUE, FALSE, TRUE),
('C0002', 3, 300.00, 3, 'mountain view', FALSE, FALSE, TRUE),
('C0002', 4, 400.00, 4, 'sea view', TRUE, FALSE, TRUE),
('C0002', 5, 500.00, 5, 'mountain view', FALSE, TRUE, TRUE),
('C0003', 1, 100.00, 1, 'sea view', TRUE, FALSE, TRUE),
('C0003', 2, 200.00, 2, 'mountain view', FALSE, FALSE, TRUE),
('C0003', 3, 300.00, 3, 'sea view', TRUE, FALSE, TRUE),
('C0003', 4, 400.00, 4, 'mountain view', FALSE, FALSE, TRUE),
('C0003', 5, 500.00, 5, 'sea view', TRUE, FALSE, TRUE),
('C0004', 1, 100.00, 1, 'mountain view', FALSE, FALSE, TRUE),
('C0004', 2, 200.00, 2, 'sea view', TRUE, FALSE, TRUE),
('C0004', 3, 300.00, 3, 'mountain view', FALSE, FALSE, TRUE),
('C0004', 4, 400.00, 4, 'sea view', TRUE, FALSE, TRUE),
('C0004', 5, 500.00, 5, 'mountain view', FALSE, FALSE, TRUE),
('C0005', 1, 100.00, 1, 'sea view', TRUE, FALSE, TRUE),
('C0005', 2, 200.00, 2, 'mountain view', FALSE, FALSE, TRUE),
('C0005', 3, 300.00, 3, 'sea view', TRUE, FALSE, TRUE),
('C0005', 4, 400.00, 4, 'mountain view', FALSE, FALSE, TRUE),
('C0005', 5, 500.00, 5, 'sea view', TRUE, FALSE, TRUE),
('C0006', 1, 100.00, 1, 'mountain view', FALSE, FALSE, TRUE),
('C0006', 2, 200.00, 2, 'sea view', TRUE, FALSE, TRUE),
('C0006', 3, 300.00, 3, 'mountain view', FALSE, FALSE, TRUE),
('C0006', 4, 400.00, 4, 'sea view', TRUE, FALSE, TRUE),
('C0006', 5, 500.00, 5, 'mountain view', FALSE, FALSE, TRUE),
('C0007', 1, 100.00, 1, 'sea view', TRUE, FALSE, TRUE),
('C0007', 2, 200.00, 2, 'mountain view', FALSE, FALSE, TRUE),
('C0007', 3, 300.00, 3, 'sea view', TRUE, FALSE, TRUE),
('C0007', 4, 400.00, 4, 'mountain view', FALSE, FALSE, TRUE),
('C0007', 5, 500.00, 5, 'sea view', TRUE, FALSE, TRUE),
('C0008', 1, 100.00, 1, 'mountain view', FALSE, TRUE, TRUE),
('C0008', 2, 200.00, 2, 'sea view', TRUE, FALSE, TRUE),
('C0008', 3, 300.00, 3, 'mountain view', FALSE, FALSE, TRUE), 
('C0008', 4, 400.00, 4, 'sea view', TRUE, FALSE, TRUE),
('C0008', 5, 500.00, 5, 'mountain view', FALSE, FALSE, TRUE),

('D0001', 1, 100.00, 1, 'sea view', TRUE, FALSE, TRUE),
('D0001', 2, 200.00, 2, 'mountain view', FALSE, FALSE, TRUE),
('D0001', 3, 300.00, 3, 'sea view', TRUE, FALSE, TRUE),
('D0001', 4, 400.00, 4, 'mountain view', FALSE, FALSE, TRUE),
('D0001', 5, 500.00, 5, 'sea view', TRUE, FALSE, TRUE),
('D0002', 1, 100.00, 1, 'mountain view', FALSE, FALSE, TRUE),
('D0002', 2, 200.00, 2, 'sea view', TRUE, FALSE, TRUE),
('D0002', 3, 300.00, 3, 'mountain view', FALSE, FALSE, TRUE),
('D0002', 4, 400.00, 4, 'sea view', TRUE, FALSE, TRUE),
('D0002', 5, 500.00, 5, 'mountain view', FALSE, TRUE, TRUE),
('D0003', 1, 100.00, 1, 'sea view', TRUE, FALSE, TRUE),
('D0003', 2, 200.00, 2, 'mountain view', FALSE, TRUE, TRUE),
('D0003', 3, 300.00, 3, 'sea view', TRUE, FALSE, TRUE),
('D0003', 4, 400.00, 4, 'mountain view', FALSE, FALSE, TRUE),
('D0003', 5, 500.00, 5, 'sea view', TRUE, FALSE, TRUE),
('D0004', 1, 100.00, 1, 'mountain view', FALSE, FALSE, TRUE),
('D0004', 2, 200.00, 2, 'sea view', TRUE, FALSE, TRUE),
('D0004', 3, 300.00, 3, 'mountain view', FALSE, FALSE, TRUE),
('D0004', 4, 400.00, 4, 'sea view', TRUE, FALSE, TRUE),
('D0004', 5, 500.00, 5, 'mountain view', FALSE, FALSE, TRUE),
('D0005', 1, 100.00, 1, 'sea view', TRUE, FALSE, TRUE),
('D0005', 2, 200.00, 2, 'mountain view', FALSE, FALSE, TRUE),
('D0005', 3, 300.00, 3, 'sea view', TRUE, FALSE, TRUE),
('D0005', 4, 400.00, 4, 'mountain view', FALSE, FALSE, TRUE),
('D0005', 5, 500.00, 5, 'sea view', TRUE, FALSE, TRUE),
('D0006', 1, 100.00, 1, 'mountain view', FALSE, TRUE, TRUE),
('D0006', 2, 200.00, 2, 'sea view', TRUE, FALSE, TRUE),
('D0006', 3, 300.00, 3, 'mountain view', FALSE, FALSE, TRUE),
('D0006', 4, 400.00, 4, 'sea view', TRUE, FALSE, TRUE), 
('D0006', 5, 500.00, 5, 'mountain view', FALSE, FALSE, TRUE),
('D0007', 1, 100.00, 1, 'sea view', TRUE, FALSE, TRUE),
('D0007', 2, 200.00, 2, 'mountain view', FALSE, FALSE, TRUE),
('D0007', 3, 300.00, 3, 'sea view', TRUE, FALSE, TRUE), 
('D0007', 4, 400.00, 4, 'mountain view', FALSE, FALSE, TRUE),
('D0007', 5, 500.00, 5, 'sea view', TRUE, FALSE, TRUE),
('D0008', 1, 100.00, 1, 'mountain view', FALSE, FALSE, TRUE),
('D0008', 2, 200.00, 2, 'sea view', TRUE, FALSE, TRUE),
('D0008', 3, 300.00, 3, 'mountain view', FALSE, FALSE, TRUE), 
('D0008', 4, 400.00, 4, 'sea view', TRUE, FALSE, TRUE),
('D0008', 5, 500.00, 5, 'mountain view', FALSE, FALSE, TRUE),

('E0001', 1, 100.00, 1, 'sea view', TRUE, FALSE, TRUE),
('E0001', 2, 200.00, 2, 'mountain view', FALSE, FALSE, TRUE),
('E0001', 3, 300.00, 3, 'sea view', TRUE, FALSE, TRUE),
('E0001', 4, 400.00, 4, 'mountain view', FALSE, TRUE, TRUE),
('E0001', 5, 500.00, 5, 'sea view', TRUE, FALSE, TRUE),
('E0002', 1, 100.00, 1, 'mountain view', FALSE, FALSE, TRUE),
('E0002', 2, 200.00, 2, 'sea view', TRUE, FALSE, TRUE),
('E0002', 3, 300.00, 3, 'mountain view', FALSE, FALSE, TRUE),
('E0002', 4, 400.00, 4, 'sea view', TRUE, FALSE, TRUE),
('E0002', 5, 500.00, 5, 'mountain view', FALSE, TRUE, TRUE),
('E0003', 1, 100.00, 1, 'sea view', TRUE, FALSE, TRUE),
('E0003', 2, 200.00, 2, 'mountain view', FALSE, FALSE, TRUE),
('E0003', 3, 300.00, 3, 'sea view', TRUE, FALSE, TRUE),
('E0003', 4, 400.00, 4, 'mountain view', FALSE, FALSE, TRUE),
('E0003', 5, 500.00, 5, 'sea view', TRUE, FALSE, TRUE),
('E0004', 1, 100.00, 1, 'mountain view', FALSE, FALSE, TRUE),
('E0004', 2, 200.00, 2, 'sea view', TRUE, FALSE, TRUE),
('E0004', 3, 300.00, 3, 'mountain view', FALSE, FALSE, TRUE),
('E0004', 4, 400.00, 4, 'sea view', TRUE, FALSE, TRUE),
('E0004', 5, 500.00, 5, 'mountain view', FALSE, FALSE, TRUE),
('E0005', 1, 100.00, 1, 'sea view', TRUE, FALSE, TRUE),
('E0005', 2, 200.00, 2, 'mountain view', FALSE, FALSE, TRUE),
('E0005', 3, 300.00, 3, 'sea view', TRUE, FALSE, TRUE),
('E0005', 4, 400.00, 4, 'mountain view', FALSE, FALSE, TRUE),
('E0005', 5, 500.00, 5, 'sea view', TRUE, FALSE, TRUE),
('E0006', 1, 100.00, 1, 'mountain view', FALSE, FALSE, TRUE),
('E0006', 2, 200.00, 2, 'sea view', TRUE, FALSE, TRUE),
('E0006', 3, 300.00, 3, 'mountain view', FALSE, FALSE, TRUE),
('E0006', 4, 400.00, 4, 'sea view', TRUE, FALSE, TRUE),
('E0006', 5, 500.00, 5, 'mountain view', FALSE, FALSE, TRUE),
('E0007', 1, 100.00, 1, 'sea view', TRUE, FALSE, TRUE),
('E0007', 2, 200.00, 2, 'mountain view', FALSE, FALSE, TRUE),
('E0007', 3, 300.00, 3, 'sea view', TRUE, FALSE, TRUE),
('E0007', 4, 400.00, 4, 'mountain view', FALSE, FALSE, TRUE), 
('E0007', 5, 500.00, 5, 'sea view', TRUE, FALSE, TRUE),
('E0008', 1, 100.00, 1, 'mountain view', FALSE, FALSE, TRUE),
('E0008', 2, 200.00, 2, 'sea view', TRUE, FALSE, TRUE),
('E0008', 3, 300.00, 3, 'mountain view', FALSE, TRUE, TRUE), 
('E0008', 4, 400.00, 4, 'sea view', TRUE, FALSE, TRUE),
('E0008', 5, 500.00, 5, 'mountain view', FALSE, TRUE, TRUE);

INSERT INTO ROOM_AMENITY (hotel_id, room_num, amenity)
VALUES
('A0001', 1, 'TV'),
('A0001', 2, 'TV'),
('A0001', 3, 'TV'),
('A0001', 4, 'TV'),
('A0001', 5, 'TV'),
('A0002', 1, 'TV'),
('A0002', 2, 'TV'),
('A0002', 3, 'TV'),
('A0002', 4, 'TV'),
('A0002', 5, 'TV'),
('A0003', 1, 'Pool'),
('A0003', 2, 'Pool'),
('A0003', 3, 'Pool'),
('A0003', 4, 'Pool'),
('A0003', 5, 'Pool'),
('A0004', 1, 'Pool'),
('A0004', 2, 'Pool'),
('A0004', 3, 'Pool'),
('A0004', 4, 'Pool'),
('A0004', 5, 'Pool'),
('A0005', 1, 'TV'),
('A0005', 2, 'TV'),
('A0005', 3, 'TV'),
('A0005', 4, 'TV'),
('A0005', 5, 'TV'),
('A0006', 1, 'TV'),
('A0006', 2, 'TV'),
('A0006', 3, 'TV'),
('A0006', 4, 'TV'),
('A0006', 5, 'TV'),
('A0007', 1, 'Gym'),
('A0007', 2, 'Gym'),
('A0007', 3, 'Gym'),
('A0007', 4, 'Gym'),
('A0007', 5, 'Gym'),
('A0008', 1, 'Gym'),
('A0008', 2, 'Gym'),
('A0008', 3, 'Gym'),
('A0008', 4, 'Gym'),
('A0008', 5, 'Gym'),

('B0001', 1, 'TV'),
('B0001', 2, 'TV'),
('B0001', 3, 'TV'),
('B0001', 4, 'TV'),
('B0001', 5, 'TV'),
('B0002', 1, 'TV'),
('B0002', 2, 'TV'),
('B0002', 3, 'TV'),
('B0002', 4, 'TV'),
('B0002', 5, 'TV'),
('B0003', 1, 'Pool'),
('B0003', 2, 'Pool'),
('B0003', 3, 'Pool'),
('B0003', 4, 'Pool'),
('B0003', 5, 'Pool'),
('B0004', 1, 'Pool'),
('B0004', 2, 'Pool'),
('B0004', 3, 'Pool'),
('B0004', 4, 'Pool'),
('B0004', 5, 'Pool'),
('B0005', 1, 'TV'),
('B0005', 2, 'TV'),
('B0005', 3, 'TV'),
('B0005', 4, 'TV'),
('B0005', 5, 'TV'),
('B0006', 1, 'TV'),
('B0006', 2, 'TV'),
('B0006', 3, 'TV'),
('B0006', 4, 'TV'),
('B0006', 5, 'TV'),
('B0007', 1, 'Gym'),
('B0007', 2, 'Gym'),
('B0007', 3, 'Gym'),
('B0007', 4, 'Gym'),
('B0007', 5, 'Gym'),
('B0008', 1, 'Gym'),
('B0008', 2, 'Gym'),
('B0008', 3, 'Gym'),
('B0008', 4, 'Gym'),
('B0008', 5, 'Gym'),

('C0001', 1, 'TV'),
('C0001', 2, 'TV'),
('C0001', 3, 'TV'),
('C0001', 4, 'TV'),
('C0001', 5, 'TV'),
('C0002', 1, 'TV'),
('C0002', 2, 'TV'),
('C0002', 3, 'TV'),
('C0002', 4, 'TV'),
('C0002', 5, 'TV'),
('C0003', 1, 'Pool'),
('C0003', 2, 'Pool'),
('C0003', 3, 'Pool'),
('C0003', 4, 'Pool'),
('C0003', 5, 'Pool'),
('C0004', 1, 'Pool'),
('C0004', 2, 'Pool'),
('C0004', 3, 'Pool'),
('C0004', 4, 'Pool'),
('C0004', 5, 'Pool'),
('C0005', 1, 'TV'),
('C0005', 2, 'TV'),
('C0005', 3, 'TV'),
('C0005', 4, 'TV'),
('C0005', 5, 'TV'),
('C0006', 1, 'TV'),
('C0006', 2, 'TV'),
('C0006', 3, 'TV'),
('C0006', 4, 'TV'),
('C0006', 5, 'TV'),
('C0007', 1, 'Gym'),
('C0007', 2, 'Gym'),
('C0007', 3, 'Gym'),
('C0007', 4, 'Gym'),
('C0007', 5, 'Gym'),
('C0008', 1, 'Gym'),
('C0008', 2, 'Gym'),
('C0008', 3, 'Gym'),
('C0008', 4, 'Gym'),
('C0008', 5, 'Gym'),

('D0001', 1, 'TV'),
('D0001', 2, 'TV'),
('D0001', 3, 'TV'),
('D0001', 4, 'TV'),
('D0001', 5, 'TV'),
('D0002', 1, 'TV'),
('D0002', 2, 'TV'),
('D0002', 3, 'TV'),
('D0002', 4, 'TV'),
('D0002', 5, 'TV'),
('D0003', 1, 'Pool'),
('D0003', 2, 'Pool'),
('D0003', 3, 'Pool'),
('D0003', 4, 'Pool'),
('D0003', 5, 'Pool'),
('D0004', 1, 'Pool'),
('D0004', 2, 'Pool'),
('D0004', 3, 'Pool'),
('D0004', 4, 'Pool'),
('D0004', 5, 'Pool'),
('D0005', 1, 'TV'),
('D0005', 2, 'TV'),
('D0005', 3, 'TV'),
('D0005', 4, 'TV'),
('D0005', 5, 'TV'),
('D0006', 1, 'TV'),
('D0006', 2, 'TV'),
('D0006', 3, 'TV'),
('D0006', 4, 'TV'),
('D0006', 5, 'TV'),
('D0007', 1, 'Gym'),
('D0007', 2, 'Gym'),
('D0007', 3, 'Gym'),
('D0007', 4, 'Gym'),
('D0007', 5, 'Gym'),
('D0008', 1, 'Gym'),
('D0008', 2, 'Gym'),
('D0008', 3, 'Gym'),
('D0008', 4, 'Gym'),
('D0008', 5, 'Gym'),

('E0001', 1, 'TV'),
('E0001', 2, 'TV'),
('E0001', 3, 'TV'),
('E0001', 4, 'TV'),
('E0001', 5, 'TV'),
('E0002', 1, 'TV'),
('E0002', 2, 'TV'),
('E0002', 3, 'TV'),
('E0002', 4, 'TV'),
('E0002', 5, 'TV'),
('E0003', 1, 'Pool'),
('E0003', 2, 'Pool'),
('E0003', 3, 'Pool'),
('E0003', 4, 'Pool'),
('E0003', 5, 'Pool'),
('E0004', 1, 'Pool'),
('E0004', 2, 'Pool'),
('E0004', 3, 'Pool'),
('E0004', 4, 'Pool'),
('E0004', 5, 'Pool'),
('E0005', 1, 'TV'),
('E0005', 2, 'TV'),
('E0005', 3, 'TV'),
('E0005', 4, 'TV'),
('E0005', 5, 'TV'),
('E0006', 1, 'TV'),
('E0006', 2, 'TV'),
('E0006', 3, 'TV'),
('E0006', 4, 'TV'),
('E0006', 5, 'TV'),
('E0007', 1, 'Gym'),
('E0007', 2, 'Gym'),
('E0007', 3, 'Gym'),
('E0007', 4, 'Gym'),
('E0007', 5, 'Gym'),
('E0008', 1, 'Gym'),
('E0008', 2, 'Gym'),
('E0008', 3, 'Gym'),
('E0008', 4, 'Gym'),
('E0008', 5, 'Gym');