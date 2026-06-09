import duckdb

# Connect to DuckDB database
con = duckdb.connect("dev.duckdb")

print("=== TOP VENUES BY MATCHES ===")

query = """
    SELECT
        venue,
        city,
        total_matches,
        avg_first_innings_score,
        chase_success_pct,
        avg_sixes_per_match,
        toss_win_match_win_pct
    FROM mart_venue_stats
    ORDER BY total_matches DESC
    LIMIT 10
"""

rows = con.execute(query).fetchall()

print(
    f"{'Venue':<40} "
    f"{'City':<20} "
    f"{'Matches':>8} "
    f"{'Avg 1st Inns':>14} "
    f"{'Chase %':>10} "
    f"{'6s/Match':>10} "
    f"{'Toss Conv %':>12}"
)

print("-" * 130)

for (
    venue,
    city,
    total_matches,
    avg_first_innings_score,
    chase_success_pct,
    avg_sixes_per_match,
    toss_win_match_win_pct,
) in rows:
    print(
        f"{str(venue):<40} "
        f"{str(city):<20} "
        f"{total_matches:>8} "
        f"{avg_first_innings_score:>14.1f} "
        f"{chase_success_pct:>10.1f} "
        f"{avg_sixes_per_match:>10.1f} "
        f"{toss_win_match_win_pct:>12.1f}"
    )

con.close()