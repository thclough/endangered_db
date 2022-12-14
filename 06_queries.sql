use endangered_animal_trade;

-- Query 1
-- Top 10 countries for importing a particular endangered species
select
	c.country_name,
    s.genus_name,
    s.species_name,
    count(t.trade_id) as num_imports
from trade t
join country c on (c.country_id = t.importer_id)
join species s using (species_id)
group by t.importer_id, t.species_id
order by num_imports desc
limit 10;


-- Query 2
-- Top 10 countries for exporting a particular endangered species
select c.country_name,
	s.genus_name,
	s.species_name,
	count(t.trade_id) 'total_exports'
from trade t join country c on (t.exporter_id = c.country_id)
join species s using (species_id)
group by t.exporter_id, s.species_id
order by total_exports desc
limit 10;


-- Query 3
-- Top 10 most traded species
select
    s.genus_name,
    s.species_name,
    count(t.trade_id) as num_trades
from trade t
join species s using (species_id)
group by s.species_id
order by num_trades desc
limit 10;


-- There are different units for each trade transaction. For better analysis based on number of endangered species
-- exchanged in a transaction, make very rough estimation based on the unit.
-- For measurement units (i.e. kg, g, mg, cm), estimate number as 1 regardless of quantity.
-- For container units (bottles, flasks, boxes, pieces, cartons, sets), number = quantity
drop function if exists estimate_total_number;
delimiter //
create function estimate_total_number
(
	unit varchar(50),
    quantity double
)
returns int
deterministic
begin
	if unit in ('bottles', 'flasks', 'boxes', 'pieces', 'cartons', 'sets') then
		return round(quantity, 0);
	else
		return 1;
	end if;
end //
delimiter ;

-- See a country's GDP per capita for a particular year along with the number of endangered species traded
-- and the number of times trade occurred.
drop procedure if exists economic_trend;
delimiter //
create procedure economic_trend
(
	countryName varchar(50)
)
begin
	select
		c.country_name,
        t.year,
        g.amount as gdp_per_capita,
        sum(estimate_total_number(t.unit, t.quantity)) as est_num_traded_species,
        count(t.trade_id) as num_trades
	from trade t
    join country c on (t.importer_id = c.country_id)
    left join gdp g on (t.importer_id = g.country_id and t.year = g.year)
    where c.country_name = countryName
    group by t.year
    order by t.year asc;
end //
delimiter ;

-- Query 4
call economic_trend('United States');


-- See a species' endangered status per year in relationship to the number of trades involving this species.
-- Possible use case: change species_name to analyze change in endangered_status from 1975 to 2018 based on trades
drop procedure if exists status_analysis;
delimiter //
create procedure status_analysis
(
	SpeciesName varchar(50)
)
begin
select
     t.year,
     count(trade_id) as no_of_trades,
     sum(estimate_total_number(unit, quantity)) as no_of_traded_quantity,
     s.species_name,
     h.endangered_status
from trade t
join species s using (species_id)
left join historical_status h on (h.species_id = t.species_id and h.year = t.year)
where species_name = SpeciesName
group by t.year, species_name, h.endangered_status
order by year;
end //
delimiter ;

-- Query 5
call status_analysis('fascicularis');


-- Query 6
-- Years organized by the most trades
select t.year,
	count(t.trade_id) 'total_trades'	
from trade t
group by t.year
order by total_trades desc;


-- Query 7
-- List of species classified as 'Extinct in the Wild' by year
select distinct
	species_name,
    year,
    endangered_status
from historical_status join species using (species_id)
where endangered_status like '%Extinct in the Wild%'
order by species_name, year;

-- Query 8

-- Given a species, see who was the largest exporter and importer overall, as well as the number traded and quantity/unit.
drop procedure if exists species_trade_data;
delimiter //
create procedure species_trade_data
( 
	SpeciesName varchar(50)
)
begin
select 
	s.species_name, 
    i.country_name as importer, 
    e.country_name as exporter, 
    SUM(t.quantity) as num_traded, 
    t.term, 
	t.unit
from trade t
join species s using (species_id)
join country i on (t.importer_id = i.country_id)
join country e on (t.exporter_id = e.country_id)
where s.species_name = SpeciesName
group by importer, exporter, term
order by num_traded desc
;
end //
delimiter ;

call species_trade_data('mulatta');

-- Query 9
-- given a species name, an importer and exporter, the query gathers information about the number of trades
-- each year as well as the importer and exporter gdp that year.
drop procedure if exists species_trade_gdp;
delimiter //
create procedure species_trade_gdp
( 
	SpeciesName varchar(50),
    Importer varchar(50),
    Exporter varchar(50)
)
begin
select 
	t.year,
	s.species_name, 
    SUM(quantity) as num_trades,
    i.country_name as importer, 
    e.country_name as exporter, 
    ig.amount as importer_gdp, 
    eg.amount as exporter_gdp
from trade t
join species s using (species_id)
join country i on (t.importer_id = i.country_id)
join country e on (t.exporter_id = e.country_id)
join gdp ig on (i.country_id = ig.country_id and t.year = ig.year)
join gdp eg on (e.country_id = eg.country_id and t.year = eg.year)
where s.species_name = SpeciesName and i.country_name = Importer and e.country_name = Exporter and term = 'specimens'
group by t.year
order by t.year;
end //
delimiter ;

call species_trade_gdp('mulatta', 'United States', 'Canada');

-- ------------------
-- Large file queries
-- ------------------

-- Query 10
-- Quantity Imports per capita for various countries
select
	year,
    country_name,
    gdp_per_capita,
	round(sum_quantity/(total_pop/100000), 3) quantity_per_capita, 
    total_pop
from (select
		t.year,
		country_name,
		amount gdp_per_capita,
		total_pop,
		sum(quantity) sum_quantity
	from 
		trade t
		join country c on (t.importer_id = c.country_id)
		join gdp g on (c.country_id = g.country_id and t.year = g.year)
		join population p on (c.country_id = p.country_id and t.year = p.year)
		where appendix = "I"
		group by t.year, country_name, gdp_per_capita, total_pop
		order by t.year, country_name, gdp_per_capita) temp
    order by country_name, year;



