from sqlalchemy import create_engine
import pandas as pd

engine = create_engine('mysql+mysqlconnector://root:food99@127.0.0.1:3306/tinder_profiles_analysis')
query = "SELECT * FROM users"
df = pd.read_sql_query(query, engine)
df.to_csv('phase_1_raw.csv', index=False)
engine.dispose()