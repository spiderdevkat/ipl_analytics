import duckdb

# Connect to DuckDB database
con = duckdb.connect("dev.duckdb")

print("=== NULL ECONOMY ROWS ===")

query = """
    SELECT
        bowler,
        balls_bowled,
        legal_balls,
        runs_conceded,
        economy_rate
    FROM int_bowling_stats
    WHERE economy_rate IS NULL
"""

rows = con.execute(query).fetchall()

if not rows:
    print("No rows found with NULL economy_rate.")
else:
    print(
        f"{'Bowler':<25} "
        f"{'Balls':>8} "
        f"{'Legal':>8} "
        f"{'Runs':>8} "
        f"{'Economy':>10}"
    )
    print("-" * 65)

    for bowler, balls, legal, runs, economy in rows:
        print(
            f"{str(bowler):<25} "
            f"{balls:>8} "
            f"{legal:>8} "
            f"{runs:>8} "
            f"{str(economy):>10}"
        )

con.close()