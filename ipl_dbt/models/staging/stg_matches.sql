with source as (
    select * from {{ source('main', 'matches') }}
),

cleaned as (
    select
        id                                          as match_id,
        -- Fix inconsistent season formats to a clean 4-digit year
        case
            when season = '2007/08' then '2008'
            when season = '2009/10' then '2010'
            when season = '2020/21' then '2021'
            else season
        end                                         as season,
        city,
        date                                        as match_date,
        match_type,
        venue,
        team1,
        team2,
        toss_winner,
        toss_decision,
        -- Null out 'NA' strings
        nullif(winner, 'NA')                        as winner,
        nullif(result, 'NA')                        as result,
        nullif(result_margin, 'NA')                 as result_margin,
        nullif(player_of_match, 'NA')               as player_of_match,
        nullif(method, 'NA')                        as method,
        super_over,
        -- Derived columns
        case
            when toss_winner = team1 then team2
            else team1
        end                                         as toss_loser,
        case
            when toss_winner = winner then true
            else false
        end                                         as toss_winner_won_match
    from source
)

select * from cleaned