# Database Design Overview

This document explains the structure and design decisions behind the Yu-Gi-Oh Card Collection database.

The goal of this database is to accurately model:

- The global Yu-Gi-Oh card catalogue
- All card printings across sets and rarities
- A personal inventory of owned cards

The design separates **card identity**, **printing identity**, and **ownership data** to avoid duplication and maintain data integrity.

---

# Design Philosophy

A key principle in this database is **normalization**.

Instead of storing card information repeatedly in every inventory row, the system separates the data into logical entities.

Example problem if not normalized:

### Inventory

Blue-Eyes White Dragon
  
Blue-Eyes White Dragon
  
Blue-Eyes White Dragon


Every row would repeat the same card information.

Instead, the schema uses references:

card_catalogue

↓

printings

↓

inventory


This allows the database to store card information only once while supporting many printings and inventory entries.

---

# Core Tables

## card_catalogue

Stores a single entry for every unique Yu-Gi-Oh card.

Primary Key: id (Konami card ID)


Example row:

| id | name | type |
|----|------|------|
| 89631139 | Blue-Eyes White Dragon | Monster |

Important fields include:

- card name
- card type
- attribute
- attack/defense
- level
- archetype

This table represents **the card itself**, independent of any set.

---

## sets

Stores every Yu-Gi-Oh set.

Example:

| set_code | set_name |
|---------|----------|
| DABL | Darkwing Blast |

Primary Key: set_code


---

## printings

This table represents a **specific printed version of a card**.

Example:

| printing_code | rarity | card_name |
|---------------|--------|-----------|
| DABL-EN043 | Ultra Rare | Kashtira Fenrir |

Important columns:

| Column | Purpose |
|------|------|
| printing_code | Card code printed on the card |
| set_code | Which set the card belongs to |
| card_id | Reference to `card_catalogue` | 
| rarity | Card rarity |
| variant_name | Used for artwork variants |

This table resolves the relationship: One card → Many printings

Example:

`Blue-Eyes White Dragon`

may appear as:

`LOB-001 (Ultra Rare)`

`SDK-001 (Ultra Rare)`

`LDK2-ENK01 (Common, Artwork Variants)`


Each of those rows exists separately in `printings`.

Currently some card_ids are NULL due to data quality issues in original csvs, as well as adding tokens to printings. This will be worked on to ensure the most accurate database possible

---

## inventory

This table stores the user's personal collection.

Each row represents **owned copies of a specific printing**.

Important fields:

| Column | Description |
|------|------|
| printing_id | Which printing the card belongs to |
| card_grade | Card condition |
| edition | 1st edition / unlimited / etc. |
| location | Binder or storage location | 
| quantity | Number owned |
| price_each | Individual value |
| binder_value | Total value of owned cards | 

location is optional, if it is not given, it will default to NULL. Web UI will allow to update this at a later date
binder_value is computed automatically, with no input needed from the user
---

# Inventory Identity

Inventory rows are uniquely identified by: 

`printing_id`

`card_grade`

`edition`

`rarity`


If a card with identical attributes is added again, the system **increments the quantity instead of creating a duplicate row**.

Example:
