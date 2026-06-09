with matches as (
    select * from {{ ref('int_match_results') }}
),

venue_stats as (
    select
        venue,
        city,

        -- Volume
        count(*)                                        as total_matches,

        -- Scoring patterns
        round(avg(first_innings_runs), 1)               as avg_first_innings_score,
        round(avg(second_innings_runs), 1)              as avg_second_innings_score,
        max(first_innings_runs)                         as highest_score,
        min(first_innings_runs)                         as lowest_score,

        round(avg(
            first_innings_runs + second_innings_runs
        ), 1)                                           as avg_total_runs,

        -- Boundaries
        round(avg(
            first_innings_fours + second_innings_fours
        ), 1)                                           as avg_fours_per_match,
        round(avg(
            first_innings_sixes + second_innings_sixes
        ), 1)                                           as avg_sixes_per_match,

        -- Chase stats
        count(case when match_outcome_type = 'chased' 
              then 1 end)                               as chases_successful,
        count(case when match_outcome_type = 'defended' 
              then 1 end)                               as defences_successful,

        round(
            count(case when match_outcome_type = 'chased' 
                  then 1 end) * 100.0
            / nullif(count(
                case when match_outcome_type 
                     in ('chased','defended') 
                then 1 end), 0), 1)                     as chase_success_pct,

        -- Toss impact at venue
        round(
            count(case when toss_winner_won_match = true 
                  then 1 end) * 100.0
            / nullif(count(*), 0), 1)                   as toss_win_match_win_pct,

        -- Season range
        min(season)                                     as first_season,
        max(season)                                     as last_season

    from matches
    where first_innings_runs is not null
    group by venue, city
    having count(*) >= 5
)

select * from venue_stats
order by total_matches desc