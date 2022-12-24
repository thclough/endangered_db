# Endangered Animal Database Construction and Analysis
#### By: Tighe Clough

## Background

This analysis stems from a group project in "CS3200: Database Design" at Northeastern University in Boston, Massachusetts. The group consisted of myself, Yuxuan Chen, Britney Chen, Sarah Tong, and Amaya Kejriwal. My original vision for the project proved too ambitious due to time and technology constraints. I have revisited the project to achieve these goals and have redesigned and updated the database. Additionally, I am performing continuous analysis on the database which I document through updates on this repo.

## Introduction

The international demand for animal and plant-derived products has caused alarming depletions in certain specie populations. While the world economies have become increasingly connected and prosperous in the past few centuries, the resulting market forces have overwheled wildlife in many cases. In 1975, 80 countries came together to address this issue by drafting and signing The Convention on International Trade in Endangered Species of Wild Flora and Fauna (CITES). The agreement stipulated the careful documentation and tracking of trade in threatened and endangered taxa (biological term for a group of related organisms). Currently the UN Environment Programme World Conservation Monitoring Center, on behalf of CITES, maintains the CITES database which contains 23 million records of such trade<sup>1</sup>. 

It is worth noting that the database does not contain *illegal* wildlife trade. However, the global *legal* trade of wildlife reached an estimated 119 billion USD or more in 2020, while its illegal counterpart only stood at an estimated 5 to 23 billion USD<sup>2</sup>. Therefore, the study of legal trade can give insights into overall wildlife trade patterns.

In this project, I have set out to create a database that integrates CITES data, RED list endangerment statuses, and importing/exporting/origin country statistics. Following the contruction of the database, I have theorized a few use cases to demonstrate the importance of studying this connected data.

[Skip to Analysis and Results](#analysis-and-results)



<details open>
<summary>

## Data Sources

</summary>
  
* <a href="ttrade.cites.org"> CITES Database </a> 
  * Single unnormalized table. See "Introduction" for desctiption of database. Use dropdown for field info
  
  <details>
    <summary> Field Info </summary>
    
  * Year - year of trade
  * Appendix - CITES classification relating to how endangered the taxon is ("I" being the most, "III" the least))
  * Taxon - taxa traded
  * Class
  * Order
  * Family
  * Genus
  * Term - trade term of taxa (ex. live, body, seed)
  * Quantity
  * Unit - Unit of measurment
  * Importer - Importing country
  * Exporter - Exporting country
  * Origin - Origin Country
  * Purpose
    * B - Breeding in captivity or artificial propagation
    * E - Educational
    * G - Botanical garden
    * H - Hunting trophy
    * L - Law enforcement/judcial/forensix
    * M - Medical (including biomedical research)
    * N - Reintroduction or introduction into the wild
    * P - Personal
    * Q - Circus or travelling exhibition
    * S - Scientific
    * Z - Zoo
  * Source
    * A - Plants/derivatives that have been arttificially propagated
    * C - Animals/derivatives bred in captivity
    * D - Appendix I animals or plants bred/propagated
    * F - Animals born in captivity that do not fulfill C
    * I - Confiscated or seized specimens
    * O - Pre-Convention Species
    * R - Ranched specimens (taken as eggs or juveniles from the wild and raised in captivity)
    * U - unknown
    * W - taken from the wild
    * X - taken from marine environment not under a jurisdiction
    * Y - plants/derivatives (in between artificially propagated and fully wild because had some level of human intervention)
  </details>
* <a href="https://www.iucnredlist.org/search">IUCN RED List Taxon Data</a>
  * List of all taxa in the IUCN RED List
* <a href="https://apiv3.iucnredlist.org/">RED List API </a> 
  * info on taxa and IUCN RED List conservation status for select years
* <a href="https://data.worldbank.org/indicator/NY.GDP.MKTP.CD">World Bank GDP Data </a>
  * Country GDP (Current USD) data per year
* <a href="https://data.worldbank.org/indicator/SP.POP.TOTL">World Bank Population Data </a>
  * Country population data per year
</details>

## Methods

### Database Design and Construction


The database enhances CITES data (found in the trade table) through attaching relevant information on the traded animals/plant and importing/exporting/origin countries. 

The "taxon" table lists taxa information (kingdom to species) for each taxa in the trade table. Addtionally, Red List conservation status by year on certain taxa is listed in the "historical_status" table.  

The country table creates a country_id for each CITES country and serves to connect trades in the "trade" table with relevant country statistics (namely gdp and population). The "gdp" and "population" tables provided yearly data for countries/regions from World Bank Open Data. Most World Bank countries align with CITES countries. Notably, regions do not align. For example, the CITES incldued data for the region "Asia" while the World Bank does not.

<!-- <img src="https://github.com/thclough/endangered_db/blob/main/readme_images/historical_status.png" width="800" height="563"></img> -->

