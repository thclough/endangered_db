import csv

# list of rows to write into normalized data csv file
year_gdps = []

# mapping for country code into countryId
country_codes = {}

start_year = 1960

# create mapping for country code
with open('countries - API_NY.GDP.PCAP.CD_DS2_en_csv_v2_2445354.csv') as countries:
    reader = csv.reader(countries, delimiter=',')
    # skip header row
    next(reader)
    country_id = 1
    for row in reader:
        if row[2] != '':
            # If world_bank_code exists, add mapping
            country_codes[row[2]] = country_id
        country_id += 1

# process prepared data
with open('gdp2021.csv') as source:
    reader = csv.reader(source, delimiter=',')
    for row in reader:
        country = row[0]
        country_code = row[1]
        country_id = country_codes[country_code]
        count = 0
        for i in range(len(row[2:])):
            if row[2+i] != '':
                year_gdps.append([country_id, start_year + i, row[2+i]])
                count += 1
        print(f'{country} {country_code} (Id={country_id}): {count} GDP records added')

with open('gdp_normalized.csv', mode='w+') as destination:
    writer = csv.writer(destination, delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL, lineterminator='\n')
    for year_gdp in year_gdps:
        writer.writerow(year_gdp)
