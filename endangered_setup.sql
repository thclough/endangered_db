drop database if exists endangered_animal_trade;
create database if not exists endangered_animal_trade;

use endangered_animal_trade;
-- NOTE: Change the file paths to match where you're storing the git repo on your machine

-- TAXON
drop table if exists taxon;
create table taxon (
	taxon_id int primary key auto_increment,
    kingdom_name varchar(255) null,
    phylum_name varchar(255) null,
    order_name varchar(255) null,
    class_name  varchar(255) null,
    family_name varchar(255) null,
    genus_name varchar(255) not null,
    species_name varchar(255) not null,
    taxon_name varchar(255) not null
);

set global local_infile = 'ON';
truncate taxon;
load data local infile "<YOUR PATH HERE>/endangered_db/table_csv's/taxon.csv"
into table taxon
fields terminated by  ','
ignore 1 lines;


-- HISTORICAL STATUS
drop table if exists historical_status;
create table historical_status (
	taxon_id int not null,
    year int not null,
    endangered_status VARCHAR(255) NOT NULL,
    CONSTRAINT fk_historical_status FOREIGN KEY (taxon_id) REFERENCES taxon (taxon_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
);

SET GLOBAL local_infile = 'ON';

LOAD DATA LOCAL INFILE "<YOUR PATH HERE>/endangered_db/table_csv's/historical_status.csv"
INTO TABLE historical_status
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
IGNORE 1 LINES;


-- COUNTRY
drop table if exists country;

create table country (
	country_id int not null primary key auto_increment,
    country_name varchar(255) not null,
    iso2_code char(2),
    continent_code char(2)
);

SET GLOBAL local_infile = 'ON';

truncate country;
LOAD DATA LOCAL INFILE "<YOUR PATH HERE>/endangered_db/table_csv's/countries.csv"
INTO TABLE country
FIELDS TERMINATED BY ',' enclosed by '"' lines terminated by  '\r\n' 
IGNORE 1 LINES
(@dummy, country_name, @dummy, iso2_code, continent_code);

-- GDP
DROP TABLE IF EXISTS gdp;

CREATE TABLE gdp (
	country_id INT NOT NULL,
    year INT NOT NULL,
    amount FLOAT NOT NULL,
    UNIQUE KEY(country_id, year),
    FOREIGN KEY (country_id) REFERENCES country(country_id)
);

SET GLOBAL local_infile = 'ON';

-- Change the file path to match where you're storing the git repo on your machine
truncate gdp;
LOAD DATA LOCAL INFILE "<YOUR PATH HERE>/endangered_db/table_csv's/gdp_normalized.csv"
INTO TABLE gdp
FIELDS TERMINATED BY ',' ENCLOSED BY '"';

-- Population
DROP TABLE IF EXISTS population;

CREATE TABLE population (
	country_id INT NOT NULL,
    year INT NOT NULL,
    total_pop BIGINT NOT NULL,
    UNIQUE KEY(country_id, year),
    FOREIGN KEY (country_id) REFERENCES country(country_id)
);

SET GLOBAL local_infile = 'ON';

-- Change the file path to match where you're storing the git repo on your machine
truncate population;
load data local infile "<YOUR PATH HERE>/endangered_db/table_csv's/pop_normalized.csv"
into table population
fields terminated by ',' enclosed by '"';

-- TRADE

-- appendix num represents how endangered the species is ('I' is most endangered, 'N" is non-CITES-listed but stricted domestric measure)
-- purpose of the trade
-- how the animal/plant is obtained/sourced

drop table if exists trade;

create table trade (
    trade_id int primary key auto_increment,
    year int not null,
    appendix enum('I','II','III', 'N') null, -- type enum defined above,
    term varchar(50) null,
    unit varchar(50) null,
    purpose enum('B', 'E', 'G', 'H', 'L', 'M', 'N', 'P', 'Q', 'S', 'T', 'Z', '') null, -- type enum defined above
    source enum('A', 'C', 'D', 'F', 'I', 'O', 'R', 'U', 'W', 'X', 'Y', '') null, -- type enum defined above
    quantity double null,
    taxon_id int not null,
    importer_id int null,
    exporter_id int null,
    origin_id int null,
    constraint trade_fk_exporter_country foreign key (exporter_id) references country (country_id),
    constraint trade_fk_importer_country foreign key (importer_id) references country (country_id),
    constraint trade_fk_origin_country foreign key (origin_id) references country (country_id),
	constraint trade_fk_species foreign key (taxon_id) references taxon (taxon_id)
    );

truncate trade;
load data local infile "<YOUR PATH HERE>/endangered_db/table_csv's/cites_trade.csv"
into table trade
fields terminated by  ','
ignore 1 lines;