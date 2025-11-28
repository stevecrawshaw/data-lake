# Local Gov Environmental Analytics: Local Lakehouse

A standalone analytical stack for UK Local Government environmental data. This project utilizes a **"Local Lakehouse"** architecture powered by **DuckDB** and **dbt** to unify geospatial boundaries, API streams, and manual datasets (Humaniverse/ONS) into a single analytical interface.

## 🏗 Architecture

This project follows the **Medallion Architecture** (Bronze $\rightarrow$ Silver $\rightarrow$ Gold) adapted for a local filesystem context.

* **Landing Zone (Filesystem):** Raw storage for CSVs, Zips, and Parquet files.
* **Bronze Layer (Raw Views):** DuckDB views reading directly from the Landing Zone or connecting via Federation to PostGIS.
* **Silver Layer (Standardized):** Data cleaning, deduplication, and **Spatial Reprojection** (Standardizing to EPSG:27700).
* **Gold Layer (Analytical):** Aggregated metrics ready for BI or GIS reporting (e.g., "Flood Risk by Ward").

## 📂 Project Structure

```text
.
├── data_lake/                   # LOCAL ONLY (Added to .gitignore)
│   ├── landing/
│   │   ├── automated/           # Output from Python scripts (APIs)
│   │   └── manual/              # Drop zone for Humaniverse/ONS files
│   └── analytics.duckdb         # Main database file
├── src/
│   ├── extractors/              # Python scripts for APIs & Scrapers
│   └── utility/                 # Helper scripts (unzipping, logging)
├── dbt_project/                 # SQL Transformations
│   ├── models/
│   ├── seeds/
│   └── profiles.yml
├── notebooks/                   # Jupyter notebooks for EDA
├── requirements.txt
└── README.md
```

## Data Ingestion Strategy

We utilize three distinct strategies depending on the data source:

1. Federated PostGIS (Corporate Data)
Source: Corporate PostGIS (Boundaries, Assets).

Strategy: Zero-copy. We attach the PostGIS instance directly to DuckDB using the postgres_scanner extension.

Usage: Managed via dbt sources.

2. Automated Pipelines (APIs & Bulk Zips)
Source: EPC Open Data, REST APIs with pagination.

Strategy: Python scripts run daily/weekly.

APIs fetch pages and write to Parquet (incremental append).

Zips are downloaded, extracted, and converted to Parquet in the data_lake/landing/automated folder.

Command: python src/extractors/run_daily_ingest.py

3. Manual "Drop Zone" (Humaniverse/ONS)
Source: Infrequently updated datasets protected by robot-checks (e.g., British Red Cross, Humaniverse).

### Strategy: Manual Download + Globbing

Protocol:

Download the file manually.

Rename with date suffix: flood_data_2025_01.csv.

Drop into data_lake/landing/manual/humaniverse/.

Run dbt. The SQL models are configured to scan *.csv and automatically select the file with the latest date stamp.

## 🌍 Geospatial Standards

Critical: This project mixes Web data (Lat/Lon) with UK Gov data (Easting/Northing).

Input: Various (EPSG:4326, EPSG:27700).

Standardization: All tables in the Silver Layer are forced to British National Grid (EPSG:27700) to ensure accurate area and distance calculations.

Engine: Uses DuckDB spatial extension.
