"""Read data from Oracle (running in Docker) into pandas.

The heavy lifting (filtering, GROUP BY) is done by Oracle;
pandas only receives the finished result.

    pip install oracledb pandas
    set ORACLE_USER / ORACLE_PASSWORD / ORACLE_DSN (see ../../.env.example)
"""
import os

import oracledb
import pandas as pd

conn = oracledb.connect(
    user=os.environ.get("ORACLE_USER", "bd_lab"),
    password=os.environ["ORACLE_PASSWORD"],
    dsn=os.environ.get("ORACLE_DSN", "localhost:1521/FREEPDB1"),
)

with conn.cursor() as cur:
    cur.execute("SELECT USER, SYS_CONTEXT('USERENV', 'CON_NAME') FROM dual")
    print("Connected as:", cur.fetchone())          # ('BD_LAB', 'FREEPDB1')

students = pd.read_sql("SELECT * FROM studenci", conn)
print(students.shape)

per_field = pd.read_sql(
    "SELECT kierunek, COUNT(*) AS liczba FROM studenci GROUP BY kierunek", conn
)
print(per_field)

per_category = pd.read_sql(
    """SELECT kategoria, COUNT(*) AS liczba, AVG(wartosc) AS srednia
       FROM dane_100k GROUP BY kategoria ORDER BY kategoria""",
    conn,
)
print(per_category)

conn.close()
