WITH scored AS (
    SELECT
        default_flag,
        predicted_pd_a,
        predicted_pd_b
    FROM public.scored_test
),

stacked AS (
    SELECT
        'Model A' AS model_name,
        default_flag,
        predicted_pd_a AS predicted_pd
    FROM scored

    UNION ALL

    SELECT
        'Model B' AS model_name,
        default_flag,
        predicted_pd_b AS predicted_pd
    FROM scored
),

ranked AS (
    SELECT
        model_name,
        default_flag,
        NTILE(10) OVER (
            PARTITION BY model_name
            ORDER BY predicted_pd DESC
        ) AS decile
    FROM stacked
),

aggregated AS (
    SELECT
        model_name,
        decile,
        COUNT(*) AS loans,
        SUM(default_flag) AS bads,
        ROUND(AVG(default_flag)::numeric,4) AS bad_rate
    FROM ranked
    GROUP BY model_name, decile
)

SELECT
    model_name,
    decile,
    loans,
    bads,
    bad_rate,
    ROUND(
        SUM(bads) OVER (
            PARTITION BY model_name
            ORDER BY decile
        ) * 1.0
        / SUM(bads) OVER (PARTITION BY model_name),
    4) AS cumulative_bad_capture
FROM aggregated
ORDER BY model_name, decile;