"""@bruin

name: ingestion.trips
type: python
image: python:3.11
connection: gcp-sa-dez

materialization:
  type: table
  strategy: append

columns:
  - name: vendor_id
    type: integer
    description: Taxi vendor identifier
  - name: pickup_datetime
    type: timestamp
    description: Trip pickup datetime
  - name: dropoff_datetime
    type: timestamp
    description: Trip dropoff datetime
  - name: passenger_count
    type: integer
    description: Number of passengers
  - name: trip_distance
    type: float
    description: Trip distance in miles
  - name: ratecode_id
    type: integer
    description: Rate code for the trip
  - name: store_and_fwd_flag
    type: string
    description: Store and forward flag (Y/N)
  - name: pu_location_id
    type: integer
    description: Pickup location ID (TLC Taxi Zone)
  - name: do_location_id
    type: integer
    description: Dropoff location ID (TLC Taxi Zone)
  - name: payment_type
    type: integer
    description: Payment type code
  - name: fare_amount
    type: float
    description: Metered fare amount
  - name: extra
    type: float
    description: Extra charges (rush hour, overnight surcharges)
  - name: mta_tax
    type: float
    description: MTA tax
  - name: tip_amount
    type: float
    description: Tip amount
  - name: tolls_amount
    type: float
    description: Tolls amount
  - name: improvement_surcharge
    type: float
    description: Improvement surcharge
  - name: total_amount
    type: float
    description: Total amount charged
  - name: congestion_surcharge
    type: float
    description: Congestion surcharge
  - name: taxi_type
    type: string
    description: Type of taxi (yellow or green)
  - name: extracted_at
    type: timestamp
    description: Timestamp when this record was extracted

@bruin"""

import json
import os
from datetime import datetime
from io import BytesIO

import pandas as pd
import requests


def materialize():
    start_date = os.environ["BRUIN_START_DATE"]
    end_date = os.environ["BRUIN_END_DATE"]
    bruin_vars = json.loads(os.environ.get("BRUIN_VARS", "{}"))
    taxi_types = bruin_vars.get("taxi_types", ["yellow", "green"])

    # Generate list of year-month dates within the run window
    start = datetime.strptime(start_date, "%Y-%m-%d").date()
    end = datetime.strptime(end_date, "%Y-%m-%d").date()

    months = []
    current = start.replace(day=1)
    while current <= end:
        months.append(current)
        if current.month == 12:
            current = current.replace(year=current.year + 1, month=1)
        else:
            current = current.replace(month=current.month + 1)

    base_url = "https://d37ci6vzurychx.cloudfront.net/trip-data"
    extracted_at = datetime.utcnow()
    dfs = []

    for taxi_type in taxi_types:
        for month_date in months:
            url = f"{base_url}/{taxi_type}_tripdata_{month_date.strftime('%Y-%m')}.parquet"
            response = requests.get(url, timeout=120)
            if response.status_code != 200:
                print(f"Skipping {url}: HTTP {response.status_code}")
                continue

            df = pd.read_parquet(BytesIO(response.content))

            # Normalize pickup/dropoff column names across yellow and green taxi schemas
            if "tpep_pickup_datetime" in df.columns:
                df = df.rename(columns={
                    "tpep_pickup_datetime": "pickup_datetime",
                    "tpep_dropoff_datetime": "dropoff_datetime",
                })
            elif "lpep_pickup_datetime" in df.columns:
                df = df.rename(columns={
                    "lpep_pickup_datetime": "pickup_datetime",
                    "lpep_dropoff_datetime": "dropoff_datetime",
                })

            # Normalize other column names to snake_case
            df = df.rename(columns={
                "VendorID": "vendor_id",
                "RatecodeID": "ratecode_id",
                "PULocationID": "pu_location_id",
                "DOLocationID": "do_location_id",
            })

            df["taxi_type"] = taxi_type
            df["extracted_at"] = extracted_at
            dfs.append(df)

    if not dfs:
        return pd.DataFrame()

    final_df = pd.concat(dfs, ignore_index=True)

    keep_cols = [
        "vendor_id", "pickup_datetime", "dropoff_datetime", "passenger_count",
        "trip_distance", "ratecode_id", "store_and_fwd_flag", "pu_location_id",
        "do_location_id", "payment_type", "fare_amount", "extra", "mta_tax",
        "tip_amount", "tolls_amount", "improvement_surcharge", "total_amount",
        "congestion_surcharge", "taxi_type", "extracted_at",
    ]
    existing_cols = [c for c in keep_cols if c in final_df.columns]
    return final_df[existing_cols]
