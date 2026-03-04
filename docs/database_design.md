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
Example:

`+1 JUSH-EN040 1st Edition, Starlight Rare`

`+1 JUSH-EN040 1st Edition, Starlight Rare`

becomes:

quantity = 2

`+1 JUSH-EN040 1st Edition, Starlight Rare`

`+1 JUSH-EN040 1st Edition, Super Rare`

becomes:

seperate entries


This logic is implemented using a PostgreSQL **UPSERT function**.

---

# Data Sources

Card catalogue data was imported from: YGOProDeck card database


This provides:

- official Konami card IDs
- card stats
- card descriptions
- archetype information

The printings dataset was built from exported card lists and corrected manually for data quality issues such as:

- incorrect rarities
- missing token cards
- artwork variants

---

# Special Cases

## Artwork Variants

Some cards share the same card code but have different artwork.

Example:
`LDK2-ENK01 Blue-Eyes White Dragon`


This set includes multiple artworks.

These are stored using: variant_name


Example:

| printing_code | variant_name |
|---------------|--------------|
| LDK2-ENK01 | Art 1 |
| LDK2-ENK01 | Art 2 |
| LDK2-ENK01 | Art 4 |

---

## Short Print Cards

Some cards are listed as: `Short Print` and `Super Short print`


These are treated as separate rarities in the database to preserve the original printing information. They are akin to the common rarity

---

# Future Improvements

Planned extensions for the database include:

### Web Interface
Allow users to:

- search cards
- add cards to inventory
- track collection completion

### Pricing Integration

Automatic price updates from:

- TCGPlayer
- other card market APIs

### Deck Builder

Allow deck creation and validation based on owned cards.

---

# Summary

This schema was designed to:

- eliminate redundant data
- support hundreds of sets and thousands printings
- accurately model card rarity and variants
- allow scalable inventory tracking

The system forms the foundation for a future web-based Yu-Gi-Oh collection manager.

