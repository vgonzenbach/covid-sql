import pandas as pd
import os
from glob import glob
import sqlalchemy
import logging

logging.basicConfig()
logging.getLogger('sqlalchemy.engine').setLevel(logging.INFO)

for csv in os.listdir('data'):
    df = pd.read_csv(f'data/{csv}')
    df.columns = [c.lower() for c in df.columns] # PostgreSQL doesn't like capitals or spaces

    engine = sqlalchemy.create_engine('postgresql://postgres:password@localhost:5432/covid')

    table_name = csv.replace('.csv', '')
    df.to_sql(table_name, 
              engine,
              if_exists = 'replace',
              index=False,
              dtype={'date': sqlalchemy.types.Date})