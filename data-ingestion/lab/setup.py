from setuptools import setup, find_packages
setup(
    name="data_ingestion",
    version="0.1",
    # packages=find_packages()
    # packages=["data_ingestion"]
    py_modules = ['ingestion','parameters']
)