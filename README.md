# Endangered Animal Database Construction and Analysis
#### By: Tighe Clough

## 1) Background

This analysis stems from a group project in "CS3200: Database Design" at Northeastern University. The group consisted of myself, [Yuxuan Chen](https://github.com/OOYUKIOO), [Britney Chen](https://github.com/britneyart80), [Sarah Tong](https://github.com/saraht0ng), and Amaya Kejriwal. My original vision for the project proved too ambitious due to time and technology constraints. I have revisited the project to achieve these goals and have redesigned and updated the database. Additionally, I am performing continuous analysis on the database which I document through updates on this repo.

## 2) Introduction

The international demand for animal and plant-derived products has caused alarming depletions in certain specie populations. While the world economies have become increasingly connected and prosperous in the past few centuries, the resulting market forces have overwheled wildlife in many cases. In 1975, 80 countries came together to address this issue by drafting and signing The Convention on International Trade in Endangered Species of Wild Flora and Fauna (CITES). The agreement stipulated the careful documentation and tracking of trade in threatened and endangered taxa (biological term for a group of related organisms). Currently the UN Environment Programme World Conservation Monitoring Center, on behalf of CITES, maintains the CITES database which contains 23 million records of such trade<sup>1</sup>. 

It is worth noting that the database does not contain *illegal* wildlife trade. However, the global *legal* trade of wildlife reached an estimated 119 billion USD or more in 2020, while its illegal counterpart only stood at an estimated 5 to 23 billion USD<sup>2</sup>. Therefore, the study of legal trade can give insights into overall wildlife trade patterns.

In this project, I have set out to create a database that integrates CITES data, Red list endangerment statuses, and importing/exporting/origin country statistics. Following the contruction of the database, I have thought up a few scenarios to guide analysis and to demonstrate the importance of studying this connected data.

[Skip to Analysis and Results](#5-analysis-and-results)



<details open>
<summary>

## 3) Data Sources

</summary>
  
* <a href="ttrade.cites.org"> CITES Database </a> 
  * Single unnormalized table. See "Introduction" for description of database. Use dropdown for field info.
  
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
* <a href="https://www.iucnredlist.org/search">IUCN Red List Taxon Data</a>
  * List of all taxa in the IUCN Red List
* <a href="https://apiv3.iucnredlist.org/">Red List API </a> 
  * info on taxa and IUCN Red List conservation status for select years
* <a href="https://data.worldbank.org/indicator/NY.GDP.MKTP.CD">World Bank GDP Data </a>
  * Country GDP (Current USD) data per year
* <a href="https://data.worldbank.org/indicator/SP.POP.TOTL">World Bank Population Data </a>
  * Country population data per year
</details>

## 4) Methods

### 4,1) Database Design and Construction


The database enhances CITES data (found in the trade table) through attaching relevant information on the traded animals/plant and importing/exporting/origin countries. 

The "taxon" table lists taxa information (kingdom to species) for each taxa in the trade table. Addtionally, Red List conservation status by year on certain taxa is listed in the "historical_status" table.  

The country table creates a country_id for each CITES country and serves to connect trades in the "trade" table with relevant country statistics (namely gdp and population). The "gdp" and "population" tables provided yearly data for countries/regions from World Bank Open Data. Most World Bank countries align with CITES countries. Notably, regions do not align. For example, the CITES incldued data for the region "Asia" while the World Bank does not.

Upon close inspection, one can see that the "taxon" table is not very normalized. Taxon data is heirarchical and therefore has many depedencies. It is not worth the effort to normalize the table by separating out each level of taxonomy to its own table. Joining such tables for later analysis would be tedious and unneccessary.

<!-- <img src="https://github.com/thclough/endangered_db/blob/main/readme_images/historical_status.png" width="800" height="563"></img> -->

![ER](https://github.com/thclough/endangered_db/blob/main/readme_images/historical_status.png)

<details>
<summary>

### See data wrangling process and code blocks

</summary>

The strategy is to prepare each table as a CSV using Python and then load each table into a database. The CITES table is unnormalized and unconducive to attaching data. As the "trade" table is a child to both the "taxon" and "country" tables, these parent tables and their primary keys must be prepared first. The primary keys from these tables can then be inserted as foreign keys into the "trade" table.

#### 4,1,1) "trade" Table CSV
	
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
    temp = pd.read_csv(f"<path to CITES data>/trade_db_{doc_num}.csv", usecols = cols)
    master = pd.concat([master, temp])
```

The newest data (impartial data for 2022) is formatted slightly different:

<img src ="https://github.com/thclough/endangered_db/blob/main/readme_images/new%20data.png" width=1000 height=100></img>

We must use a different method for reading in the data, and format it to fit our existing dataframe:
```python
# read 2022 data
new_cols = ["Year", "App.", "Taxon", "Class", "Order", "Family", "Genus","Term", "Importer reported quantity", "Exporter reported quantity", "Unit", "Importer", "Exporter", "Origin", "Purpose", "Source"]
twenty_df = pd.read_csv(f"<path to CITES data>/cites_2022.csv", usecols = new_cols)

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

#### 4,1,2) "taxon" Table CSV

The "taxon" table will be a parent of the trade table. The table will contain all taxa in the IUCN RED List along with those in the trade table. My manipulation of the trade table dataframe so far has been in preparation for comapring the two CSVs, seeing which taxa are in CITES trade data but NOT in the IUCN RED List data, then adding those to the "taxon" table. For example, there are hyprid species and "spp" (more than one species of the same genus) in the CITES trade data which are not in the IUCN RED List: 

<img src ="https://github.com/thclough/endangered_db/blob/main/readme_images/spp.png"></img>
<img src ="https://github.com/thclough/endangered_db/blob/main/readme_images/hybrid.png"></img>

So I first had to load the IUCN taxon data into a new dataframe:

```python
#### Read in taxon data ####
# taxon data from IUCN Red List database of endangered animals
# every entry in "trade" table will have a taxon id, linking to the "taxon" table, participation is mandatory

# columns to use
cols = ["kingdomName", "phylumName", "className", "orderName", "familyName", "genusName", "speciesName"]

# read csvs (had to read two because of data export limits from Red)
LC = pd.read_csv("original_data/taxonomy_LC.csv", usecols = cols)
ex_LC = pd.read_csv("original_data/taxonomy_ex.csv", usecols = cols)

# combine
taxon_df = pd.concat([LC, ex_LC])

# lowercase for good looks
taxon_df = taxon_df.apply(lambda x: x.str.lower())

# get rid of the weird naming
taxon_df.columns = [col.replace("Name","") for col in taxon_df.columns]

# create a taxon column
taxon_df["taxon"] = (taxon_df["genus"] + ' ' + taxon_df["species"]).copy(deep = True)
```

I added higher order classification data to CITES trade taxon that were missing such data and performed an outer join to obtain a comprehensive taxon dataframe: 

```python
# take just the taxon data out of the cites trade table
cites_taxon = master2[lower_cols].copy(deep=True).drop_duplicates()

# lower case the column labels to match with the taxon table columns
cites_taxon.columns = [col.lower() for col in cites_taxon.columns]

# get kingdom and phylum for the CITES data
# create a df for the classes with their kingdoms and phylums 
higher = taxon_df[["kingdom", "phylum", "class"]].drop_duplicates() # unique kingdom, phylum, class in taxon_df
cites_taxon = cites_taxon.merge(higher, how="outer", on="class")

# outer join for comprehensive set of taxa
on_cols = ["kingdom", "phylum", "class", "order", "family", "genus", "taxon"]
taxon_df = taxon_df.merge(cites_taxon, how="outer", on=on_cols).drop_duplicates().dropna(subset=["taxon"])
```

#### 4,1,3) "historical_status" Table CSV

[Yuki Chen](https://github.com/OOYUKIOO) wrote the original code to fetch data from the Red List API.

The original project only only collected data on taxon related to medicinal purposes. In this extension of the project, I decided to collect data on all CITES taxon that were in the Red List. While this was a lengthier process, it made for a more complete data set. I prepared the list of CITES taxon for Red List data collection with a simple pandas inner join:

```python
# get the taxon name and then merge with original taxon data on taxon
temp = master2.merge(taxon_df2, left_on="taxon_id", right_index=True).merge(taxon_df, on="taxon")[["taxon_id", "taxon", "species_y"]].drop_duplicates()
```

See code [here](https://github.com/thclough/endangered_db/blob/main/prepare_status_data.py) for fetching data from the API.

#### 4,1,4) "country" Table CSV

[Sarah Tong](https://github.com/saraht0ng) and myself modified the original list of World Bank countries and codes given

We created the primary keys for each country and mapped the World Bank countries to each CITES country. These primary keys are used as foreign keys in the "gdp" and "population" tables.

#### 4,1,5) "gdp" and "population" Table CSV

[Yuki Chen](https://github.com/OOYUKIOO) wrote original code to format the "gdp" Table CSV found [here](https://github.com/thclough/endangered_db/blob/main/prepare_gdp_data.py)

This code normalized the World Bank gdp data for each country. I repurposed the code to normalize population data.

#### 4,1,6) Aligning Parent and Child Keys

I first created a primary key disctionary for the "taxon" table and mapped them into the trade table:

```python
### Aligning foreign keys for creation of database

# find the foreign keys for the taxon data
# create way to map foreign keys
# giving each taxa an index number (starts at 0 so adding 1)
taxon_dict = {y:x+1 for x,y in taxon_df["taxon"].to_dict().items()}

# add foreign keys
master2["taxon_id"] = master2["Taxon"].map(taxon_dict)
```

A similar process for the "country" foreign keys:

```python
# Create foreign keys for different countries
# data taken from World Bank
countries_df = pd.read_csv("original_data/countries - API_NY.GDP.PCAP.CD_DS2_en_csv_v2_2445354.csv", index_col=0)

countries_df.reset_index(drop=True, inplace=True)

# some weird countries to change out
master2 = master2.replace("YD","YE")
master2 = master2.replace("NT","AN")
master2 = master2.replace("HS","") # HS typo (maybe does not exist)

# create map for foreign keys
countries_dict = {y:int(x+1) for x,y in countries_df["cites_code"].to_dict().items()}

# insert correct foreign keys
master2["importer_id"] = master2["Importer"].map(countries_dict)
master2["exporter_id"] = master2["Exporter"].map(countries_dict)
master2["origin_id"] = master2["Origin"].map(countries_dict)
```

I dropped unwanted columns/entries and finalized the indices:

```python
# drop unneeded columns
master2 = master2.drop(["Taxon","Class", "Order", "Family", "Exporter","Importer", "Origin","Species","Genus"],axis=1)

# every entry needs all three foreign 
master2 = master2.dropna(subset=["importer_id", "exporter_id", "origin_id"])

# reset index ands start at 1
master2.reset_index(drop=True, inplace = True)
master2.index += 1
```

</details>

## 5) Analysis and Results

Scenario: WildAid is a US-based environmental organization that manages campaigns to reduce demand for wildlife products. They would like to know which taxon are currently in most demand and for which purpose so that they can most efficiently strategize their next campaign.


### 5,2) Medicine Scenario

Certain taxon are valued for their supposed medicinal properties. Here I have visualized trends in medicinal trades.

**GOAL**: Find **1)** which endangered taxon are most at threat from medicine-driven trade, and **2)** which countries are driving this demand.

#### Key Findings (TL;DR)

* Chinese Pond Turtle mauremys_reevesii 

<details>

<summary>

#### See Queries and Explanations

</summary>

To analyze "medicine" trades I first had to filter the trades down to those with the term "medicine". While there is an "M" (medical) purpose, this is too broad because it includes taxon used for biomedical research. In fact, I found when including all trades under the "M" purpose that biomedical trades dominated the resulting outputs. The taxon accounting for most medicine and "M" trades was the "macaca fascicularis" or crab-eating macaque (see side note below). This animal is not traded for its medicinal properties but for its use in epxerimentation due to their close physiology with humans (see "Tangent" dropdown below)

<details>

<summary>
  
#### Tangent

</summary>

When first approaching medical trade analysis, I chose to filter trades under either term "Medicine" or purpose "M" to have more data. The "Medicine" term only has 2977 entries out of 2.5 million + total entries in the trade table. I also started out by comparing trades where the quantity referred to number of specimens (not another unit like kg).
	
```sql
-- create view for cleaner querying 
create view med_trades as
	select *
	from trade 
	where term = "medicine" or purpose = "M";

-- data guide says that "if no unit is shown the quantity represents the number of specimens
-- let's filter down to no units listed and "Number of specimens" for specimens only
drop view if exists world_specimen_med_trades;
create view world_specimen_med_trades as
	select *
    from med_trades -- not joining, no need to carry around all data, wait to join at end
    where unit = '' or unit = "Number of specimens";
-- need this intermediate view to go back to for further analysis

-- let's group by year and taxon_id, sum across all trades for year regardless of origin, importer, exporters
-- then find most traded animal per year
drop view if exists world_specimen_med_trades_per_year;
create view world_specimen_med_trades_per_year as
	select year, taxon_id, appendix, sum(quantity) as tot_traded
	from world_specimen_med_trades
	group by year, taxon_id, appendix
	order by year, taxon_id;
-- max traded med species traded per year

with
	-- temp table containing year and taxon_id with maximum amount of trades
	max_taxon_world_specimen_med_trades_per_year as
		(select * 
		from world_specimen_med_trades_per_year
		where (year, tot_traded) in
			(select year, max(tot_traded)
			from world_specimen_med_trades_per_year
			group by year))
	select year, taxon_id, taxon_name, appendix, tot_traded -- save join for very last to be the most efficient and cleaner code
    from max_taxon_world_specimen_med_trades_per_year left join taxon using (taxon_id);
```

I quickly found this was insufficient. The following output, which shows the max traded taxon per year listed under the term "medicine" or purpose "M", is dominated by taxa for biomedical research, particularly "macaca fascicularis" as mentioned above:
  
Output:

|year|taxon_name                |appendix|tot_traded|
|----|--------------------------|--------|----------|
|1977|erythrocebus patas        |II      |4         |
|1977|pan troglodytes           |I       |4         |
|1978|alligator mississippiensis|I       |273       |
|1979|chlorocebus aethiops      |II      |88        |
|1980|chlorocebus aethiops      |II      |60        |
|1981|macaca fascicularis       |II      |895       |
|1982|macaca fascicularis       |II      |723       |
|1983|macaca fascicularis       |II      |4038      |
|1984|macaca fascicularis       |II      |7184      |
|1985|macaca fascicularis       |II      |13653     |
|1986|macaca fascicularis       |II      |652       |
|1987|chlorocebus aethiops      |II      |662       |
|1988|macaca fascicularis       |II      |750       |
|1989|hirudo medicinalis        |II      |15080     |
|1990|hirudo medicinalis        |II      |8090      |
|1991|hirudo medicinalis        |II      |14238     |
|1992|hirudo medicinalis        |II      |50160     |
|1993|macaca fascicularis       |II      |11522     |
|1994|macaca fascicularis       |II      |25023     |
|1995|aloe ferox                |II      |330000    |
|1996|macaca fascicularis       |II      |14745     |
|1997|macaca fascicularis       |II      |15132     |
|1998|hirudo medicinalis        |II      |56000     |
|1999|macaca mulatta            |II      |28084     |
|2000|macaca fascicularis       |II      |42938     |
|2001|macaca fascicularis       |II      |103709    |
|2002|macaca fascicularis       |II      |145675    |
|2003|macaca fascicularis       |II      |73970     |
|2004|macaca fascicularis       |II      |70192     |
|2005|macaca fascicularis       |II      |81818     |
|2006|macaca fascicularis       |II      |67504     |
|2007|daboia russelii           |III     |337726    |
|2008|daboia russelii           |III     |333210    |
|2009|macaca fascicularis       |II      |440029.9  |
|2010|daboia russelii           |III     |552086    |
|2011|daboia russelii           |III     |538496    |
|2012|daboia russelii           |III     |415541    |
|2013|cairina moschata          |III     |2934849   |
|2014|cairina moschata          |III     |8577995   |
|2015|cairina moschata          |III     |10090928  |
|2016|cairina moschata          |III     |5021559   |
|2017|daboia russelii           |III     |1063842   |
|2018|daboia russelii           |III     |844536    |
|2019|chlorocebus aethiops      |II      |360001143 |
|2020|prunus africana           |II      |634050    |
|2021|alligator mississippiensis|II      |2320      |

</details>

Instead, I want to focus on taxa that are traded for medicinal consumption. This fits into the WildAid strategy of targeting individual consumer demand. I first filtered by the term "medicine" and relevant purposes (see code comments for selected purposes)

```sql
-- also only if purpose is in B (Breeding/propagation), M (Medical), P (Personal), T (commercial), and blank
-- don't want to include purposes like S (Scientific), H (Hunting Trophy), L (law enforcement/foresic) because those have nothing to do with medicine
drop view if exists medicine_species_trades;
create view medicine_species_trades as 
	select * from trade join taxon using (taxon_id)
	where term = "medicine" and purpose in ("B", "M", "P", "T", "");
```
	
I then decided to breakout the analysis by the Kingdoms Animalia (animals) and ex-Animalia (plants) because comparing absolute quantities between plants and animals is misleading, especially when looking at certain units such as kg. Plants typically come in much smaller quantities because they are naturally smaller than many animals. This query is for filtering by animalia:

```sql
-- create view for any medicine animalia trades 
drop view if exists medicine_animalia_trades;
create view medicine_animalia_trades as
	select *
	from medicine_species_trades
	where kingdom_name = "animalia";
```
	
I further broke each of these categories down into "Number of specimens" and kg for similar comparison. According to the CITES guide, any trade without a unit can be assumed to be measured in specimens as well as those with the explicit "Number of specimens" unit. The query is for filtering out trades where the unit is number of specimens:

```sql
### medicine animalia: No unit ('') and "Number of specimens"
drop view if exists specimen_medicine_animalia_trades;
create view specimen_medicine_animalia_trades as
	select *
    from medicine_animalia_trades
    where unit in ('', 'Number of specimens');
```

For each of these subcategories, I wrote a query to break out the total amount of taxa traded by appendix (how endangered the taxa is).
Example for [Section 5,2,1](#521-medicine---animalia---number-of-specimens) Figure 1.
```sql
select
    year,
    sum(case when appendix = "I" then quantity else 0 end) as I,
    sum(case when appendix = "II" then quantity else 0 end) as II,
    sum(case when appendix = "III" then quantity else 0 end) as III,
    sum(quantity) as total
from specimen_medicine_animalia_trades
group by year;
```

I then summed up trades among taxa by year regardless of importer, exporter, or origin. I finally found the most traded taxa per year by appendix. See example below used for [Section 5,2,1](#521-medicine---animalia---number-of-specimens) : 
	
```sql
-- max taxon each year
with
	-- temp table containing year and taxon_id with maximum amount of trades
	max_world_specimen_medicine_animalia_trades as
		(select * 
		from world_specimen_medicine_animalia_trades
		where (year, appendix, tot_traded) in
			-- maximum quantity for each taxon by year
			(select year, appendix, max(tot_traded)
			from world_specimen_medicine_animalia_trades
			group by year, appendix))
	select year, taxon_id, taxon_name, appendix, tot_traded -- save join for very last to be the most efficient and cleaner code
    from max_world_specimen_medicine_animalia_trades;
```
	
</details>

#### 5,2,1) Medicine - Animalia - Number of Specimens
*Figure 1*
![5,2,1 Figure 1](https://github.com/thclough/endangered_db/blob/main/query_output_and_visualizations/medical/medicine/Animalia/specimen/Medicine%20-%20Animalia%20-%20Number%20of%20Specimens%20-%20Trades%20vs%20Year%20by%20Appendix.png)

I chose to start with a simple visualization of the trades over time broken out by CITES appendix (Appendix I the most threatened and III the least). While Appendix III taxa account for the vast majority of trade (**notice the different y-axis scales**), a large increase in Appendix I trade would raise the most concern.

For the Appendix I trades, there was a large increase starting in 2013, that peaked in 2014, and receded in 2015. I queried to find the most traded taxa by year broken out by appendix (see final example query in [Queries and Explanation Section](#see-queries-and-explanations)). 

The most traded Appendix I animal in 2013 and 2014 by specimen under the term medicine was "crocodylus siamensis" or the Siamese Crocodile. This animal is commonly farmed and exploited for its medicinal properties cooming from its oil and blood<sup>3</sup>. This particular taxa does not raise concern as its trade has plummited. Instead, I am looking for taxa with sustained levels of high trade which indicate an ongoing problem.

<details>

<summary>

#### See Output for Most Traded Taxon per Year by Appendix
	
</summary>
	
|year|taxon_id|taxon_name                |appendix|tot_traded|
|----|--------|--------------------------|--------|----------|
|2009|136436  |moschus moschiferus       |II      |358140    |
|2010|136551  |moschus spp.              |II      |10        |
|2010|134639  |daboia russelii           |III     |144951    |
|2011|6336    |alligator mississippiensis|II      |3887      |
|2011|134639  |daboia russelii           |III     |191205    |
|2012|101703  |panthera tigris           |I       |833       |
|2012|6336    |alligator mississippiensis|II      |23778     |
|2012|134639  |daboia russelii           |III     |143590    |
|2013|75841   |crocodylus siamensis      |I       |111935    |
|2013|136551  |moschus spp.              |II      |76671     |
|2013|50207   |cairina moschata          |III     |2934844   |
|2014|75841   |crocodylus siamensis      |I       |405070    |
|2014|136551  |moschus spp.              |II      |46606     |
|2014|50207   |cairina moschata          |III     |8577995   |
|2015|101703  |panthera tigris           |I       |2213      |
|2015|136551  |moschus spp.              |II      |32138     |
|2015|50207   |cairina moschata          |III     |10090928  |
|2016|101703  |panthera tigris           |I       |1335      |
|2016|136686  |saiga tatarica            |II      |27186     |
|2016|50207   |cairina moschata          |III     |5021559   |
|2017|101703  |panthera tigris           |I       |6150      |
|2017|136436  |moschus moschiferus       |II      |36823     |
|2017|134639  |daboia russelii           |III     |435985    |
|2018|129985  |ursus thibetanus          |I       |8947      |
|2018|45832   |ursus arctos              |II      |212239    |
|2018|134639  |daboia russelii           |III     |324670    |
|2019|45832   |ursus arctos              |II      |527011    |
|2019|134639  |daboia russelii           |III     |549181    |
|2020|45832   |ursus arctos              |II      |104620    |
|2020|134639  |daboia russelii           |III     |385250    |

</details>

#### 5,2,2) Medicine - Animalia - kg
*Figure 1*
![5,2,2 Figure 1](https://github.com/thclough/endangered_db/blob/main/query_output_and_visualizations/medical/medicine/Animalia/kg/Medicine%20-%20Animalia%20-%20kg%20-%20Trades%20vs%20Year%20by%20Appendix.png)

There is sustained trade in Appendix III animal taxa trade. Looking at the max taxa per year output (see below), the main driver for this trend is "mauremys reevesii" (the Chinese Pond Turtle) year after year. The plastron (or belly shell) of the Chinese Pond Turtle is common in traditional Chinese medicine <sup>4</sup>.

<details>

<summary>

#### See Output for Most Traded Taxon per Year by Appendix
	
</summary>

|year|taxon_id|taxon_name                |appendix|total_traded|
|----|--------|--------------------------|--------|------------|
|2009|136686  |saiga tatarica            |II      |12.975      |
|2010|136551  |moschus spp.              |II      |2.885       |
|2011|136686  |saiga tatarica            |II      |35.609      |
|2011|111654  |mauremys reevesii         |III     |265.75      |
|2012|129985  |ursus thibetanus          |I       |0.005       |
|2012|136364  |cetacea spp.              |II      |192         |
|2012|111654  |mauremys reevesii         |III     |727.545     |
|2013|134462  |testudinidae spp.         |I       |20          |
|2013|136686  |saiga tatarica            |II      |351.973     |
|2013|111654  |mauremys reevesii         |III     |1184.944    |
|2014|101703  |panthera tigris           |I       |5.873       |
|2014|136686  |saiga tatarica            |II      |320.082     |
|2014|111654  |mauremys reevesii         |III     |7480.137    |
|2015|129985  |ursus thibetanus          |I       |0.555       |
|2015|134462  |testudinidae spp.         |II      |3085.05     |
|2015|111654  |mauremys reevesii         |III     |2982.386    |
|2016|129985  |ursus thibetanus          |I       |0.006       |
|2016|136686  |saiga tatarica            |II      |885.136     |
|2016|111654  |mauremys reevesii         |III     |4203.8      |
|2017|129825  |panthera pardus           |I       |0.382       |
|2017|136686  |saiga tatarica            |II      |672.114     |
|2017|111654  |mauremys reevesii         |III     |6471.558    |
|2018|136379  |rhinocerotidae spp.       |I       |6           |
|2018|134640  |naja naja                 |II      |409.522     |
|2018|111654  |mauremys reevesii         |III     |4272.12     |
|2019|136686  |saiga tatarica            |II      |149.711     |
|2019|111654  |mauremys reevesii         |III     |2311.819    |
|2020|136551  |moschus spp.              |II      |41.615      |
|2020|111654  |mauremys reevesii         |III     |2269.75     |

</details>

<img src="https://upload.wikimedia.org/wikipedia/commons/e/e0/Naturalis_Biodiversity_Center_-_RMNH.ART.274_-_Chinemys_reevesii_-_Mauremys_reevesii_-_Kawahara_Keiga_-_1823_-_1829_-_Siebold_Collection_-_white_background.jpeg" height=211 width=456></img>
<br>
*Mauremys reevesii: The Chinese Pond Turtle*

This trade pattern in Chinese Pond Turtles presents itself as a target for an NGO like WildAid and requires further querying to identify importers and gather further information on its population.

I started off by querying for the largest importer by absolute quantity for each year. I found that Japan has been the largest importer by absolute amount of kilograms starting in 2014. I then decided to query by largest importer on a per 100,000 population basis to correct for population and identify if the average consumer in one country had more demand for the Chinese Pond Turtle over consumers in other countries. Again, Japan was the largest on a per capita basis, this time since 2013. I finally looked into the IUCN conservation status of the Chinese Pond Turtle. The Red list has classified the turtle as Endangered since 2011. While trade in the turtle is continuously high, trade has declined in the past few year.

<details>
<summary>
	
#### See Queries and Output
	
</summary>

#### Largest Importers of the Chinese Pond Turtle for Medicinal Puposes in kg by Year

```SQL
with turtle_importer_sums_per_year as -- first sum imports by year for each importer
	(select
		year,
		importer_id,
		sum(quantity) as total_traded
	from kg_medicine_animalia_trades
    where taxon_name = "mauremys reevesii"
	group by year, importer_id)
select
	year,
    country_name,
    total_traded
    from turtle_importer_sums_per_year t join country c on t.importer_id = c.country_id
	where (year, total_traded) in
		-- table with max 
        (select
		year,
        max(total_traded) as total_traded
		from turtle_importer_sums_per_year
		group by year)
	order by year;
```
	
|year|country_name|total_traded              |
|----|------------|--------------------------|
|2011|United States|142.54                    |
|2012|United States|659.82                    |
|2013|United States|624.98                    |
|2014|Japan       |7175.76                   |
|2015|Japan       |2833.75                   |
|2016|Japan       |4080.6000000000004        |
|2017|Japan       |6160.9000000000015        |
|2018|Japan       |4080.6                    |
|2019|Japan       |2267                      |
|2020|Japan       |2138.98                   |


#### Largest Importers of the Chinese Pond Turtle for Medicinal Puposes in kg/100000 people by Year

```sql
with turtle_importer_sums_per_year as -- first sum imports by year for each importer
	(select
		year,
		importer_id,
		sum(quantity) as total_traded
	from kg_medicine_animalia_trades
    where taxon_name = "mauremys reevesii"
	group by year, importer_id),
turtle_kg_per_100k as
	(select
	year,
    country_name,
    total_traded/total_pop * 100000 as kg_per_1k
	from turtle_importer_sums_per_year t
	join country c on t.importer_id = c.country_id
    join population p using (year, country_id))
select *
from turtle_kg_per_100k
where (year,kg_per_100k) in
	(select 
		year,
		max(kg_per_100k)
    from turtle_kg_per_100k
    group by year);
```
|year|country_name|kg_per_100k                 |
|----|------------|--------------------------|
|2011|Canada      |0.18582192406327813       |
|2012|United States|0.2102156603931885        |
|2013|Japan       |0.3923261014555298        |
|2014|Japan       |5.637952166944279         |
|2015|Japan       |2.228824690697729         |
|2016|Japan       |3.2111492335295413        |
|2017|Japan       |4.852172132438649         |
|2018|Japan       |3.2178596493995           |
|2019|Japan       |1.7902126617864222        |
|2020|Japan       |1.6940939799304615        |

#### IUCN Conservation Status of the Chinese Pond Turtle
```sql
select 
    year,
    taxon_name,
    endangered_status
from taxon join historical_status using(taxon_id)
where taxon_name = "mauremys reevesii";
```
|year|taxon_name|endangered_status         |
|----|----------|--------------------------|
|2011|mauremys reevesii|Endangered                |

</details>

#### 5,2,3) Medicine - Ex-Animalia (Plants) - Number of Specimens
*Figure 1*
![5,2,3 Figure 1](https://github.com/thclough/endangered_db/blob/main/query_output_and_visualizations/medical/medicine/Ex-Animalia/specimen/Medicine%20-%20Plantae%20-%20Number%20of%20Specimens%20-%20Trades%20vs%20Year%20by%20Appendix.png)

There is an overall increasing trend in Appendix II taxa trade for this category. According to the output below for most traded taxon, from 2014 to 2018, trade in "hydrastis candensis" (Goldenseal) drove this trend. Since 2019, trade in "prunus africana" (African cherry) has been the largest for Appendix II in this category.

<details>
<summary>
	
#### See Output for Most Traded Taxon per Year by Appendix
	
</summary>
	
|year|taxon_id|taxon_name                |appendix|round(tot_traded,4)|
|----|--------|--------------------------|--------|-------------------|
|2008|147641  |hoodia gordonii           |II      |1830               |
|2009|139699  |saussurea costus          |I       |941                |
|2009|147641  |hoodia gordonii           |II      |15246              |
|2010|139699  |saussurea costus          |I       |14428              |
|2010|152520  |hirudo medicinalis        |II      |198960             |
|2011|139699  |saussurea costus          |I       |6588               |
|2011|152520  |hirudo medicinalis        |II      |55264              |
|2012|139699  |saussurea costus          |I       |4932               |
|2012|152520  |hirudo medicinalis        |II      |55620              |
|2013|139699  |saussurea costus          |I       |9537               |
|2013|138707  |aloe ferox                |II      |64231.7            |
|2014|139699  |saussurea costus          |I       |6258               |
|2014|145446  |hydrastis canadensis      |II      |466520             |
|2015|139699  |saussurea costus          |I       |1839               |
|2015|145446  |hydrastis canadensis      |II      |621506.57          |
|2016|139699  |saussurea costus          |I       |7338               |
|2016|145446  |hydrastis canadensis      |II      |649965             |
|2017|139699  |saussurea costus          |I       |6437               |
|2017|145446  |hydrastis canadensis      |II      |480640             |
|2018|139699  |saussurea costus          |I       |47502              |
|2018|145446  |hydrastis canadensis      |II      |612674             |
|2019|139699  |saussurea costus          |I       |120000             |
|2019|145071  |prunus africana           |II      |1723000            |
|2020|139699  |saussurea costus          |I       |6982               |
|2020|145071  |prunus africana           |II      |634050             |
	
</details>

#### 5,2,4) Medicine - Ex-Animalia (Plants) - kg
![5,2,4 Figure 1](https://github.com/thclough/endangered_db/blob/main/query_output_and_visualizations/medical/medicine/Ex-Animalia/kg/Medicine%20-%20Plantae%20-%20kg%20-%20Trades%20vs%20Year%20by%20Appendix.png)

<details>
<summary>
	
#### See Output for Most Traded Taxon per Year by Appendix

</summary>
</details>
	
### 5,3) Fashion Scenario

## Citations

<br>

[1] CITES Secretariat and UNEP-WCMC (2022). A guide to using the CITES Trade Database. Version 9. Geneva, Switzerland, and Cambridge, UK. https://trade.cites.org/cites_trade_guidelines/en-CITES_Trade_Database_Guide.pdf
<br>
[2] Tow, J. H., Symes, W. S., & Carrasco, L. R. (2021, October 12). Economic value of illegal wildlife trade entering the USA. PLOS ONE. https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0258523
<br>
[3] Crocodile | Asian Bestiary. (n.d.). http://asianbestiary.org/crocodile/
<br>
[4] Plastus of Turtle
