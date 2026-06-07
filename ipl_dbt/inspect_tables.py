import duckdb

con = duckdb.connect("dev.duckdb")

print("=== INNING VALUES ===")

rows = con.execute("""
    SELECT
        inning,
        COUNT(*) AS cnt
    FROM deliveries
    GROUP BY inning
    ORDER BY inning
""").fetchall()

for inning, count in rows:
    print(f"Inning {inning}: {count:,} rows")

con.close()