use endangered_animal_trade;

-- working with dirty data, so many different units, terms, unlabeled data probably different classification procedures

-- find top 10 most traded animal for each (five) year period going back to 1975
-- NOTE: you can just focus on units now for this one
-- broken down by units (kg, 

drop view if exists kg_per_year;
create view world_kg_per_year as select year, taxon_name, sum(quantity) as total_kg_traded
from trade join taxon using (taxon_id)
where unit = "kg"
group by year, taxon_id;

select * 
from world_kg_per_year where (year, total_kg_traded) in
	(select year, max(total_kg_traded)
	from world_kg_per_year
	group by year);

select count(*)
from trade
where term = ''; -- 0

select count(*)
from trade
where unit = ''; -- 2562294

select distinct(term)
from trade
order by term;


-- what if there are smaller more valuable species, not all animals are the same size
-- where kg < 1

-- what about the amount of traded appendix i species broken down by unit and by year
-- separate query for each year

-- what about growth year over year appendix i different unit, use window function
-- 

-- what species drive this growth?

-- what countries drive this growth?

-- what about broken down into 5 year periods
-- compare to red list data

-- what species is becoming popular over the last few years???


########## MEDICINE ##########
-- Like the red list ads, which species do you focus one
-- what if was looking at medicine term? 
-- country or company that has become more concerned wiht sustainability

-- data shows that there are only 2977 entries for medicine
select count(*)
from trade
where term = "medicine";

-- DEAD END START

-- let's include trades where the purpose is "M" (medical)
-- (even though some trades under M might be for biomedical research)
-- up to 18291 entrie
select count(*)
from trade 
where term = "medicine" or purpose = "M";

-- create view for cleaner querying 
create view med_trades as
	select *
	from trade 
	where term = "medicine" or purpose = "M";

-- we'll base our anlaysis over time on changes in units for certain taxons
-- let's take a look at the most popular terms
select unit, count(unit) as tot_entries
from med_trades
group by unit
order by tot_entries desc;

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
    
-- DEAD END END 

-- hitting a problem because we used "M" purpose species, crab-eating macaque (Macaca fascicularis)
-- this is used in medical experiments due to their close physiology with humans
-- but still could be used to look at ethical concerns of experimenting on animals

-- so what if we just wanted to look at the trades where the species is used for medicine for human consumption
-- There aren't many entries labeled under the term "medicine" (which seems to be more appropriate for our analysis)
-- which is why I included "M" purpose trades in the first place for more data. 
-- Problem: just "medicine" term entries are too specific while "M" purpose are too broad:
	-- if used any species that were traded in medicine could have overlaps in different motives not attributed to medicine, e.g. the fashion industry
-- Solution: Don't rely on term medicine solely, but terms that are related to medicine


# any taxon traded under medicine
select unit, count(*)
from trade
where term = "Medicine"
group by unit;

-- also only if purpose is in B (Breeding/propagation), M (Medical), P (Personal), T (commercial), and blank
-- don't want to include purposes like S (Scientific), H (Hunting Trophy), L (law enforcement/foresic) because those have nothing to do with medicine
drop view if exists medicine_species_trades;
create view medicine_species_trades as 
	select * from trade join taxon using (taxon_id)
	where term = "medicine" and purpose in ("B", "M", "P", "T", "");

-- analysis broken down into animalia and then all other
-- only start off with animalia

## medicine animalia

-- create view for any medicine animalia trades 
drop view if exists medicine_animalia_trades;
create view medicine_animalia_trades as
	select *
	from medicine_species_trades
	where kingdom_name = "animalia";

### medicine animalia: No unit ('') and "Number of specimens"
drop view if exists specimen_medicine_animalia_trades;
create view specimen_medicine_animalia_trades as
	select *
    from medicine_animalia_trades
    where unit in ('', 'Number of specimens');

-- overview (group by year) create a pivot
select
	year,
    sum(case when appendix = "I" then quantity else 0 end) as I,
    sum(case when appendix = "II" then quantity else 0 end) as II,
    sum(case when appendix = "III" then quantity else 0 end) as III,
    sum(quantity) as total
from specimen_medicine_animalia_trades
group by year;

-- find growth rates in by appendix by year



-- sum each taxon by year (Regardless of importer, exporter, or origin)
drop view if exists world_specimen_medicine_animalia_trades;
create view world_specimen_medicine_animalia_trades as
	select year, taxon_id, taxon_name, appendix, sum(quantity) as tot_traded
	from specimen_medicine_animalia_trades
	group by year, taxon_id, taxon_name, appendix;

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

### medicine animalia: kg
drop view if exists kg_medicine_animalia_trades;
create view kg_medicine_animalia_trades as
	select *
    from medicine_animalia_trades
    where unit = 'kg';

-- overview (group by year) create a pivot
select
	year,
    round(sum(case when appendix = "I" then quantity else 0 end),4) as I,
    round(sum(case when appendix = "II" then quantity else 0 end),4) as II,
    round(sum(case when appendix = "III" then quantity else 0 end),4) as III,
    round(sum(quantity),4) as total
from kg_medicine_animalia_trades
group by year;

-- sum each taxon by year (Regardless of importer, exporter, or origin)
drop view if exists world_kg_medicine_animalia_trades;
create view world_kg_medicine_animalia_trades as
	select year, taxon_id, taxon_name, appendix, sum(quantity) as tot_traded
	from kg_medicine_animalia_trades
	group by year, taxon_id, taxon_name, appendix;


-- max taxon each year
with
	-- temp table containing year and taxon_id with maximum amount of trades
	max_world_kg_medicine_animalia_trades as
		(select *
		from world_kg_medicine_animalia_trades
		where (year, appendix, tot_traded) in
			-- maximum quantity for each taxon by year
			(select year, appendix, max(tot_traded)
			from world_kg_medicine_animalia_trades
			group by year, appendix))
	select year, taxon_id, taxon_name, appendix, round(tot_traded, 3) as total_traded -- save join for very last to be the most efficient and cleaner code
    from max_world_kg_medicine_animalia_trades;

-- Query into "mauremys reevesii" The Chinese Pond Turtle
select * from kg_medicine_animalia_trades;

-- Find the top importers
-- absolute
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

-- per capita
with turtle_importer_sums_per_year as -- first sum imports by year for each importer
	(select
		year,
		importer_id,
		sum(quantity) as total_traded
	from kg_medicine_animalia_trades
    where taxon_name = "mauremys reevesii"
	group by year, importer_id),
turtle_kg_per_1k as
	(select
	year,
    country_name,
    total_traded/total_pop * 100000 as kg_per_1k
	from turtle_importer_sums_per_year t
	join country c on t.importer_id = c.country_id
    join population p using (year, country_id))
select *
from turtle_kg_per_1k
where (year,kg_per_1k) in
	(select 
		year,
		max(kg_per_1k)
    from turtle_kg_per_1k
    group by year);
    
-- look at IUCN data
select 
	year,
    taxon_name,
    endangered_status
from taxon join historical_status using(taxon_id)
where taxon_name = "mauremys reevesii";
    
## Medicine Ex-Animalia (Probably plantae) (plants come in much squaller quanitities and need to be separated)
drop view if exists medicine_ex_animalia_trades;
create view medicine_ex_animalia_trades as
	select *
	from medicine_species_trades
	where kingdom_name != "animalia";

### Medicine Ex-Animalia: No unit ('') and "Number of specimens"
drop view if exists specimen_medicine_ex_animalia_trades;
create view specimen_medicine_ex_animalia_trades as
	select *
    from medicine_ex_animalia_trades
    where unit in ('', 'Number of specimens');

-- overview (group by year) create a pivot
select
	year,
    sum(case when appendix = "I" then quantity else 0 end) as I,
    round(sum(case when appendix = "II" then quantity else 0 end),4) as II,
    sum(case when appendix = "III" then quantity else 0 end) as III,
    round(sum(quantity),4) as total
from specimen_medicine_ex_animalia_trades
group by year;

-- group by taxon and year to get total traded in the world over a year
drop view if exists world_specimen_medicine_ex_animalia_trades;
create view world_specimen_medicine_ex_animalia_trades as
	select year, taxon_id, taxon_name, appendix, sum(quantity) as tot_traded
	from specimen_medicine_ex_animalia_trades
	group by year, taxon_id, taxon_name, appendix;
-- SHOULD REALLY LOOK AT GROWTH RATES FOR THIS ONE AS 


-- max taxon each year
with
	-- temp table containing year and taxon_id with maximum amount of trades
	max_world_specimen_medicine_ex_animalia_trades as
		(select * 
		from world_specimen_medicine_ex_animalia_trades
		where (year, appendix, tot_traded) in
			-- maximum quantity for each taxon by year
			(select year, appendix, max(tot_traded)
			from world_specimen_medicine_ex_animalia_trades
			group by year, appendix))
	select year, taxon_id, taxon_name, appendix, round(tot_traded,4) as tot_traded -- save join for very last to be the most efficient and cleaner code
    from max_world_specimen_medicine_ex_animalia_trades;

-- look at growth rate for most common species in this

### Medicine Ex-Animalia: kg 
drop view if exists kg_medicine_ex_animalia_trades;
create view kg_medicine_ex_animalia_trades as
	select *
    from medicine_ex_animalia_trades
    where unit = "kg";

-- overview (group by year) create a pivot
select
	year,
    round(sum(case when appendix = "I" then quantity else 0 end),4) as I,
    round(sum(case when appendix = "II" then quantity else 0 end),4) as II,
    round(sum(case when appendix = "III" then quantity else 0 end),4) as III,
    round(sum(quantity),4) as total
from kg_medicine_ex_animalia_trades
group by year;

-- group by taxon and year to get total traded in the world over a year
drop view if exists world_kg_medicine_ex_animalia_trades;
create view world_kg_medicine_ex_animalia_trades as
	select year, taxon_id, taxon_name, appendix, sum(quantity) as tot_traded
	from kg_medicine_ex_animalia_trades
	group by year, taxon_id, taxon_name, appendix;

-- max taxon each year
with
	-- temp table containing year and taxon_id with maximum amount of trades
	max_world_kg_medicine_ex_animalia_trades as
		(select * 
		from world_kg_medicine_ex_animalia_trades
		where (year, appendix, tot_traded) in
			-- maximum quantity for each taxon by year
			(select year, appendix, max(tot_traded)
			from world_kg_medicine_ex_animalia_trades
			group by year, appendix))
	select year, taxon_id, taxon_name, appendix, round(tot_traded,4) as tot_traded -- save join for very last to be the most efficient and cleaner code
    from max_world_kg_medicine_ex_animalia_trades;

-- didn't start using that term until 2009, so is there a way to use more data to study medicinal purposes
-- use some background knowledge
# Medicine by term

### medicine animalia - live, specimens, bodies, medicine, unspecified
-- largest group of terms

### medicine animalia - raw corals??

### medicine animalia - bones, skulls, tusks, skeletons, horn products, bone products, horn pieces, horn scraps, ivory scraps
-- like ivory, like horn

### medicine animalia - derivatives, extract, oil, powder


### medicine animalia - like gall


## medicine ex-animalia (plantae or plants)
drop view if exists medicine_ex_animalia_trades;
create view medicine_ex_animalia_trades as
	select *
	from medicine_species_trades
	where kingdom_name = "animalia";




-- but this is for all animals, what about just for appendix i or ii?




########## FASHION & LUXURY ##########
-- perfumes: look at the term musk

-- what if you just focused on animals taken from the wild

###### Stored Pocedures ######



/*
TAKEAWAYS
Purpose and term is unreliable for deeper anlaysis, instead have to use intuition with terms and break into categories from prior knowledge
*/
