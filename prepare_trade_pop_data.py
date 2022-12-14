import csv

with open('trade.csv', 'r') as trades, open('medical_purpose_trades.csv', 'w') as medical_trades:
    reader = csv.reader(trades, delimiter=',')
    writer = csv.writer(medical_trades, delimiter=',', lineterminator='\n')
    writer.writerow(next(reader))
    trade_id = 0
    for row in reader:
        purpose = row[5]
        if purpose == 'medical':
            writer.writerow([trade_id, row[1], row[2], row[3], row[4], row[5], row[6], row[7], row[8], row[9], row[10], row[11]])
            trade_id += 1

    trades.close()
    medical_trades.close()