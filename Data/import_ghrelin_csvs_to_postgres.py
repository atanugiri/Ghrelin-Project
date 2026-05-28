from pathlib import Path
import pandas as pd
from sqlalchemy import create_engine

csv_folder = Path("/Users/atanugiri/Downloads/Ghrelin Project/Data")

db_name = "live_database"
user = "atanugiri"
host = "localhost"
port = 5432

engine = create_engine(
    f"postgresql+psycopg2://{user}@{host}:{port}/{db_name}"
)

csv_to_table = {
    "P2L1_ghrelin_featuretable_rows.csv": "ghrelin_featuretable",
    "P2L1_manuscript_live_table_rows.csv": "live_table",
}

for csv_name, table_name in csv_to_table.items():
    csv_path = csv_folder / csv_name

    if not csv_path.exists():
        raise FileNotFoundError(f"Could not find: {csv_path}")

    print(f"\nImporting:")
    print(f"  CSV:   {csv_path}")
    print(f"  Table: {table_name}")

    df = pd.read_csv(csv_path)

    df.to_sql(
        table_name,
        engine,
        if_exists="replace",   # replaces old table if it already exists
        index=False,
        chunksize=10000
    )

    print(f"Done: {len(df)} rows x {len(df.columns)} columns")

print("\nBoth CSV files imported successfully.")