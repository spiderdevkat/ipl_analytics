with batting as (
    select * from {{ ref('int_batting_stats') }}
),

matches as (
    select * from {{ ref('stg_matches') }}
),

-- Join batting stats with match metadata
batting_with_meta as (
    select
        b.*,
        m.season,
        m.match_date,
        m.venue,
        m.city
    from batting b
    left join matches m on b.match_id = m.match_id
),

-- Season-level aggregates per player
season_stats as (
    select
        batter                                          as player_name,
        season,
        batting_team                                    as team,

        -- Innings
        count(*)                                        as innings,
        count(case when was_dismissed = 0 
              then 1 end)                               as not_outs,

        -- Runs
        sum(runs_scored)                                as total_runs,
        max(runs_scored)                                as highest_score,
        round(avg(runs_scored), 2)                      as avg_runs_per_innings,

        -- Milestones
        count(case when runs_scored >= 100 
              then 1 end)                               as centuries,
        count(case when runs_scored >= 50 
              and runs_scored < 100 
              then 1 end)                               as fifties,
        count(case when runs_scored >= 30 
              and runs_scored < 50 
              then 1 end)                               as thirties,
        count(case when runs_scored = 0 
              and was_dismissed = 1 
              then 1 end)                               as ducks,

        -- Balls + boundaries
        sum(balls_faced)                                as total_balls,
        sum(fours)                                      as total_fours,
        sum(sixes)                                      as total_sixes,
        sum(dot_balls)                                  as total_dot_balls,

        -- Phase runs
        sum(pp_runs)                                    as total_pp_runs,
        sum(middle_runs)                                as total_middle_runs,
        sum(death_runs)                                 as total_death_runs,

        -- Computed metrics
        {{ strike_rate('sum(runs_scored)', 'sum(balls_faced)') }}
                                                        as season_strike_rate,
        {{ boundary_pct('sum(fours)', 'sum(sixes)', 'sum(balls_faced)') }}
                                                        as season_boundary_pct,
        {{ dot_ball_pct('sum(dot_balls)', 'sum(balls_faced)') }}
                                                        as season_dot_ball_pct,

        -- Batting average (runs / dismissals)
        round(
            sum(runs_scored) * 1.0
            / nullif(sum(was_dismissed), 0), 2)         as batting_average

    from batting_with_meta
    group by batter, season, batting_team
)

select * from season_stats
order by season, total_runs desc