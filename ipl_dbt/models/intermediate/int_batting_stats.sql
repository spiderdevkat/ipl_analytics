with deliveries as (
    select * from {{ ref('stg_deliveries') }}
),

batting as (
    select
        match_id,
        inning,
        batting_team_clean,
        batter,

        -- Volume
        count(*)                                        as balls_faced,
        sum(batsman_runs)                               as runs_scored,

        -- Boundaries
        sum(is_four)                                    as fours,
        sum(is_six)                                     as sixes,
        sum(is_dot_ball)                                as dot_balls,

        -- Dismissal
        max(is_wicket)                                  as was_dismissed,

        -- Phase-wise runs
        sum(case when phase = 'Powerplay' 
            then batsman_runs else 0 end)               as pp_runs,
        sum(case when phase = 'Middle' 
            then batsman_runs else 0 end)               as middle_runs,
        sum(case when phase = 'Death' 
            then batsman_runs else 0 end)               as death_runs,

        -- Computed metrics
        {{ strike_rate('sum(batsman_runs)', 'count(*)') }}
                                                        as strike_rate,
        {{ boundary_pct('sum(is_four)', 'sum(is_six)', 'count(*)') }}
                                                        as boundary_pct,
        {{ dot_ball_pct('sum(is_dot_ball)', 'count(*)') }}
                                                        as dot_ball_pct

    from deliveries
    -- Only regular innings, exclude super overs
    where inning in (1, 2)
    group by match_id, inning, batting_team_clean, batter
)

select * from batting