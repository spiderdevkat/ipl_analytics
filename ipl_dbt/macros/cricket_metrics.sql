{% macro strike_rate(runs, balls) %}
    round({{ runs }} * 100.0 / nullif({{ balls }}, 0), 2)
{% endmacro %}

{% macro economy_rate(runs, legal_balls) %}
    round({{ runs }} * 6.0 / nullif({{ legal_balls }}, 0), 2)
{% endmacro %}

{% macro boundary_pct(fours, sixes, balls) %}
    round(({{ fours }} + {{ sixes }}) * 100.0 / nullif({{ balls }}, 0), 2)
{% endmacro %}

{% macro dot_ball_pct(dot_balls, total_balls) %}
    round({{ dot_balls }} * 100.0 / nullif({{ total_balls }}, 0), 2)
{% endmacro %}

{% macro phase_runs(phase_name) %}
    sum(case when phase = '{{ phase_name }}' then total_runs else 0 end)
{% endmacro %}