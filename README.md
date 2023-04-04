# CSI2132 Course Project - e-Hotels

### Group 25:
- Noël Khalaf (300079144)
- Youssef Elfaramawy (300051124)
- Rageesan Pushparajah (8714073)

---

## Setup


1. Ensure your terminal is currently within the `DataBase_1_Project_E_Hotel\` directory by navigating to it.

2. Run `pip3 install -r requirements.txt` in the terminal. This will install all the necessary dependencies for the project.

3. Change the `user` and `passwd` fields at the top of the `EHotels.py` file to match your MySQL credentials

```python
host = 'localhost'
user = 'root'           # Modify this field
passwd = 'password'     # Modify this field
database = 'e_hotels'
```

4. Run `python3 initialize_db.py` in the terminal. This will reset the e_hotels database to its initial state.

## Running

1. To start the site, simply run `python3 app.py` in the terminal.
2. Copy the address next to **Running on** shown in the terminal into your browser. Or simply click this link: http://127.0.0.1:7777
