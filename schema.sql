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
    chain_id INT AUTO_INCREMENT,
    chain_name VARCHAR(30) UNIQUE NOT NULL,
    num_hotels INTEGER,
    email VARCHAR(30),
    phone_number VARCHAR(20),
    PRIMARY KEY (chain_id)
);

CREATE TABLE IF NOT EXISTS CENTRAL_OFFICE (
    chain_name VARCHAR(30) NOT NULL,
    address VARCHAR(30) NOT NULL,
    PRIMARY KEY (chain_name, address),
    FOREIGN KEY (chain_name) REFERENCES HOTEL_CHAIN (chain_name)
		ON DELETE CASCADE
		ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS CUSTOMER (
    customer_id INT AUTO_INCREMENT,
    username VARCHAR(30) UNIQUE NOT NULL,
    password VARCHAR(30) NOT NULL,
    sxn CHAR(9) UNIQUE NOT NULL,
    first_name VARCHAR(30) NOT NULL,
    last_name VARCHAR(30) NOT NULL,
    address VARCHAR(30) NOT NULL,
    registration_date DATE NOT NULL,
    PRIMARY KEY (customer_id)
);

CREATE TABLE IF NOT EXISTS EMPLOYEE (
	employee_id CHAR(5) NOT NULL,
    chain_name VARCHAR(30) NOT NULL,
    first_name VARCHAR(30) NOT NULL,
    last_name VARCHAR(30) NOT NULL,
    sxn CHAR(9) UNIQUE NOT NULL,
    address VARCHAR(30),
    PRIMARY KEY (employee_id),
    FOREIGN KEY (chain_name) REFERENCES HOTEL_CHAIN (chain_name)
		ON DELETE CASCADE -- Was SET NULL
		ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS HOTEL (
    hotel_id INT AUTO_INCREMENT,
    hotel_name VARCHAR(30) UNIQUE NOT NULL,
    chain_name VARCHAR(30) NOT NULL,
    manager_id CHAR(5),
    category ENUM('1-star', '2-star', '3-star', '4-star', '5-star'),
    num_rooms INTEGER,
    city VARCHAR(30) NOT NULL,
    address VARCHAR(30),
    email VARCHAR(30),
    phone_number VARCHAR(20) NOT NULL,
    PRIMARY KEY (hotel_id),
    FOREIGN KEY (chain_name) REFERENCES HOTEL_CHAIN (chain_name)
    	ON DELETE CASCADE
		ON UPDATE CASCADE,
    FOREIGN KEY (manager_id) REFERENCES EMPLOYEE (employee_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE
);
-- CREATE INDEX index_hotel_id ON HOTEL (hotel_id);

CREATE TRIGGER increment_num_hotels
AFTER INSERT ON HOTEL
FOR EACH ROW
UPDATE HOTEL_CHAIN
SET num_hotels = num_hotels + 1
WHERE chain_name = NEW.chain_name;

CREATE TRIGGER decrement_num_hotels
AFTER DELETE ON HOTEL
FOR EACH ROW
UPDATE HOTEL_CHAIN
SET num_hotels = num_hotels - 1
WHERE chain_name = OLD.chain_name;

ALTER TABLE EMPLOYEE
ADD COLUMN hotel_name VARCHAR(30);
ALTER TABLE EMPLOYEE
ADD FOREIGN KEY (hotel_name) REFERENCES HOTEL (hotel_name)
	ON DELETE CASCADE -- Was SET NULL
	ON UPDATE CASCADE;

CREATE TABLE IF NOT EXISTS EMPLOYEE_POSITION (
	employee_id CHAR(5) NOT NULL,
    position VARCHAR(20) NOT NULL,
    PRIMARY KEY (employee_id, position),
    FOREIGN KEY (employee_id) REFERENCES EMPLOYEE (employee_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS ROOM (
    room_id INT AUTO_INCREMENT,
	hotel_name VARCHAR(30) NOT NULL,
    room_num INTEGER NOT NULL,
    price DECIMAL(15,2) NOT NULL,
    capacity INTEGER NOT NULL CHECK (1<=capacity<=6),
    view_type ENUM('sea view', 'mountain view') NOT NULL,
    can_extend BOOL NOT NULL,
    has_problems BOOL NOT NULL,
    available BOOL NOT NULL,
    PRIMARY KEY (room_id),
    FOREIGN KEY (hotel_name) REFERENCES HOTEL (hotel_name)
		ON DELETE CASCADE
		ON UPDATE CASCADE,
    INDEX idx_hotel_room (hotel_name, room_num)
);

CREATE TRIGGER increment_num_rooms
AFTER INSERT ON ROOM
FOR EACH ROW
UPDATE HOTEL
SET num_rooms = num_rooms + 1
WHERE hotel_name = NEW.hotel_name;

CREATE TRIGGER decrement_num_rooms
AFTER DELETE ON ROOM
FOR EACH ROW
UPDATE HOTEL
SET num_rooms = num_rooms - 1
WHERE hotel_name = OLD.hotel_name;

CREATE TABLE IF NOT EXISTS ROOM_AMENITY (
	hotel_name VARCHAR(30) NOT NULL,
    room_num INTEGER NOT NULL,
    amenity VARCHAR(30) NOT NULL,
    PRIMARY KEY (hotel_name, room_num, amenity),
    FOREIGN KEY (hotel_name, room_num) REFERENCES ROOM (hotel_name, room_num)
		ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS BOOKING (
	booking_id CHAR(5) NOT NULL,
    username VARCHAR(30) NOT NULL,
    chain_name VARCHAR(30) NOT NULL,
    hotel_name VARCHAR(30) NOT NULL,
    room_num INTEGER NOT NULL,
    capacity INTEGER NOT NULL CHECK (1<=capacity<=6),
    placed_date DATE NOT NULL,
    exp_check_in_date DATE NOT NULL,
    exp_check_out_date DATE NOT NULL,
    PRIMARY KEY (booking_id),
    FOREIGN KEY (username) REFERENCES CUSTOMER (username)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS BOOKING_ARCHIVE (
	booking_id CHAR(5) NOT NULL,
    username VARCHAR(30) NOT NULL,
    chain_name VARCHAR(30) NOT NULL,
    hotel_name VARCHAR(30) NOT NULL,
    room_num INTEGER NOT NULL,
    capacity INTEGER NOT NULL CHECK (1<=capacity<=6),
    placed_date DATE NOT NULL,
    exp_check_in_date DATE NOT NULL,
    exp_check_out_date DATE NOT NULL,
    PRIMARY KEY (booking_id)
);

CREATE TABLE IF NOT EXISTS RENTAL (
	rental_id CHAR(5) NOT NULL,
    username VARCHAR(30) NOT NULL,
    chain_name VARCHAR(30) NOT NULL,
    hotel_name VARCHAR(30) NOT NULL,
    room_num INTEGER NOT NULL,
    capacity INTEGER NOT NULL CHECK (1<=capacity<=6),
    rental_rate DECIMAL(15,2) NOT NULL,
    additional_charges DECIMAL(15,2),
    check_in_date DATE NOT NULL,
    check_out_date DATE NOT NULL,
    check_in_e_sxn CHAR(9) NOT NULL,
    check_out_e_sxn CHAR(9),
    PRIMARY KEY (rental_id),
    FOREIGN KEY (username) REFERENCES CUSTOMER (username)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS RENTAL_ARCHIVE (
	rental_id CHAR(5) NOT NULL,
    username VARCHAR(30) NOT NULL,
    chain_name VARCHAR(30) NOT NULL,
    hotel_name VARCHAR(30) NOT NULL,
    room_num INTEGER NOT NULL,
    capacity INTEGER NOT NULL CHECK (1<=capacity<=6),
    rental_rate DECIMAL(15,2) NOT NULL,
    additional_charges DECIMAL(15,2) NOT NULL,
    check_in_date DATE NOT NULL,
    check_out_date DATE NOT NULL,
    check_in_e_sxn CHAR(9) NOT NULL,
    check_out_e_sxn CHAR(9) NOT NULL,
    PRIMARY KEY (rental_id)
);

CREATE VIEW view_available_rooms AS
SELECT h.city, hc.chain_name, h.hotel_name, h.category, COUNT(r.room_num) AS available_rooms
FROM HOTEL_CHAIN hc
JOIN HOTEL h ON hc.chain_name = h.chain_name
JOIN ROOM r ON h.hotel_name = r.hotel_name
GROUP BY h.city, hc.chain_name, h.hotel_name, h.hotel_name, h.category;

CREATE VIEW view_capacity AS
SELECT h.hotel_name, r.room_num, r.capacity
FROM HOTEL h
JOIN ROOM r ON h.hotel_name = r.hotel_name;

INSERT INTO HOTEL_CHAIN (chain_name, num_hotels, email, phone_number)
VALUES
('Hilton', 0, 'support@hilton.com', '(364) 744-9920'),
('Hyatt', 0, 'support@hyatt.com', '(654) 440-5155'),
('Marriott', 0, 'support@marriott.com', '(839) 385-3736'),
('IHG', 0, 'support@ihg.com', '(211) 732-6435'),
('Wyndham', 0, 'support@wyndham.com', '(848) 818-8802');

INSERT INTO CENTRAL_OFFICE (chain_name, address)
VALUES
('Hilton', '1957 Mulberry Street'),
('Hilton', '4158 Philli Lane'),
('Hyatt', '1715 Hinkle Deegan Lake Road'),
('Hyatt', '2869 Round Table Drive'),
('Marriott', '2296 Murry Street'),
('Marriott', '1844 Dovetail Estates'),
('IHG', '2017 Scott Street'),
('IHG', '1737 Confederate Drive'),
('Wyndham', '4249 Tea Berry Lane'),
('Wyndham', '4709 Spring Avenue');

INSERT INTO EMPLOYEE (employee_id, chain_name, sxn, first_name, last_name)
VALUES
('A1001', 'Hilton', '479429054', 'Philip', 'Prince'),
('A1002', 'Hilton', '582321848', 'Carrie', 'Parker'),
('A1003', 'Hilton', '774770919', 'Julio', 'Bush'),
('A2001', 'Hilton', '674462475', 'Wade', 'Barron'),
('A2002', 'Hilton', '725696111', 'Randi', 'Torres'),
('A2003', 'Hilton', '169421599', 'Scott', 'Decker'),
('A3001', 'Hilton', '902471674', 'Alexis', 'Mack'),
('A3002', 'Hilton', '815150416', 'Myron', 'Crawford'),
('A3003', 'Hilton', '617386070', 'Grover', 'Ponce'),
('A4001', 'Hilton', '379534394', 'Shelby', 'Shields'),
('A4002', 'Hilton', '065036758', 'Fred', 'Jacobs'),
('A4003', 'Hilton', '749778460', 'Mitch', 'Ayala'),
('A5001', 'Hilton', '149621101', 'Emery', 'Pearson'),
('A5002', 'Hilton', '875637696', 'Simone', 'Ritter'),
('A5003', 'Hilton', '235693078', 'Rodger', 'Huerta'),
('A6001', 'Hilton', '699315056', 'Brendan', 'Sutton'),
('A6002', 'Hilton', '384668117', 'Lorenzo', 'Nelson'),
('A6003', 'Hilton', '902793232', 'Loraine', 'Sampson'),
('A7001', 'Hilton', '392783847', 'Rupert', 'Carroll'),
('A7002', 'Hilton', '659970521', 'Lynne', 'Reed'),
('A7003', 'Hilton', '706686398', 'Ray', 'Neal'),
('A8001', 'Hilton', '199375197', 'Loren', 'Sharp'),
('A8002', 'Hilton', '863520684', 'Irwin', 'Clay'),
('A8003', 'Hilton', '194848630', 'Elroy', 'Morris'),

('B1001', 'Hyatt', '336906312', 'Sammy', 'Espinoza'),
('B1002', 'Hyatt', '669576133', 'Weston', 'Sanders'),
('B1003', 'Hyatt', '012889109', 'Merrill', 'Chavez'),
('B2001', 'Hyatt', '769029570', 'Tyree', 'Mays'),
('B2002', 'Hyatt', '793264671', 'Joe', 'Castaneda'),
('B2003', 'Hyatt', '250408229', 'Asa', 'Thornton'),
('B3001', 'Hyatt', '400543538', 'Krystal', 'Ali'),
('B3002', 'Hyatt', '030801064', 'Courtney', 'Mosley'),
('B3003', 'Hyatt', '936745420', 'Marcie', 'Greene'),
('B4001', 'Hyatt', '074641067', 'Roman', 'Gentry'),
('B4002', 'Hyatt', '132787516', 'Adriana', 'Jefferson'),
('B4003', 'Hyatt', '082453927', 'Walton', 'Bradford'),
('B5001', 'Hyatt', '011887518', 'Naomi', 'Maxwell'),
('B5002', 'Hyatt', '769290236', 'Harold', 'Ellison'),
('B5003', 'Hyatt', '020787061', 'Tessa', 'Phillips'),
('B6001', 'Hyatt', '066493934', 'Sylvia', 'Hooper'),
('B6002', 'Hyatt', '101094449', 'Amos', 'Lane'),
('B6003', 'Hyatt', '490457708', 'Jesus', 'Avery'),
('B7001', 'Hyatt', '715956156', 'Judith', 'Leonard'),
('B7002', 'Hyatt', '014392377', 'Etta', 'Carter'),
('B7003', 'Hyatt', '607939014', 'Oscar', 'Guerra'),
('B8001', 'Hyatt', '546353364', 'Mabel', 'Salazar'),
('B8002', 'Hyatt', '225492882', 'Leo', 'Mcgee'),
('B8003', 'Hyatt', '562416783', 'Kelly', 'Buchanan'),

('C1001', 'Marriott', '166778493', 'Darius', 'Dickerson'),
('C1002', 'Marriott', '527955918', 'Maricela', 'Villarreal'),
('C1003', 'Marriott', '512345389', 'Dario', 'Cooper'),
('C2001', 'Marriott', '305642101', 'Duncan', 'Mclaughlin'),
('C2002', 'Marriott', '321501398', 'Elsie', 'Cross'),
('C2003', 'Marriott', '457636987', 'Wilda', 'Barker'),
('C3001', 'Marriott', '112426733', 'Wilbert', 'Tapia'),
('C3002', 'Marriott', '995622754', 'Marsha', 'Schmitt'),
('C3003', 'Marriott', '869744903', 'Jacklyn', 'Sloan'),
('C4001', 'Marriott', '552894605', 'Ellen', 'Whitney'),
('C4002', 'Marriott', '608765417', 'Al', 'Weaver'),
('C4003', 'Marriott', '616414308', 'Debbie', 'Salazar'),
('C5001', 'Marriott', '094221257', 'Sheena', 'Burns'),
('C5002', 'Marriott', '451007389', 'Colette', 'Mccarty'),
('C5003', 'Marriott', '700026563', 'Lakisha', 'Wilkerson'),
('C6001', 'Marriott', '877874181', 'Laura', 'Mejia'),
('C6002', 'Marriott', '900812957', 'Gene', 'Haas'),
('C6003', 'Marriott', '322436140', 'Sanford', 'Sexton'),
('C7001', 'Marriott', '917520714', 'Zachery', 'Bond'),
('C7002', 'Marriott', '649028751', 'Cathleen', 'Heath'),
('C7003', 'Marriott', '224930891', 'Alberta', 'Patterson'),
('C8001', 'Marriott', '658285028', 'Mohammed', 'Mccarty'),
('C8002', 'Marriott', '858583228', 'Lena', 'Cummings'),
('C8003', 'Marriott', '488269073', 'Manuel', 'Stark'),

('D1001', 'IHG', '951699547', 'Esther', 'Gibson'),
('D1002', 'IHG', '411957491', 'Mabel', 'Burgess'),
('D1003', 'IHG', '523813333', 'Carlton', 'Bullock'),
('D2001', 'IHG', '171175592', 'Janelle', 'Quinn'),
('D2002', 'IHG', '628369156', 'Rupert', 'George'),
('D2003', 'IHG', '978193820', 'Salvatore', 'Yang'),
('D3001', 'IHG', '049110350', 'Adolfo', 'Montgomery'),
('D3002', 'IHG', '595804419', 'Maritza', 'Underwood'),
('D3003', 'IHG', '619931744', 'Carla', 'Travis'),
('D4001', 'IHG', '565322077', 'Lonny', 'Deleon'),
('D4002', 'IHG', '389369474', 'Jessie', 'Marquez'),
('D4003', 'IHG', '225938036', 'Jewell', 'Monroe'),
('D5001', 'IHG', '667560276', 'Andreas', 'Hogan'),
('D5002', 'IHG', '281491464', 'Cleveland', 'Huynh'),
('D5003', 'IHG', '995554411', 'Christian', 'Wiggins'),
('D6001', 'IHG', '251379703', 'Gail', 'Gail'),
('D6002', 'IHG', '358279012', 'Kim', 'Fernandez'),
('D6003', 'IHG', '490270976', 'Carmella', 'Ellis'),
('D7001', 'IHG', '715160800', 'Blanche', 'Lee'),
('D7002', 'IHG', '388114991', 'Will', 'Whitehead'),
('D7003', 'IHG', '272168321', 'Sandy', 'Mathews'),
('D8001', 'IHG', '774460068', 'Stephanie', 'Hendrix'),
('D8002', 'IHG', '183837745', 'Felton', 'Salas'),
('D8003', 'IHG', '975911194', 'Brock', 'Mcclain'),

('E1001', 'Wyndham', '435231065', 'Wilton', 'Ramsey'),
('E1002', 'Wyndham', '621186925', 'Bennett', 'Booth'),
('E1003', 'Wyndham', '100677677', 'Ester', 'Allison'),
('E2001', 'Wyndham', '611653969', 'Tamra', 'Nguyen'),
('E2002', 'Wyndham', '891393213', 'Lesley', 'Mclaughlin'),
('E2003', 'Wyndham', '272582394', 'Barney', 'Glover'),
('E3001', 'Wyndham', '535725140', 'Hai', 'Mathews'),
('E3002', 'Wyndham', '565129529', 'Stuart', 'Wyatt'),
('E3003', 'Wyndham', '377075033', 'Helena', 'Adams'),
('E4001', 'Wyndham', '715768576', 'Darrin', 'Briggs'),
('E4002', 'Wyndham', '177292303', 'Carly', 'Salinas'),
('E4003', 'Wyndham', '524916451', 'Herminia', 'Malone'),
('E5001', 'Wyndham', '426387062', 'Patrice', 'Mercer'),
('E5002', 'Wyndham', '120564656', 'Louis', 'Conway'),
('E5003', 'Wyndham', '698638401', 'Jarod', 'Watson'),
('E6001', 'Wyndham', '076844624', 'Chrystal', 'Ballard'),
('E6002', 'Wyndham', '486076589', 'Sergio', 'Vega'),
('E6003', 'Wyndham', '186815281', 'Gilberto', 'Moody'),
('E7001', 'Wyndham', '626534505', 'Aaron', 'Zimmerman'),
('E7002', 'Wyndham', '555970597', 'Trenton', 'Harper'),
('E7003', 'Wyndham', '638036690', 'Aldo', 'Mann'),
('E8001', 'Wyndham', '569604377', 'Hassan', 'Lucas'),
('E8002', 'Wyndham', '060784523', 'Bernard', 'Cain'),
('E8003', 'Wyndham', '578821525', 'Merle', 'Torres');

INSERT INTO HOTEL (chain_name, manager_id, hotel_name, category, num_rooms, city, address, email, phone_number)
VALUES
('Hilton', 'A1001', 'Canopy', '3-star', 0, 'Lima', '1006 Upland Avenue', 'support@canopy.com', '419-233-9601'),
('Hilton', 'A2001', 'Conrad Hotel & Resort', '4-star', 0, 'Louisville', '922 Earnhardt Drive', 'support@conrad.com', '502-634-2737'),
('Hilton', 'A3001', 'Curio Collection', '3-star', 0, 'Milwaukee', '4824 Johnny Lane', 'support@curio.com', '414-332-6767'),
('Hilton', 'A4001', 'DoubleTree', '3-star', 0, 'San Francisco', '4733 Thompson Drive', 'support@doubletree.com', '747-232-0482'),
('Hilton', 'A5001', 'Hampton', '3-star', 0, 'Waterproof', '1241 Emerson Road', 'support@hampton.com', '318-749-7831'),
('Hilton', 'A6001', 'LXR Hotel & Resort', '4-star', 0, 'Louisville', '3431 Cerullo Road', 'support@lxr.com', '502-452-7369'),
('Hilton', 'A7001', 'Tru', '3-star', 0, 'Tallahassee', '4264 Virgil Street', 'support@tru.com', '850-228-6208'),
('Hilton', 'A8001', 'Embassy Suite', '5-star', 0, 'New Orleans', '3209 Big Indian', 'support@embassysuites.com', '504-568-9770'),

('Hyatt', 'B1001', 'Hyatt Place', '3-star', 0, 'Fort Lauderdale', '4653 Foley Street', 'support@hyattplace.com', '304-694-1467'),
('Hyatt', 'B2001', 'Spirit Ridge', '3-star', 0, 'Denver', '3718 Stark Hollow Road', 'support@spiritridge.com', '970-812-9599'),
('Hyatt', 'B3001', 'Andaz', '3-star', 0, 'South Boston', '3049 Hinkle Lake Road', 'support@andaz.com', '269-499-9079'),
('Hyatt', 'B4001', 'Park Hyatt', '3-star', 0, 'China Grove', '3812 Kelly Street', 'support@parkhyatt.com', '805-342-8021'),
('Hyatt', 'B5001', 'The Anndore House', '4-star', 0, 'Denver', '1857 Sampson Street', 'support@anndore.com', '477-546-9498'),
('Hyatt', 'B6001', 'Tempe Mission Palms', '4-star', 0, 'Defiance', '539 Hill Street', 'support@tempepalms.com', '771-279-2479'),
('Hyatt', 'B7001', 'The Eliza Jane', '4-star', 0, 'Earlville', '397 Emeral Dreams Drive', 'support@elizajane.com', '334-595-3424'),
('Hyatt', 'B8001', 'The Walper Hotel', '5-star', 0, 'Somerville', '3040 Gerald L. Bates Drive', 'support@walperhotel.com', '530-702-6218'),

('Marriott', 'C1001', 'AC Hotel', '3-star', 0, 'Westland', '2941 Bombardier Way', 'support@achotel.com', '586-729-3821'),
('Marriott', 'C2001', 'Autograph Collection', '3-star', 0, 'Ashtabula', '1572 Vineyard Drive', 'support@autocollection.com', '440-536-1901'),
('Marriott', 'C3001', 'City Express', '3-star', 0, 'Tampa', '1197 Collins Street', 'support@cityexpress.com', '813-400-0048'),
('Marriott', 'C4001', 'Delta Hotel', '3-star', 0, 'Atlanta', '1509 Stroop Hill Road', 'support@deltahotel.com', '678-230-8898'),
('Marriott', 'C5001', 'Courtyard', '4-star', 0, 'Dallas', '4981 Deercove Drive', 'support@courtyard.com', '214-552-3542'),
('Marriott', 'C6001', 'Moxy', '4-star', 0, 'Mira Loma', '4470 Carriage Court', 'support@moxy.com', '951-362-1487'),
('Marriott', 'C7001', 'Tribute', '4-star', 0, 'Doral', '1534 Warner Street', 'support@tribute.com', '305-994-6699'),
('Marriott', 'C8001', 'EDITION', '5-star', 0, 'Tampa', '4696 Saints Alley', 'support@edition.com', '813-694-0955'),

('IHG', 'D1001', 'Ritz-Carlton', '1-star', 0, 'Tempe', '2734 East Avenue', 'support@ritzcarlton.com', '480-355-8447'),
('IHG', 'D2001', 'Aman Resort', '1-star', 0, 'Brooklyn', '1499 Redbud Drive', 'support@amanresort.com', '347-890-8363'),
('IHG', 'D3001', 'Four Seasons', '2-star', 0, 'Dallas', '2430 Ersel Street', 'support@fourseasons.com', '214-408-6999'),
('IHG', 'D4001', 'Candlewood Suite', '2-star', 0, 'Naperville', '4517 Hickman Street', 'support@candlewoodsuite.com', '630-505-2028'),
('IHG', 'D5001', 'Vignette', '2-star', 0, 'Graceville', '2431 Virgil Street', 'support@vignette.com', '850-263-5314'),
('IHG', 'D6001', 'Kimpton', '2-star', 0, 'La Cygne', '4574 Charter Street', 'support@kimpton.com', '913-757-2423'),
('IHG', 'D7001', 'Hotel Indigo', '3-star', 0, 'Princeton', '4568 Sherman Street', 'support@hotelindigo.com', '785-937-3298'),
('IHG', 'D8001', 'InterContinetal', '5-star', 0, 'Brooklyn', '584 Pride Avenue', 'support@intercontinetal.com', '718-332-3923'),

('Wyndham', 'E1001', 'AmericInn', '3-star', 0, 'Marion', '1031 Payne Street', 'support@americinn.com', '276-243-8678'),
('Wyndham', 'E2001', 'Baymont', '4-star', 0, 'Wrangle Hill', '3710 Columbia Road', 'support@baymont.com', '302-838-4839'),
('Wyndham', 'E3001', 'Dazzler', '4-star', 0, 'Detroit', '2768 Tuna Street', 'support@dazzler.com', '810-813-9213'),
('Wyndham', 'E4001', 'Esplendor', '4-star', 0, 'New York', '1563 Redbud Drive', 'support@esplendor.com', '347-923-4460'),
('Wyndham', 'E5001', 'Howard Johnson', '4-star', 0, 'Kingsport', '2450 Corbin Branch Road', 'support@howardjohnson.com', '423-502-4598'),
('Wyndham', 'E6001', 'La Quinta', '5-star', 0, 'San Diego', '2575 Willison Street', 'support@laquinta.com', '619-242-8201'),
('Wyndham', 'E7001', 'Origin', '5-star', 0, 'Marion', '3888 Shady Pines Drive', 'support@origin.com', '276-780-1328'),
('Wyndham', 'E8001', 'TRYP', '5-star', 0, 'Mayhill', '1736 Cooks Mine Road', 'support@tryp.com', '505-203-6521');

UPDATE EMPLOYEE SET hotel_name = 'Canopy'                WHERE employee_id LIKE 'A1%';
UPDATE EMPLOYEE SET hotel_name = 'Conrad Hotel & Resort' WHERE employee_id LIKE 'A2%';
UPDATE EMPLOYEE SET hotel_name = 'Curio Collection'      WHERE employee_id LIKE 'A3%';
UPDATE EMPLOYEE SET hotel_name = 'DoubleTree'            WHERE employee_id LIKE 'A4%';
UPDATE EMPLOYEE SET hotel_name = 'Hampton'               WHERE employee_id LIKE 'A5%';
UPDATE EMPLOYEE SET hotel_name = 'LXR Hotel & Resort'    WHERE employee_id LIKE 'A6%';
UPDATE EMPLOYEE SET hotel_name = 'Tru'                   WHERE employee_id LIKE 'A7%';
UPDATE EMPLOYEE SET hotel_name = 'Embassy Suite'         WHERE employee_id LIKE 'A8%';

UPDATE EMPLOYEE SET hotel_name = 'Hyatt Place'         WHERE employee_id LIKE 'B1%';
UPDATE EMPLOYEE SET hotel_name = 'Spirit Ridge'        WHERE employee_id LIKE 'B2%';
UPDATE EMPLOYEE SET hotel_name = 'Andaz'               WHERE employee_id LIKE 'B3%';
UPDATE EMPLOYEE SET hotel_name = 'Park Hyatt'          WHERE employee_id LIKE 'B4%';
UPDATE EMPLOYEE SET hotel_name = 'The Anndore House'   WHERE employee_id LIKE 'B5%';
UPDATE EMPLOYEE SET hotel_name = 'Tempe Mission Palms' WHERE employee_id LIKE 'B6%';
UPDATE EMPLOYEE SET hotel_name = 'The Eliza Jane'      WHERE employee_id LIKE 'B7%';
UPDATE EMPLOYEE SET hotel_name = 'The Walper Hotel'    WHERE employee_id LIKE 'B8%';

UPDATE EMPLOYEE SET hotel_name = 'AC Hotel'             WHERE employee_id LIKE 'C1%';
UPDATE EMPLOYEE SET hotel_name = 'Autograph Collection' WHERE employee_id LIKE 'C2%';
UPDATE EMPLOYEE SET hotel_name = 'City Express'         WHERE employee_id LIKE 'C3%';
UPDATE EMPLOYEE SET hotel_name = 'Delta Hotel'          WHERE employee_id LIKE 'C4%';
UPDATE EMPLOYEE SET hotel_name = 'Courtyard'            WHERE employee_id LIKE 'C5%';
UPDATE EMPLOYEE SET hotel_name = 'Moxy'                 WHERE employee_id LIKE 'C6%';
UPDATE EMPLOYEE SET hotel_name = 'Tribute'              WHERE employee_id LIKE 'C7%';
UPDATE EMPLOYEE SET hotel_name = 'EDITION'              WHERE employee_id LIKE 'C8%';

UPDATE EMPLOYEE SET hotel_name = 'Ritz-Carlton'     WHERE employee_id LIKE 'D1%';
UPDATE EMPLOYEE SET hotel_name = 'Aman Resort'      WHERE employee_id LIKE 'D2%';
UPDATE EMPLOYEE SET hotel_name = 'Four Seasons'     WHERE employee_id LIKE 'D3%';
UPDATE EMPLOYEE SET hotel_name = 'Candlewood Suite' WHERE employee_id LIKE 'D4%';
UPDATE EMPLOYEE SET hotel_name = 'Vignette'         WHERE employee_id LIKE 'D5%';
UPDATE EMPLOYEE SET hotel_name = 'Kimpton'          WHERE employee_id LIKE 'D6%';
UPDATE EMPLOYEE SET hotel_name = 'Hotel Indigo'     WHERE employee_id LIKE 'D7%';
UPDATE EMPLOYEE SET hotel_name = 'InterContinetal'  WHERE employee_id LIKE 'D8%';

UPDATE EMPLOYEE SET hotel_name = 'AmericInn'      WHERE employee_id LIKE 'E1%';
UPDATE EMPLOYEE SET hotel_name = 'Baymont'        WHERE employee_id LIKE 'E2%';
UPDATE EMPLOYEE SET hotel_name = 'Dazzler'        WHERE employee_id LIKE 'E3%';
UPDATE EMPLOYEE SET hotel_name = 'Esplendor'      WHERE employee_id LIKE 'E4%';
UPDATE EMPLOYEE SET hotel_name = 'Howard Johnson' WHERE employee_id LIKE 'E5%';
UPDATE EMPLOYEE SET hotel_name = 'La Quinta'      WHERE employee_id LIKE 'E6%';
UPDATE EMPLOYEE SET hotel_name = 'Origin'         WHERE employee_id LIKE 'E7%';
UPDATE EMPLOYEE SET hotel_name = 'TRYP'           WHERE employee_id LIKE 'E8%';


INSERT INTO EMPLOYEE_POSITION (employee_id, position)
VALUES
('A1001', 'Manager'),
('A2001', 'Manager'),
('A3001', 'Manager'),
('A4001', 'Manager'),
('A5001', 'Manager'),
('A6001', 'Manager'),
('A7001', 'Manager'),
('A8001', 'Manager'),
('A1002', 'Front Desk Clerk'),
('A2002', 'Front Desk Clerk'),
('A3002', 'Front Desk Clerk'),
('A4002', 'Front Desk Clerk'),
('A5002', 'Front Desk Clerk'),
('A6002', 'Front Desk Clerk'),
('A7002', 'Front Desk Clerk'),
('A8002', 'Front Desk Clerk'),
('A1003', 'Housekeeping'),
('A2003', 'Housekeeping'),
('A3003', 'Housekeeping'),
('A4003', 'Housekeeping'),
('A5003', 'Housekeeping'),
('A6003', 'Housekeeping'),
('A7003', 'Housekeeping'),
('A8003', 'Housekeeping'),

('B1001', 'Manager'),
('B2001', 'Manager'),
('B3001', 'Manager'),
('B4001', 'Manager'),
('B5001', 'Manager'),
('B6001', 'Manager'),
('B7001', 'Manager'),
('B8001', 'Manager'),
('B1002', 'Front Desk Clerk'),
('B2002', 'Front Desk Clerk'),
('B3002', 'Front Desk Clerk'),
('B4002', 'Front Desk Clerk'),
('B5002', 'Front Desk Clerk'),
('B6002', 'Front Desk Clerk'),
('B7002', 'Front Desk Clerk'),
('B8002', 'Front Desk Clerk'),
('B1003', 'Housekeeping'),
('B2003', 'Housekeeping'),
('B3003', 'Housekeeping'),
('B4003', 'Housekeeping'),
('B5003', 'Housekeeping'),
('B7003', 'Housekeeping'),
('B6003', 'Housekeeping'),
('B8003', 'Housekeeping'),

('C1001', 'Manager'),
('C2001', 'Manager'),
('C3001', 'Manager'),
('C4001', 'Manager'),
('C5001', 'Manager'),
('C6001', 'Manager'),
('C7001', 'Manager'),
('C8001', 'Manager'),
('C1002', 'Front Desk Clerk'),
('C2002', 'Front Desk Clerk'),
('C3002', 'Front Desk Clerk'),
('C4002', 'Front Desk Clerk'),
('C5002', 'Front Desk Clerk'),
('C6002', 'Front Desk Clerk'),
('C7002', 'Front Desk Clerk'),
('C8002', 'Front Desk Clerk'),
('C1003', 'Housekeeping'),
('C2003', 'Housekeeping'),
('C3003', 'Housekeeping'),
('C4003', 'Housekeeping'),
('C5003', 'Housekeeping'),
('C6003', 'Housekeeping'),
('C7003', 'Housekeeping'),
('C8003', 'Housekeeping'),

('D1001', 'Manager'),
('D2001', 'Manager'),
('D3001', 'Manager'),
('D4001', 'Manager'),
('D5001', 'Manager'),
('D6001', 'Manager'),
('D7001', 'Manager'),
('D8001', 'Manager'),
('D1002', 'Front Desk Clerk'),
('D2002', 'Front Desk Clerk'),
('D3002', 'Front Desk Clerk'),
('D4002', 'Front Desk Clerk'),
('D5002', 'Front Desk Clerk'),
('D6002', 'Front Desk Clerk'),
('D7002', 'Front Desk Clerk'),
('D8002', 'Front Desk Clerk'),
('D1003', 'Housekeeping'),
('D2003', 'Housekeeping'),
('D3003', 'Housekeeping'),
('D4003', 'Housekeeping'),
('D5003', 'Housekeeping'),
('D6003', 'Housekeeping'),
('D7003', 'Housekeeping'),
('D8003', 'Housekeeping'),

('E1001', 'Manager'),
('E2001', 'Manager'),
('E3001', 'Manager'),
('E4001', 'Manager'),
('E5001', 'Manager'),
('E6001', 'Manager'),
('E7001', 'Manager'),
('E8001', 'Manager'),
('E1002', 'Front Desk Clerk'),
('E2002', 'Front Desk Clerk'),
('E3002', 'Front Desk Clerk'),
('E4002', 'Front Desk Clerk'),
('E5002', 'Front Desk Clerk'),
('E6002', 'Front Desk Clerk'),
('E7002', 'Front Desk Clerk'),
('E8002', 'Front Desk Clerk'),
('E1003', 'Housekeeping'),
('E2003', 'Housekeeping'),
('E3003', 'Housekeeping'),
('E4003', 'Housekeeping'),
('E5003', 'Housekeeping'),
('E6003', 'Housekeeping'),
('E7003', 'Housekeeping'),
('E8003', 'Housekeeping');

INSERT INTO ROOM (hotel_name, room_num, price, capacity, view_type, can_extend, has_problems, available)
VALUES
('Canopy', 1, 100.00, 1, 'sea view', TRUE, FALSE, TRUE),
('Canopy', 2, 200.00, 2, 'mountain view', FALSE, FALSE, TRUE),
('Canopy', 3, 300.00, 3, 'sea view', TRUE, FALSE, TRUE),
('Canopy', 4, 400.00, 4, 'mountain view', FALSE, FALSE, TRUE),
('Canopy', 5, 500.00, 5, 'sea view', TRUE, FALSE, TRUE),
('Conrad Hotel & Resort', 1, 100.00, 1, 'mountain view', FALSE, FALSE, TRUE),
('Conrad Hotel & Resort', 2, 200.00, 2, 'sea view', TRUE, FALSE, TRUE),
('Conrad Hotel & Resort', 3, 300.00, 3, 'mountain view', FALSE, FALSE, TRUE),
('Conrad Hotel & Resort', 4, 400.00, 4, 'sea view', TRUE, FALSE, TRUE),
('Conrad Hotel & Resort', 5, 500.00, 5, 'mountain view', FALSE, TRUE, TRUE),
('Curio Collection', 1, 100.00, 1, 'sea view', TRUE, FALSE, TRUE),
('Curio Collection', 2, 200.00, 2, 'mountain view', FALSE, FALSE, TRUE),
('Curio Collection', 3, 300.00, 3, 'sea view', TRUE, FALSE, TRUE),
('Curio Collection', 4, 400.00, 4, 'mountain view', FALSE, FALSE, TRUE),
('Curio Collection', 5, 500.00, 5, 'sea view', TRUE, FALSE, TRUE),
('DoubleTree', 1, 100.00, 1, 'mountain view', FALSE, FALSE, TRUE),
('DoubleTree', 2, 200.00, 2, 'sea view', TRUE, FALSE, TRUE),
('DoubleTree', 3, 300.00, 3, 'mountain view', FALSE, FALSE, TRUE),
('DoubleTree', 4, 400.00, 4, 'sea view', TRUE, FALSE, TRUE),
('DoubleTree', 5, 500.00, 5, 'mountain view', FALSE, FALSE, TRUE),
('Hampton', 1, 100.00, 1, 'sea view', TRUE, FALSE, TRUE),
('Hampton', 2, 200.00, 2, 'mountain view', FALSE, FALSE, TRUE),
('Hampton', 3, 300.00, 3, 'sea view', TRUE, FALSE, TRUE),
('Hampton', 4, 400.00, 4, 'mountain view', FALSE, FALSE, TRUE),
('Hampton', 5, 500.00, 5, 'sea view', TRUE, FALSE, TRUE),
('LXR Hotel & Resort', 1, 100.00, 1, 'mountain view', FALSE, TRUE, TRUE),
('LXR Hotel & Resort', 2, 200.00, 2, 'sea view', TRUE, FALSE, TRUE),
('LXR Hotel & Resort', 3, 300.00, 3, 'mountain view', FALSE, FALSE, TRUE),
('LXR Hotel & Resort', 4, 400.00, 4, 'sea view', TRUE, FALSE, TRUE),
('LXR Hotel & Resort', 5, 500.00, 5, 'mountain view', FALSE, FALSE, TRUE),
('Tru', 1, 100.00, 1, 'sea view', TRUE, FALSE, TRUE),
('Tru', 2, 200.00, 2, 'mountain view', FALSE, FALSE, TRUE),
('Tru', 3, 300.00, 3, 'sea view', TRUE, FALSE, TRUE),
('Tru', 4, 400.00, 4, 'mountain view', FALSE, FALSE, TRUE),
('Tru', 5, 500.00, 5, 'sea view', TRUE, FALSE, TRUE),
('Embassy Suite', 1, 100.00, 1, 'mountain view', FALSE, FALSE, TRUE),
('Embassy Suite', 2, 200.00, 2, 'sea view', TRUE, FALSE, TRUE),
('Embassy Suite', 3, 300.00, 3, 'mountain view', FALSE, FALSE, TRUE),
('Embassy Suite', 4, 400.00, 4, 'sea view', TRUE, FALSE, TRUE),
('Embassy Suite', 5, 500.00, 5, 'mountain view', FALSE, FALSE, TRUE),

('Hyatt Place', 1, 100.00, 1, 'sea view', TRUE, FALSE, TRUE),
('Hyatt Place', 2, 200.00, 2, 'mountain view', FALSE, FALSE, TRUE),
('Hyatt Place', 3, 300.00, 3, 'sea view', TRUE, FALSE, TRUE),
('Hyatt Place', 4, 400.00, 4, 'mountain view', FALSE, FALSE, TRUE),
('Hyatt Place', 5, 500.00, 5, 'sea view', TRUE, FALSE, TRUE),
('Spirit Ridge', 1, 100.00, 1, 'mountain view', FALSE, FALSE, TRUE),
('Spirit Ridge', 2, 200.00, 2, 'sea view', TRUE, FALSE, TRUE),
('Spirit Ridge', 3, 300.00, 3, 'mountain view', FALSE, FALSE, TRUE),
('Spirit Ridge', 4, 400.00, 4, 'sea view', TRUE, FALSE, TRUE),
('Spirit Ridge', 5, 500.00, 5, 'mountain view', FALSE, TRUE, TRUE),
('Andaz', 1, 100.00, 1, 'sea view', TRUE, FALSE, TRUE),
('Andaz', 2, 200.00, 2, 'mountain view', FALSE, FALSE, TRUE),
('Andaz', 3, 300.00, 3, 'sea view', TRUE, FALSE, TRUE),
('Andaz', 4, 400.00, 4, 'mountain view', FALSE, FALSE, TRUE),
('Andaz', 5, 500.00, 5, 'sea view', TRUE, FALSE, TRUE),
('Park Hyatt', 1, 100.00, 1, 'mountain view', FALSE, FALSE, TRUE),
('Park Hyatt', 2, 200.00, 2, 'sea view', TRUE, FALSE, TRUE),
('Park Hyatt', 3, 300.00, 3, 'mountain view', FALSE, FALSE, TRUE),
('Park Hyatt', 4, 400.00, 4, 'sea view', TRUE, FALSE, TRUE),
('Park Hyatt', 5, 500.00, 5, 'mountain view', FALSE, FALSE, TRUE),
('The Anndore House', 1, 100.00, 1, 'sea view', TRUE, FALSE, TRUE),
('The Anndore House', 2, 200.00, 2, 'mountain view', FALSE, FALSE, TRUE),
('The Anndore House', 3, 300.00, 3, 'sea view', TRUE, FALSE, TRUE),
('The Anndore House', 4, 400.00, 4, 'mountain view', FALSE, FALSE, TRUE),
('The Anndore House', 5, 500.00, 5, 'sea view', TRUE, FALSE, TRUE),
('Tempe Mission Palms', 1, 100.00, 1, 'mountain view', FALSE, FALSE, TRUE),
('Tempe Mission Palms', 2, 200.00, 2, 'sea view', TRUE, FALSE, TRUE),
('Tempe Mission Palms', 3, 300.00, 3, 'mountain view', FALSE, FALSE, TRUE),
('Tempe Mission Palms', 4, 400.00, 4, 'sea view', TRUE, FALSE, TRUE), 
('Tempe Mission Palms', 5, 500.00, 5, 'mountain view', FALSE, FALSE, TRUE),
('The Eliza Jane', 1, 100.00, 1, 'sea view', TRUE, FALSE, TRUE),
('The Eliza Jane', 2, 200.00, 2, 'mountain view', FALSE, FALSE, TRUE),
('The Eliza Jane', 3, 300.00, 3, 'sea view', TRUE, FALSE, TRUE), 
('The Eliza Jane', 4, 400.00, 4, 'mountain view', FALSE, FALSE, TRUE), 
('The Eliza Jane', 5, 500.00, 5, 'sea view', TRUE, FALSE, TRUE),
('The Walper Hotel', 1, 100.00, 1, 'mountain view', FALSE, FALSE, TRUE),
('The Walper Hotel', 2, 200.00, 2, 'sea view', TRUE, FALSE, TRUE),
('The Walper Hotel', 3, 300.00, 3, 'mountain view', FALSE, FALSE, TRUE), 
('The Walper Hotel', 4, 400.00, 4, 'sea view', TRUE, FALSE, TRUE),
('The Walper Hotel', 5, 500.00, 5, 'mountain view', FALSE, FALSE, TRUE),

('AC Hotel', 1, 100.00, 1, 'sea view', TRUE, FALSE, TRUE),
('AC Hotel', 2, 200.00, 2, 'mountain view', FALSE, FALSE, TRUE),
('AC Hotel', 3, 300.00, 3, 'sea view', TRUE, FALSE, TRUE),
('AC Hotel', 4, 400.00, 4, 'mountain view', FALSE, FALSE, TRUE),
('AC Hotel', 5, 500.00, 5, 'sea view', TRUE, FALSE, TRUE),
('Autograph Collection', 1, 100.00, 1, 'mountain view', FALSE, TRUE, TRUE),
('Autograph Collection', 2, 200.00, 2, 'sea view', TRUE, FALSE, TRUE),
('Autograph Collection', 3, 300.00, 3, 'mountain view', FALSE, FALSE, TRUE),
('Autograph Collection', 4, 400.00, 4, 'sea view', TRUE, FALSE, TRUE),
('Autograph Collection', 5, 500.00, 5, 'mountain view', FALSE, TRUE, TRUE),
('City Express', 1, 100.00, 1, 'sea view', TRUE, FALSE, TRUE),
('City Express', 2, 200.00, 2, 'mountain view', FALSE, FALSE, TRUE),
('City Express', 3, 300.00, 3, 'sea view', TRUE, FALSE, TRUE),
('City Express', 4, 400.00, 4, 'mountain view', FALSE, FALSE, TRUE),
('City Express', 5, 500.00, 5, 'sea view', TRUE, FALSE, TRUE),
('Delta Hotel', 1, 100.00, 1, 'mountain view', FALSE, FALSE, TRUE),
('Delta Hotel', 2, 200.00, 2, 'sea view', TRUE, FALSE, TRUE),
('Delta Hotel', 3, 300.00, 3, 'mountain view', FALSE, FALSE, TRUE),
('Delta Hotel', 4, 400.00, 4, 'sea view', TRUE, FALSE, TRUE),
('Delta Hotel', 5, 500.00, 5, 'mountain view', FALSE, FALSE, TRUE),
('Courtyard', 1, 100.00, 1, 'sea view', TRUE, FALSE, TRUE),
('Courtyard', 2, 200.00, 2, 'mountain view', FALSE, FALSE, TRUE),
('Courtyard', 3, 300.00, 3, 'sea view', TRUE, FALSE, TRUE),
('Courtyard', 4, 400.00, 4, 'mountain view', FALSE, FALSE, TRUE),
('Courtyard', 5, 500.00, 5, 'sea view', TRUE, FALSE, TRUE),
('Moxy', 1, 100.00, 1, 'mountain view', FALSE, FALSE, TRUE),
('Moxy', 2, 200.00, 2, 'sea view', TRUE, FALSE, TRUE),
('Moxy', 3, 300.00, 3, 'mountain view', FALSE, FALSE, TRUE),
('Moxy', 4, 400.00, 4, 'sea view', TRUE, FALSE, TRUE),
('Moxy', 5, 500.00, 5, 'mountain view', FALSE, FALSE, TRUE),
('Tribute', 1, 100.00, 1, 'sea view', TRUE, FALSE, TRUE),
('Tribute', 2, 200.00, 2, 'mountain view', FALSE, FALSE, TRUE),
('Tribute', 3, 300.00, 3, 'sea view', TRUE, FALSE, TRUE),
('Tribute', 4, 400.00, 4, 'mountain view', FALSE, FALSE, TRUE),
('Tribute', 5, 500.00, 5, 'sea view', TRUE, FALSE, TRUE),
('EDITION', 1, 100.00, 1, 'mountain view', FALSE, TRUE, TRUE),
('EDITION', 2, 200.00, 2, 'sea view', TRUE, FALSE, TRUE),
('EDITION', 3, 300.00, 3, 'mountain view', FALSE, FALSE, TRUE), 
('EDITION', 4, 400.00, 4, 'sea view', TRUE, FALSE, TRUE),
('EDITION', 5, 500.00, 5, 'mountain view', FALSE, FALSE, TRUE),

('Ritz-Carlton', 1, 100.00, 1, 'sea view', TRUE, FALSE, TRUE),
('Ritz-Carlton', 2, 200.00, 2, 'mountain view', FALSE, FALSE, TRUE),
('Ritz-Carlton', 3, 300.00, 3, 'sea view', TRUE, FALSE, TRUE),
('Ritz-Carlton', 4, 400.00, 4, 'mountain view', FALSE, FALSE, TRUE),
('Ritz-Carlton', 5, 500.00, 5, 'sea view', TRUE, FALSE, TRUE),
('Aman Resort', 1, 100.00, 1, 'mountain view', FALSE, FALSE, TRUE),
('Aman Resort', 2, 200.00, 2, 'sea view', TRUE, FALSE, TRUE),
('Aman Resort', 3, 300.00, 3, 'mountain view', FALSE, FALSE, TRUE),
('Aman Resort', 4, 400.00, 4, 'sea view', TRUE, FALSE, TRUE),
('Aman Resort', 5, 500.00, 5, 'mountain view', FALSE, TRUE, TRUE),
('Four Seasons', 1, 100.00, 1, 'sea view', TRUE, FALSE, TRUE),
('Four Seasons', 2, 200.00, 2, 'mountain view', FALSE, TRUE, TRUE),
('Four Seasons', 3, 300.00, 3, 'sea view', TRUE, FALSE, TRUE),
('Four Seasons', 4, 400.00, 4, 'mountain view', FALSE, FALSE, TRUE),
('Four Seasons', 5, 500.00, 5, 'sea view', TRUE, FALSE, TRUE),
('Candlewood Suite', 1, 100.00, 1, 'mountain view', FALSE, FALSE, TRUE),
('Candlewood Suite', 2, 200.00, 2, 'sea view', TRUE, FALSE, TRUE),
('Candlewood Suite', 3, 300.00, 3, 'mountain view', FALSE, FALSE, TRUE),
('Candlewood Suite', 4, 400.00, 4, 'sea view', TRUE, FALSE, TRUE),
('Candlewood Suite', 5, 500.00, 5, 'mountain view', FALSE, FALSE, TRUE),
('Vignette', 1, 100.00, 1, 'sea view', TRUE, FALSE, TRUE),
('Vignette', 2, 200.00, 2, 'mountain view', FALSE, FALSE, TRUE),
('Vignette', 3, 300.00, 3, 'sea view', TRUE, FALSE, TRUE),
('Vignette', 4, 400.00, 4, 'mountain view', FALSE, FALSE, TRUE),
('Vignette', 5, 500.00, 5, 'sea view', TRUE, FALSE, TRUE),
('Kimpton', 1, 100.00, 1, 'mountain view', FALSE, TRUE, TRUE),
('Kimpton', 2, 200.00, 2, 'sea view', TRUE, FALSE, TRUE),
('Kimpton', 3, 300.00, 3, 'mountain view', FALSE, FALSE, TRUE),
('Kimpton', 4, 400.00, 4, 'sea view', TRUE, FALSE, TRUE), 
('Kimpton', 5, 500.00, 5, 'mountain view', FALSE, FALSE, TRUE),
('Hotel Indigo', 1, 100.00, 1, 'sea view', TRUE, FALSE, TRUE),
('Hotel Indigo', 2, 200.00, 2, 'mountain view', FALSE, FALSE, TRUE),
('Hotel Indigo', 3, 300.00, 3, 'sea view', TRUE, FALSE, TRUE), 
('Hotel Indigo', 4, 400.00, 4, 'mountain view', FALSE, FALSE, TRUE),
('Hotel Indigo', 5, 500.00, 5, 'sea view', TRUE, FALSE, TRUE),
('InterContinetal', 1, 100.00, 1, 'mountain view', FALSE, FALSE, TRUE),
('InterContinetal', 2, 200.00, 2, 'sea view', TRUE, FALSE, TRUE),
('InterContinetal', 3, 300.00, 3, 'mountain view', FALSE, FALSE, TRUE), 
('InterContinetal', 4, 400.00, 4, 'sea view', TRUE, FALSE, TRUE),
('InterContinetal', 5, 500.00, 5, 'mountain view', FALSE, FALSE, TRUE),

('AmericInn', 1, 100.00, 1, 'sea view', TRUE, FALSE, TRUE),
('AmericInn', 2, 200.00, 2, 'mountain view', FALSE, FALSE, TRUE),
('AmericInn', 3, 300.00, 3, 'sea view', TRUE, FALSE, TRUE),
('AmericInn', 4, 400.00, 4, 'mountain view', FALSE, TRUE, TRUE),
('AmericInn', 5, 500.00, 5, 'sea view', TRUE, FALSE, TRUE),
('Baymont', 1, 100.00, 1, 'mountain view', FALSE, FALSE, TRUE),
('Baymont', 2, 200.00, 2, 'sea view', TRUE, FALSE, TRUE),
('Baymont', 3, 300.00, 3, 'mountain view', FALSE, FALSE, TRUE),
('Baymont', 4, 400.00, 4, 'sea view', TRUE, FALSE, TRUE),
('Baymont', 5, 500.00, 5, 'mountain view', FALSE, TRUE, TRUE),
('Dazzler', 1, 100.00, 1, 'sea view', TRUE, FALSE, TRUE),
('Dazzler', 2, 200.00, 2, 'mountain view', FALSE, FALSE, TRUE),
('Dazzler', 3, 300.00, 3, 'sea view', TRUE, FALSE, TRUE),
('Dazzler', 4, 400.00, 4, 'mountain view', FALSE, FALSE, TRUE),
('Dazzler', 5, 500.00, 5, 'sea view', TRUE, FALSE, TRUE),
('Esplendor', 1, 100.00, 1, 'mountain view', FALSE, FALSE, TRUE),
('Esplendor', 2, 200.00, 2, 'sea view', TRUE, FALSE, TRUE),
('Esplendor', 3, 300.00, 3, 'mountain view', FALSE, FALSE, TRUE),
('Esplendor', 4, 400.00, 4, 'sea view', TRUE, FALSE, TRUE),
('Esplendor', 5, 500.00, 5, 'mountain view', FALSE, FALSE, TRUE),
('Howard Johnson', 1, 100.00, 1, 'sea view', TRUE, FALSE, TRUE),
('Howard Johnson', 2, 200.00, 2, 'mountain view', FALSE, FALSE, TRUE),
('Howard Johnson', 3, 300.00, 3, 'sea view', TRUE, FALSE, TRUE),
('Howard Johnson', 4, 400.00, 4, 'mountain view', FALSE, FALSE, TRUE),
('Howard Johnson', 5, 500.00, 5, 'sea view', TRUE, FALSE, TRUE),
('La Quinta', 1, 100.00, 1, 'mountain view', FALSE, FALSE, TRUE),
('La Quinta', 2, 200.00, 2, 'sea view', TRUE, FALSE, TRUE),
('La Quinta', 3, 300.00, 3, 'mountain view', FALSE, FALSE, TRUE),
('La Quinta', 4, 400.00, 4, 'sea view', TRUE, FALSE, TRUE),
('La Quinta', 5, 500.00, 5, 'mountain view', FALSE, FALSE, TRUE),
('Origin', 1, 100.00, 1, 'sea view', TRUE, FALSE, TRUE),
('Origin', 2, 200.00, 2, 'mountain view', FALSE, FALSE, TRUE),
('Origin', 3, 300.00, 3, 'sea view', TRUE, FALSE, TRUE),
('Origin', 4, 400.00, 4, 'mountain view', FALSE, FALSE, TRUE), 
('Origin', 5, 500.00, 5, 'sea view', TRUE, FALSE, TRUE),
('TRYP', 1, 100.00, 1, 'mountain view', FALSE, FALSE, TRUE),
('TRYP', 2, 200.00, 2, 'sea view', TRUE, FALSE, TRUE),
('TRYP', 3, 300.00, 3, 'mountain view', FALSE, TRUE, TRUE), 
('TRYP', 4, 400.00, 4, 'sea view', TRUE, FALSE, TRUE),
('TRYP', 5, 500.00, 5, 'mountain view', FALSE, TRUE, TRUE);

INSERT INTO ROOM_AMENITY (hotel_name, room_num, amenity)
VALUES
('Canopy', 1, 'TV'),
('Canopy', 2, 'TV'),
('Canopy', 3, 'TV'),
('Canopy', 4, 'TV'),
('Canopy', 5, 'TV'),
('Conrad Hotel & Resort', 1, 'TV'),
('Conrad Hotel & Resort', 2, 'TV'),
('Conrad Hotel & Resort', 3, 'TV'),
('Conrad Hotel & Resort', 4, 'TV'),
('Conrad Hotel & Resort', 5, 'TV'),
('Curio Collection', 1, 'Pool'),
('Curio Collection', 2, 'Pool'),
('Curio Collection', 3, 'Pool'),
('Curio Collection', 4, 'Pool'),
('Curio Collection', 5, 'Pool'),
('DoubleTree', 1, 'Pool'),
('DoubleTree', 2, 'Pool'),
('DoubleTree', 3, 'Pool'),
('DoubleTree', 4, 'Pool'),
('DoubleTree', 5, 'Pool'),
('Hampton', 1, 'TV'),
('Hampton', 2, 'TV'),
('Hampton', 3, 'TV'),
('Hampton', 4, 'TV'),
('Hampton', 5, 'TV'),
('LXR Hotel & Resort', 1, 'TV'),
('LXR Hotel & Resort', 2, 'TV'),
('LXR Hotel & Resort', 3, 'TV'),
('LXR Hotel & Resort', 4, 'TV'),
('LXR Hotel & Resort', 5, 'TV'),
('Tru', 1, 'Gym'),
('Tru', 2, 'Gym'),
('Tru', 3, 'Gym'),
('Tru', 4, 'Gym'),
('Tru', 5, 'Gym'),
('Embassy Suite', 1, 'Gym'),
('Embassy Suite', 2, 'Gym'),
('Embassy Suite', 3, 'Gym'),
('Embassy Suite', 4, 'Gym'),
('Embassy Suite', 5, 'Gym'),

('Hyatt Place', 1, 'TV'),
('Hyatt Place', 2, 'TV'),
('Hyatt Place', 3, 'TV'),
('Hyatt Place', 4, 'TV'),
('Hyatt Place', 5, 'TV'),
('Spirit Ridge', 1, 'TV'),
('Spirit Ridge', 2, 'TV'),
('Spirit Ridge', 3, 'TV'),
('Spirit Ridge', 4, 'TV'),
('Spirit Ridge', 5, 'TV'),
('Andaz', 1, 'Pool'),
('Andaz', 2, 'Pool'),
('Andaz', 3, 'Pool'),
('Andaz', 4, 'Pool'),
('Andaz', 5, 'Pool'),
('Park Hyatt', 1, 'Pool'),
('Park Hyatt', 2, 'Pool'),
('Park Hyatt', 3, 'Pool'),
('Park Hyatt', 4, 'Pool'),
('Park Hyatt', 5, 'Pool'),
('The Anndore House', 1, 'TV'),
('The Anndore House', 2, 'TV'),
('The Anndore House', 3, 'TV'),
('The Anndore House', 4, 'TV'),
('The Anndore House', 5, 'TV'),
('Tempe Mission Palms', 1, 'TV'),
('Tempe Mission Palms', 2, 'TV'),
('Tempe Mission Palms', 3, 'TV'),
('Tempe Mission Palms', 4, 'TV'),
('Tempe Mission Palms', 5, 'TV'),
('The Eliza Jane', 1, 'Gym'),
('The Eliza Jane', 2, 'Gym'),
('The Eliza Jane', 3, 'Gym'),
('The Eliza Jane', 4, 'Gym'),
('The Eliza Jane', 5, 'Gym'),
('The Walper Hotel', 1, 'Gym'),
('The Walper Hotel', 2, 'Gym'),
('The Walper Hotel', 3, 'Gym'),
('The Walper Hotel', 4, 'Gym'),
('The Walper Hotel', 5, 'Gym'),

('AC Hotel', 1, 'TV'),
('AC Hotel', 2, 'TV'),
('AC Hotel', 3, 'TV'),
('AC Hotel', 4, 'TV'),
('AC Hotel', 5, 'TV'),
('Autograph Collection', 1, 'TV'),
('Autograph Collection', 2, 'TV'),
('Autograph Collection', 3, 'TV'),
('Autograph Collection', 4, 'TV'),
('Autograph Collection', 5, 'TV'),
('City Express', 1, 'Pool'),
('City Express', 2, 'Pool'),
('City Express', 3, 'Pool'),
('City Express', 4, 'Pool'),
('City Express', 5, 'Pool'),
('Delta Hotel', 1, 'Pool'),
('Delta Hotel', 2, 'Pool'),
('Delta Hotel', 3, 'Pool'),
('Delta Hotel', 4, 'Pool'),
('Delta Hotel', 5, 'Pool'),
('Courtyard', 1, 'TV'),
('Courtyard', 2, 'TV'),
('Courtyard', 3, 'TV'),
('Courtyard', 4, 'TV'),
('Courtyard', 5, 'TV'),
('Moxy', 1, 'TV'),
('Moxy', 2, 'TV'),
('Moxy', 3, 'TV'),
('Moxy', 4, 'TV'),
('Moxy', 5, 'TV'),
('Tribute', 1, 'Gym'),
('Tribute', 2, 'Gym'),
('Tribute', 3, 'Gym'),
('Tribute', 4, 'Gym'),
('Tribute', 5, 'Gym'),
('EDITION', 1, 'Gym'),
('EDITION', 2, 'Gym'),
('EDITION', 3, 'Gym'),
('EDITION', 4, 'Gym'),
('EDITION', 5, 'Gym'),

('Ritz-Carlton', 1, 'TV'),
('Ritz-Carlton', 2, 'TV'),
('Ritz-Carlton', 3, 'TV'),
('Ritz-Carlton', 4, 'TV'),
('Ritz-Carlton', 5, 'TV'),
('Aman Resort', 1, 'TV'),
('Aman Resort', 2, 'TV'),
('Aman Resort', 3, 'TV'),
('Aman Resort', 4, 'TV'),
('Aman Resort', 5, 'TV'),
('Four Seasons', 1, 'Pool'),
('Four Seasons', 2, 'Pool'),
('Four Seasons', 3, 'Pool'),
('Four Seasons', 4, 'Pool'),
('Four Seasons', 5, 'Pool'),
('Candlewood Suite', 1, 'Pool'),
('Candlewood Suite', 2, 'Pool'),
('Candlewood Suite', 3, 'Pool'),
('Candlewood Suite', 4, 'Pool'),
('Candlewood Suite', 5, 'Pool'),
('Vignette', 1, 'TV'),
('Vignette', 2, 'TV'),
('Vignette', 3, 'TV'),
('Vignette', 4, 'TV'),
('Vignette', 5, 'TV'),
('Kimpton', 1, 'TV'),
('Kimpton', 2, 'TV'),
('Kimpton', 3, 'TV'),
('Kimpton', 4, 'TV'),
('Kimpton', 5, 'TV'),
('Hotel Indigo', 1, 'Gym'),
('Hotel Indigo', 2, 'Gym'),
('Hotel Indigo', 3, 'Gym'),
('Hotel Indigo', 4, 'Gym'),
('Hotel Indigo', 5, 'Gym'),
('InterContinetal', 1, 'Gym'),
('InterContinetal', 2, 'Gym'),
('InterContinetal', 3, 'Gym'),
('InterContinetal', 4, 'Gym'),
('InterContinetal', 5, 'Gym'),

('AmericInn', 1, 'TV'),
('AmericInn', 2, 'TV'),
('AmericInn', 3, 'TV'),
('AmericInn', 4, 'TV'),
('AmericInn', 5, 'TV'),
('Baymont', 1, 'TV'),
('Baymont', 2, 'TV'),
('Baymont', 3, 'TV'),
('Baymont', 4, 'TV'),
('Baymont', 5, 'TV'),
('Dazzler', 1, 'Pool'),
('Dazzler', 2, 'Pool'),
('Dazzler', 3, 'Pool'),
('Dazzler', 4, 'Pool'),
('Dazzler', 5, 'Pool'),
('Esplendor', 1, 'Pool'),
('Esplendor', 2, 'Pool'),
('Esplendor', 3, 'Pool'),
('Esplendor', 4, 'Pool'),
('Esplendor', 5, 'Pool'),
('Howard Johnson', 1, 'TV'),
('Howard Johnson', 2, 'TV'),
('Howard Johnson', 3, 'TV'),
('Howard Johnson', 4, 'TV'),
('Howard Johnson', 5, 'TV'),
('La Quinta', 1, 'TV'),
('La Quinta', 2, 'TV'),
('La Quinta', 3, 'TV'),
('La Quinta', 4, 'TV'),
('La Quinta', 5, 'TV'),
('Origin', 1, 'Gym'),
('Origin', 2, 'Gym'),
('Origin', 3, 'Gym'),
('Origin', 4, 'Gym'),
('Origin', 5, 'Gym'),
('TRYP', 1, 'Gym'),
('TRYP', 2, 'Gym'),
('TRYP', 3, 'Gym'),
('TRYP', 4, 'Gym'),
('TRYP', 5, 'Gym');