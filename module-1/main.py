import click
import pandas as pd
import pyarrow.parquet as pq
from sqlalchemy import create_engine
from tqdm.auto import tqdm
from pathlib import Path


def ingest_data(file, chunksize, connection):
    if file.suffix == ".csv":
        df_iter = pd.read_csv(file, iterator=True, chunksize=chunksize)
        target_table = "zones"

        first = True

        for df_chunk in tqdm(df_iter):
            if first:
                df_chunk.head(0).to_sql(
                    name=target_table, con=connection, if_exists="replace"
                )
                first = False

            df_chunk.to_sql(name=target_table, con=connection, if_exists="append")

    elif file.suffix == ".parquet":
        parquet_file = pq.ParquetFile(file)
        target_table = "green_taxi_data"
        first = True

        for batch in tqdm(parquet_file.iter_batches(batch_size=chunksize)):
            df_batch = batch.to_pandas()
            if first:
                df_batch.head(0).to_sql(
                    name=target_table, con=connection, if_exists="replace"
                )
                first = False

            df_batch.to_sql(name=target_table, con=connection, if_exists="append")


@click.command()
@click.option("--pg-user", default="postgres", help="PostgreSQL user")
@click.option("--pg-pass", default="postgres", help="PostgreSQL password")
@click.option("--pg-host", default="postgres", help="PostgreSQL host")
@click.option("--pg-port", default=5432, type=int, help="PostgreSQL port")
@click.option("--pg-db", default="ny_taxi", help="PostgreSQL database name")
@click.option(
    "--chunksize",
    default=100000,
    type=int,
    help="Chunk size for each file to be ingested",
)
def main(pg_user, pg_pass, pg_host, pg_port, pg_db, chunksize):
    engine = create_engine(
        f"postgresql+psycopg://{pg_user}:{pg_pass}@{pg_host}:{pg_port}/{pg_db}"
    )

    files_dir = Path("/code/files")
    files = list(files_dir.iterdir())
    for file in files:
        ingest_data(file, chunksize, engine)


if __name__ == "__main__":
    main()
