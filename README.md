# Data Engineering Zoomcamp — Homework

Solutions to the [DataTalks.Club Data Engineering Zoomcamp](https://github.com/DataTalksClub/data-engineering-zoomcamp) exercises, covering ingestion, warehousing, transformation, orchestration, batch processing, and stream processing.

---

## Modules

### [module-1](module-1/)
**Containerization & Infrastructure**
Docker and Terraform fundamentals. Sets up a PostgreSQL instance via Docker Compose, ingests NYC taxi data, and provisions cloud infrastructure with Terraform.

### [module-2](module-2/)
**Workflow Orchestration with Kestra**
ETL pipelines built with Kestra for orchestrating yellow and green taxi data ingestion workflows.

### [module-3](module-3/)
**Data Warehousing with BigQuery**
BigQuery exercises covering partitioning, clustering, and query optimization on NYC taxi data. Infrastructure provisioned with Terraform.

### [module-4](module-4/)
**Data Transformation with dbt**
dbt project with staging, intermediate, and mart models transforming raw taxi data. Includes lineage, tests, and documentation.

### [module-5](module-5/)
**Data Pipelines with Bruin**
End-to-end data pipeline built with Bruin, covering ingestion through to reporting on NYC taxi data.

### [module-6](module-6/)
**Batch Processing with Apache Spark**
PySpark exercises using a UV-managed Python environment. Covers schema definition, DataFrame operations, SQL queries, partitioning, and writing parquet files.

### [module-7](module-7/)
**Stream Processing with Redpanda & PyFlink**
Streaming pipeline using Redpanda (Kafka-compatible) as the message broker and PyFlink for stream processing. Includes Kafka producers and consumers in Python, tumbling and session window aggregations, and results written to PostgreSQL via the JDBC connector. Flink cluster runs locally via Docker Compose.
