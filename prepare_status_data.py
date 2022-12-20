import urllib.request
import csv
import json
import pandas as pd

# historical endangered status records
status_records = {}
# token to make url request to Red List API
token = "<INSERT TOKEN HERE>"
# species missing historical records
missing_records = []


# make api call to Red List obtaining historical endangered status records
def obtain_records(name, classification_id):
    processed_name = '%20'.join(name.split(" "))
    request = f"https://apiv3.iucnredlist.org/api/v3/species/history/name/{processed_name}?token={token}"
    response = urllib.request.urlopen(request).read()
    parsed = json.loads(response)
    if len(parsed['result']) == 0:
        missing_records.append(name)
    else:
        records = []
        for record in parsed['result']:
            records.append([record['year'], record['category']])
        status_records[classification_id] = records



taxon_file_name = 'red_data.csv'
# contains all taxonomy classifications
taxon = pd.read_csv(taxon_file_name)

# obtain species from trades table
with open(taxon_file_name) as trades:
    reader = csv.reader(trades, delimiter=',')
    # skip header
    next(reader)
    for row in reader:
        print(row[0])
        specie_id = int(row[1])
        if specie_id not in status_records:
            specie_name = row[2]
            obtain_records(specie_name, specie_id)


# write historical records obtained from Red List API into csv for import into MySQL
with open("historical_status.csv", mode='w+') as status_table:
    writer = csv.writer(status_table, delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL, lineterminator='\n')
    writer.writerow(['species_id', 'year', 'endangered_status'])
    for classification_id, records in status_records.items():
        for record in records:
            writer.writerow([classification_id] + record)

missing_records_unique = set(missing_records)
print(f"Missing historical records for {len(missing_records_unique)} species")
print('\n'.join(missing_records_unique))
