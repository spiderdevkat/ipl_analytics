from google import genai
from google.genai import types
from dotenv import load_dotenv
import os
import duckdb

load_dotenv()

# ── Config ────────────────────────────────────────────────
DB_PATH = "ipl_dbt/dev.duckdb"
API_KEY = os.getenv("GEMINI_API_KEY")

client = genai.Client(api_key=API_KEY)
MODEL  = "gemini-3.1-flash-lite"

# ── Database schema ───────────────────────────────────────
SCHEMA = """
You have access to an IPL cricket database with these tables:

1. mart_batting (player_name, season, team, innings, total_runs, highest_score,
   batting_average, centuries, fifties, ducks, total_balls, total_fours,
   total_sixes, season_strike_rate, season_boundary_pct, total_pp_runs,
   total_middle_runs, total_death_runs)

2. mart_bowling (player_name, season, team, matches, total_overs, total_wickets,
   total_runs_conceded, season_economy, bowling_average, bowling_strike_rate,
   five_wicket_hauls, three_plus_wickets, best_bowling_wickets, total_dot_balls,
   season_dot_pct, total_pp_wickets, total_death_wickets,
   total_pp_runs_conceded, total_death_runs_conceded)

3. mart_team_performance (team, season, matches_played, matches_won, matches_lost,
   win_pct, avg_runs_scored, avg_runs_conceded, total_sixes, toss_wins,
   toss_win_conversion_pct, win_pct_batting_first, win_pct_chasing)

4. mart_venue_stats (venue, city, total_matches, avg_first_innings_score,
   avg_second_innings_score, highest_score, avg_total_runs, avg_sixes_per_match,
   chase_success_pct, toss_win_match_win_pct)

Rules:
- Always use exact table and column names above
- Use aggregations when comparing across seasons (sum/avg)
- Return only a single valid DuckDB SQL query
- No markdown, no explanation, no code fences, just raw SQL
- Limit results to 10 rows unless user asks for more
- The season column is VARCHAR (e.g. '2022', '2023', '2024'). Never do math on it directly. Use WHERE season IN ('2022','2023','2024') for last 3 seasons, or CAST(season AS INTEGER) if arithmetic is needed
"""

# ── Functions ─────────────────────────────────────────────
def generate_sql(question: str) -> str:
    prompt = f"{SCHEMA}\n\nQuestion: {question}\n\nSQL:"
    response = client.models.generate_content(model=MODEL, contents=prompt)
    sql = response.text.strip()
    # Clean any accidental markdown fences
    sql = sql.replace("```sql", "").replace("```", "").strip()
    return sql


def run_query(sql: str) -> str:
    con = duckdb.connect(DB_PATH)
    try:
        result = con.execute(sql).df()
        if result.empty:
            return "No results found."
        return result.to_string(index=False)
    except Exception as e:
        return f"Query error: {e}"
    finally:
        con.close()


def explain_results(question: str, sql: str, results: str) -> str:
    prompt = f"""You are an expert IPL cricket analyst.

Question asked: {question}
SQL used: {sql}
Results: {results}

Give a concise, insightful answer in 2-3 sentences like a cricket commentator.
Include specific numbers from the results."""
    response = client.models.generate_content(model=MODEL, contents=prompt)
    return response.text.strip()


def ask(question: str):
    print(f"\n{'='*60}")
    print(f"Q: {question}")
    print(f"{'='*60}")

    print("⚙  Generating SQL...")
    sql = generate_sql(question)
    print(f"SQL: {sql}\n")

    print("🔍 Running query...")
    results = run_query(sql)
    print(f"Results:\n{results}\n")

    print("🤖 Analysing...")
    answer = explain_results(question, sql, results)
    print(f"Answer: {answer}")


# ── Main ──────────────────────────────────────────────────
def main():
    print("🏏 IPL AI Cricket Analyst (Gemini)")
    print("Type your question or 'quit' to exit\n")

    while True:
        question = input("You: ").strip()
        if question.lower() in ("quit", "exit", "q"):
            break
        if not question:
            continue
        ask(question)


if __name__ == "__main__":
    main()