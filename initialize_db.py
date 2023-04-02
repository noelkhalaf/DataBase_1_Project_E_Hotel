from EHotels import eHotels

msg = input('Are you sure you want to reset the e_hotels database to its initial state? (y/n): ')
if msg == 'y' or msg == 'yes' or msg == 'yep' or msg == 'yeah' or msg == 'ye':
    pass
else:
    exit('Invalid response, cancelled database reset')

try:
    eHotels.execute('DROP DATABASE `e_hotels`')
    eHotels.connectDB()
except Exception as e:
    print('Error:', e)

print('Successfully restored e_hotels database!')

with open('schema.sql', 'r') as f:
    script = f.read()

commands = script.split(';')
for command in commands:
    if command.strip() != '' and not command.startswith('--'):
        eHotels.execute(command)

print('Successfully filled e_hotels database!')