# Endangered Animal Database Construction and Analysis
#### By: Tighe Clough

## Background

This analysis stems from a group project in "CS3200: Database Design" at Northeastern University in Boston, Massachusetts. The group consisted of myself, Yuxuan Chen, Britney Chen, Sarah Tong, and Amaya Kejriwal. My original vision for the project proved too ambitious due to time and technology constraints. I have revisited the project to achieve these goals and have redesigned and updated the database. Additionally, I am performing continuous analysis on the database which I document through updates on this repo.

## Introduction

The international demand for animal and plant-derived products has caused alarming depletions in certain specie populations. While the world economies have become increasingly connected and prosperous in the past few centuries, the resulting market forces have overwheled wildlife in many cases. In 1975, 80 countries came together to address this issue by drafting and signing The Convention on International Trade in Endangered Species of Wild Flora and Fauna (CITES). The agreement stipulated the careful documentation and tracking of trade in threatened and endangered taxa (biological term for a group of related organisms). Currently the UN Environment Programme World Conservation Monitoring Center, on behalf of CITES, maintains the CITES database which contains 23 million records of such trade<sup>1</sup>. 

It is worth noting that the database does not contain *illegal* wildlife trade. However, the global *legal* trade of wildlife reached an estimated 119 billion USD or more in 2020, while its illegal counterpart only stood at an estimated 5 to 23 billion USD<sup>2</sup>. Therefore, the study of legal trade can give insights into overall wildlife trade patterns.

In this project, I have set out to create a database that integrates CITES data, RED list endangerment statuses, and importing/exporting/origin country statistics. Following the contruction of the database, I have theorized a few use cases to demonstrate the importance of studying this connected data.

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
* <a href="https://apiv3.iucnredlist.org/"> RED List API </a> 
  * info on taxa and IUCN Red List conservation status for select years
* <a href="https://data.worldbank.org/indicator/NY.GDP.MKTP.CD"> World Bank GDP Data </a>
  * Country GDP (Current USD) data per year
* <a href="https://data.worldbank.org/indicator/SP.POP.TOTL"> World Bank Population Data </a>
  * Country population data per year
</details>

## Methods

## Analysis/Results


<details>
<summary>

## Citations

</summary>

<br>

[1] CITES Secretariat and UNEP-WCMC (2022). A guide to using the CITES Trade Database. Version 9. Geneva, Switzerland, and Cambridge, UK. https://trade.cites.org/cites_trade_guidelines/en-CITES_Trade_Database_Guide.pdf
<br>
[2] Tow, J. H., Symes, W. S., & Carrasco, L. R. (2021, October 12). Economic value of illegal wildlife trade entering the USA. PLOS ONE. https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0258523
</details>