![ER](https://github.com/thclough/endangered_db/blob/main/readme_images/historical_status.png)

<details open>
<summary>

### See data wrangling process and code blocks below

</summary>

The strategy is to prepare each table as a csv using Python and then load each table into a database. The CITES table is unnormalized and unconducive to attaching data. As the "trade" table is a child to both the "taxon" and "country" tables, these parent tables and their primary keys must be prepared first. The primary keys from these tables can then be inserted as foreign keys into the "trade" table.
  
I first imported relevant packages and read in all of the data from the CSV's, only keeping selected columns:
```python
import pandas as pd
import numpy as np
import joblib

cols = ["Year", "Appendix", "Taxon", "Class", "Order", "Family", "Genus", "Term", "Quantity", "Unit", "Importer", "Exporter", "Origin", "Purpose", "Source"]
  
# create dataframe to append data to
master = pd.DataFrame(columns = cols)

# CITES CSV's are downloaded in separate parts so must put together in one dataframe
for doc_num in range(1, 49):
    temp = pd.read_csv(f"data/cites_master/trade_db_{doc_num}.csv", usecols = cols)
    master = pd.concat([master, temp])
```

The newest data (impartial data for 2022) is formatted slightly different:

<img src ="https://github.com/thclough/endangered_db/blob/main/readme_images/new%20data.png" width=1000 height=100></img>

We must use a different method for reading in the data, and format it to fit our existing dataframe:
```python
# read 2022 data
new_cols = ["Year", "App.", "Taxon", "Class", "Order", "Family", "Genus","Term", "Importer reported quantity", "Exporter reported quantity", "Unit", "Importer", "Exporter", "Origin", "Purpose", "Source"]
twenty_df = pd.read_csv(f"data/cites_master/cites_2022.csv", usecols = new_cols)

# newer data separates exporter reported quantity and importer reported quantity
# only one party (importer or exporter) reports quantity meaning we can
# sum import/export quantity into one new column to get the general traded quantity and drop the old separaecolumns

# replace nan values with 0's for valid summation
twenty_df["Importer reported quantity"] = twenty_df["Importer reported quantity"].replace(np.nan, 0)
twenty_df["Exporter reported quantity"] = twenty_df["Exporter reported quantity"].replace(np.nan, 0)

# sum the importer and exporter quantities
twenty_df["Quantity"] = twenty_df["Importer reported quantity"] + twenty_df["Exporter reported quantity"]
twenty_df = twenty_df.drop(columns = ["Importer reported quantity", "Exporter reported quantity"])

# rename appendix column to match other data
twenty_df = twenty_df.rename(columns = {"App.": "Appendix"})

# combine dataframes to get full year range (1975-2022)
master2 = pd.concat([master, twenty_df])
```

The master dataframe containing all of the CITES data has many different units:

```python
master2["Unit"].unique()
```
Output
```python
array(['kg', 'g', nan, 'shipments', 'sets', 'm', 'pieces', 'cartons',
       'ml', 'l', 'bags', 'oz', 'flasks', 'pairs', 'cases', 'boxes',
       'sides', 'm2', 'cm', 'inches', 'cans', 'items', 'bottles', 'ft3',
       'm3', 'cm3', 'backskins', 'bellyskins', 'cm2', 'hornback skins',
       'mg', '(skins)', 'microgrammes', 'ft2', 'lbs', 'metric tonnes',
       'dm2', 'Number of specimens'], dtype=object)
```

I converted units to SI units where I could:
```python
# dictionary for converting units
# each key have tuple value containing new unit name and conversion factor
conv_dict = {# length
             "cm" : ("m", 10e-4),
             "inches" : ("m", 0.0254),
             "ft" : ("m", 0.3048),
             # area
             "cm2" : ("m2", 10e-5),
             "dm2" : ("m2", 10e-3),
             "ft2" : ("m2", 0.092903),
             # mass
             "microgrammes": ("kg", 10e-10),
             "mg" : ("kg", 10e-7), #milligram
             "g"  : ("kg", 10e-4), 
             "oz" : ("kg", 0.0283495),
             "lbs": ("kg", 0.453592),
             "metric tonnes" : ("kg", 1000),
             # volume
             "cm3" : ("m3", 10e-7),
             "ml"  : ("m3", 10e-7),
             "l"   : ("m3", 10e-4),
             "ft3" : ("m3", 0.0283168)}

for orig_unit, val in conv_dict.items():
    si_unit = val[0]
    conv_factor = val[1]
    
    # find the correct filter
    filt = master2["Unit"] == orig_unit
    
    master2.loc[filt, "Quantity"] = master2.loc[filt, "Quantity"] * conv_factor
    master2.loc[filt, "Unit"] = si_unit
```

I then summed the quantities of trades with identical characteristics for each year for easier analysis:
  
<img src ="https://github.com/thclough/endangered_db/blob/main/readme_images/sum.png" width=1000 height=100></img>
```python
# nearly identical trades (only differentiated by quantity) in the same year are separate 
# use groupby to create one entry where quantities are amalgamated for one year

by_cols = cols[:]
by_cols.remove("Quantity") # group by everything except quantity (only differentiator)
master2 = master2.groupby(by = by_cols, dropna = False).sum().sort_values(by_cols)
master2 = master2.reset_index()
```

I then dropped all entries that did not have specic taxa data:

```python
master2 = master2[[len(taxon) > 1 for taxon in master2["Taxon"].str.split()]]
```

I then made all of the taxonomy names lowercase for easy comparison:

```python
# make all lower case for comparison with taxon table
lower_cols = ["Class", "Order", "Family", "Genus", "Taxon"]
master2[lower_cols] = master2[lower_cols].copy(deep=True).apply(lambda x: x.str.lower())
```

#### Taxon Table

First need to read in all the 

</details>

## Analysis and Results

## Citations

<br>

[1] CITES Secretariat and UNEP-WCMC (2022). A guide to using the CITES Trade Database. Version 9. Geneva, Switzerland, and Cambridge, UK. https://trade.cites.org/cites_trade_guidelines/en-CITES_Trade_Database_Guide.pdf
<br>
[2] Tow, J. H., Symes, W. S., & Carrasco, L. R. (2021, October 12). Economic value of illegal wildlife trade entering the USA. PLOS ONE. https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0258523
</details>
