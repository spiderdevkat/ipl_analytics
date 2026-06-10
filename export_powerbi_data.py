import duckdb
import os

con = duckdb.connect('ipl_dbt/dev.duckdb')

tables = [
    'mart_batting',
    'mart_bowling',
    'mart_team_performance',
    'mart_venue_stats',
    'mart_match_reports'
]

os.makedirs('power_bi_data', exist_ok=True)

for table in tables:
    output_file = f'power_bi_data/{table}.csv'

    con.execute(f"""
        COPY {table}
        TO '{output_file}'
        (HEADER, DELIMITER ',')
    """)

    print(f"✅ Exported {table}")

con.close()
print("🎉 All files exported!")