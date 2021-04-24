import os

from pyspark.sql import SparkSession

from data_ingestion.config import job_parameters, download_twdu_dataset
from data_ingestion.ingestion import Ingestion

# By sticking with standard Spark, we can avoid having to deal with Glue dependencies locally
# If developing outside of the TWDU Dev Container, don't forget to set the environment variable: TWDU_ENVIRONMENT=local
ENVIRONMENT = os.getenv(key="TWDU_ENVIRONMENT", default="aws")

# If running locally, first download the necessary datasets to local storage
if ENVIRONMENT == "local":
    download_twdu_dataset(
        s3_uri="s3://twdu-germany-pl-km/data-ingestion/EmissionsByCountry.parquet/", 
        destination=job_parameters["co2_input_path"],
        format="parquet")
    download_twdu_dataset(
        s3_uri="s3://twdu-germany-data-source/data-ingestion/GlobalTemperatures.csv", 
        destination=job_parameters["temperatures_global_input_path"],
        format="parquet")
    download_twdu_dataset(
        s3_uri="s3://twdu-germany-data-source/TemperaturesByCountry.csv", 
        destination=job_parameters["temperatures_country_input_path"],
        format="parquet")

# ---------- Part III: Run Da Ting (for Part II, see data_ingestion/ingestion.py) ---------- #

spark = SparkSession \
    .builder \
    .appName("TWDU Germany Glue Data Ingestion") \
    .config("spark.some.config.option", "some-value") \
    .getOrCreate()

Ingestion(spark, job_parameters).run()