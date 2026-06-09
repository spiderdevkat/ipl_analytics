from google import genai
from google.genai import types
from dotenv import load_dotenv
import os
import duckdb
import time
import warnings
warnings.filterwarnings("ignore")

load_dotenv()

# ── Config ────────────────────────────────────────────────
DB_PATH = "ipl_dbt/dev.duckdb"
API_KEY = os.getenv("GEMINI_API_KEY")

client = genai.Client(api_key=API_KEY)
MODEL  = "gemini-3.1-flash-lite"

# ── Generate report for one match ─────────────────────────
def generate_match_report(match: dict) -> str:
    prompt = f"""You are an IPL cricket commentator. Write a 2-sentence match summary.

Match details:
- Season: {match['season']}
- Venue: {match['venue']}, {match['city']}
- {match['first_innings_team']} scored {match['first_innings_runs']} runs
- {match['second_innings_team']} scored {match['second_innings_runs']} runs  
- Winner: {match['winner']}
- Result: {match['result']} by {match['result_margin']}
- Player of the match: {match['player_of_match']}
- Outcome type: {match['match_outcome_type']}

Write exactly 2 sentences. Be specific with numbers. Sound like a commentator.
No preamble, just the summary."""

    response = client.models.generate_content(model=MODEL, contents=prompt)
    return response.text.strip()


# ── Main ──────────────────────────────────────────────────
def main():
    con = duckdb.connect(DB_PATH)

    print("📊 Fetching matches...")
    matches = con.execute("""
        SELECT 
            match_id, season, venue, city,
            first_innings_team, first_innings_runs,
            second_innings_team, second_innings_runs,
            winner, result, result_margin,
            player_of_match, match_outcome_type
        FROM int_match_results
        WHERE winner IS NOT NULL
          AND first_innings_runs IS NOT NULL
        ORDER BY season DESC, match_id DESC
        LIMIT 20
    """).df()

    print(f"🤖 Generating reports for {len(matches)} matches...\n")

    # Create output table if not exists
    con.execute("""
        CREATE TABLE IF NOT EXISTS mart_match_reports (
            match_id     INTEGER,
            season       VARCHAR,
            venue        VARCHAR,
            winner       VARCHAR,
            ai_report    VARCHAR,
            generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    """)

    # Clear previous reports
    con.execute("DELETE FROM mart_match_reports")

    reports = []
    for i, row in matches.iterrows():
        match = row.to_dict()
        print(f"  [{i+1}/{len(matches)}] Match {match['match_id']} — "
              f"{match['first_innings_team']} vs {match['second_innings_team']}")

        try:
            report = generate_match_report(match)
            reports.append({
                "match_id"  : match['match_id'],
                "season"    : match['season'],
                "venue"     : match['venue'],
                "winner"    : match['winner'],
                "ai_report" : report
            })
            print(f"     ✅ {report[:80]}...")

        except Exception as e:
            print(f"     ⚠ Skipped: {e}")

        # Respect free tier rate limit
        time.sleep(1.5)

    # Insert all reports
    import pandas as pd
    df = pd.DataFrame(reports)
    con.execute("INSERT INTO mart_match_reports SELECT "
                "match_id, season, venue, winner, ai_report, "
                "CURRENT_TIMESTAMP FROM df")

    print(f"\n✅ {len(reports)} match reports stored in mart_match_reports")

    # Preview
    print("\n=== SAMPLE REPORTS ===")
    sample = con.execute("""
        SELECT match_id, season, winner, ai_report 
        FROM mart_match_reports 
        LIMIT 3
    """).df()

    for _, row in sample.iterrows():
        print(f"\nMatch {row['match_id']} ({row['season']}) — {row['winner']}")
        print(f"{row['ai_report']}")

    con.close()


if __name__ == "__main__":
    main()