import requests
from google.cloud import storage, bigquery
from dotenv import load_dotenv
import os


load_dotenv()

project_id = os.getenv("GCP_PROJECT")
dataset = os.getenv("BQ_DATASET")
bucket_name = os.getenv("GCS_BUCKET_NAME")


def get_fhv_data(fhv_url):
    repo_path = fhv_url.replace("https://github.com/", "")
    tag = repo_path.split("/releases/tag/")[1]
    repo = repo_path.split("/releases/")[0]

    api_url = f"https://api.github.com/repos/{repo}/releases/tags/{tag}"
    response = requests.get(api_url)
    response.raise_for_status()

    assets = response.json()["assets"]
    return [
        asset["browser_download_url"]
        for asset in assets
        if asset["name"].endswith(".csv.gz")
    ]


def upload_to_gcs(bucket_name, file_urls):
    storage_client = storage.Client()
    bucket = storage_client.bucket(bucket_name)

    for url in file_urls:
        filename = url.split("/")[-1]
        response = requests.get(url, stream=True)
        response.raise_for_status()
        blob = bucket.blob(f"fhv/{filename}")
        blob.upload_from_file(response.raw, content_type="application/gzip")
        print(f"Uploaded {filename}")


def main():
    fhv_url = "https://github.com/DataTalksClub/nyc-tlc-data/releases/tag/fhv"
    fhv_trip_data = get_fhv_data(fhv_url)

    upload_to_gcs(bucket_name, fhv_trip_data)

    client = bigquery.Client()

    job_config = bigquery.LoadJobConfig(
        source_format=bigquery.SourceFormat.CSV,
        skip_leading_rows=1,
        write_disposition=bigquery.WriteDisposition.WRITE_APPEND,
        max_bad_records=10,
        schema=[
            bigquery.SchemaField("dispatch_base_num", "STRING"),
            bigquery.SchemaField("pickup_datetime", "TIMESTAMP"),
            bigquery.SchemaField("dropoff_datetime", "TIMESTAMP"),
            bigquery.SchemaField("PUlocationID", "FLOAT"),
            bigquery.SchemaField("DOlocationID", "FLOAT"),
            bigquery.SchemaField("SR_Flag", "STRING"),
            bigquery.SchemaField("Affiliated_base_number", "STRING"),
        ],
    )

    load_job = client.load_table_from_uri(
        f"gs://{bucket_name}/fhv/*.csv.gz",
        f"{project_id}.{dataset}.fhv_tripdata",
        job_config=job_config,
    )

    load_job.result()


if __name__ == "__main__":
    main()
