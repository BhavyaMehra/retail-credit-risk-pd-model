
-- Portfolio Summary
DROP TABLE IF EXISTS public.portfolio_summary;

CREATE TABLE public.portfolio_summary AS
SELECT
    COUNT(*) AS total_loans,
    ROUND(AVG(default_flag)::numeric,4) AS validation_default_rate,
    ROUND(AVG(loan_amnt)::numeric,2) AS avg_loan_amount
FROM public.lendingclub_test;



-- Default Rate by Grade
DROP TABLE IF EXISTS public.grade_risk_analysis;

CREATE TABLE public.grade_risk_analysis AS
SELECT
    grade,
    COUNT(*) AS loans,
    ROUND(AVG(default_flag)::numeric,4) AS bad_rate
FROM public.lendingclub_test
GROUP BY grade
ORDER BY grade;



-- Default Rate by FICO Band
DROP TABLE IF EXISTS public.fico_band_analysis;

CREATE TABLE public.fico_band_analysis AS
SELECT
    CASE 
        WHEN fico_range_low < 680 THEN '660-679'
        WHEN fico_range_low < 700 THEN '680-699'
        WHEN fico_range_low < 720 THEN '700-719'
        WHEN fico_range_low < 740 THEN '720-739'
        ELSE '740+'
    END AS fico_band,
    COUNT(*) AS loans,
    ROUND(AVG(default_flag)::numeric,4) AS bad_rate
FROM public.lendingclub_test
GROUP BY fico_band
ORDER BY fico_band;



-- Default Rate by Term
DROP TABLE IF EXISTS public.term_risk_analysis;

CREATE TABLE public.term_risk_analysis AS
SELECT
    term,
    COUNT(*) AS loans,
    ROUND(AVG(default_flag)::numeric,4) AS bad_rate
FROM public.lendingclub_test
GROUP BY term
ORDER BY term;