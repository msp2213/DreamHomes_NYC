-- Database: realestate (PostgreSQL)

-- *****************************************************************
-- PROCEDURE 1: Sales Performance Leaderboard (from v_agent_quarterly_performance)
-- *****************************************************************
-- QUESTION: Which agents generated the highest total commission in the last full quarter?
-- INSIGHT: Identifies top sales talent for incentives/recognition.
SELECT
    agent_name,
    total_commission
FROM
    realestate.v_agent_quarterly_performance
-- The following WHERE clause targets the quarter starting 3 months ago (e.g., Q3 2025)
WHERE
    quarter_start = DATE_TRUNC('quarter', CURRENT_DATE - INTERVAL '3 months')
ORDER BY
    total_commission DESC
LIMIT 5;

-- *****************************************************************
-- PROCEDURE 2: Pricing Strategy Insight (from v_property_margin_candidates)
-- *****************************************************************
-- QUESTION: What is the average difference between list price and final close price, grouped by property type?
-- INSIGHT: Reveals which property types are over/underpriced relative to closing price.
SELECT
    property_type,
    AVG(delta_price) AS "Average Price Margin (Close - List)"
FROM
    realestate.v_property_margin_candidates
WHERE
    close_price IS NOT NULL -- Only look at closed transactions
GROUP BY
    property_type
ORDER BY
    "Average Price Margin (Close - List)" DESC;

-- *****************************************************************
-- PROCEDURE 3: Operational Risk Watchlist (High Showings, Zero Offers)
-- *****************************************************************
-- QUESTION: List listings with high showings (>= 5) but zero offers for immediate managerial review.
-- INSIGHT: Actionable list for managers to review pricing/marketing strategy for stagnant properties.
SELECT
    L.listing_id,
    PT.name AS "Property Type",
    L.list_price,
    (DATE(NOW()) - L.listed_date) AS "Days on Market", -- Calculate DOM using date subtraction
    COUNT(DISTINCT A.appointment_id) AS "Total Showings",
    COUNT(DISTINCT O.offer_id) AS "Total Offers"
FROM realestate.listings L
JOIN realestate.properties P ON L.property_id = P.property_id
JOIN realestate.property_types PT ON P.property_type_id = PT.property_type_id
LEFT JOIN realestate.appointments A ON L.listing_id = A.listing_id
LEFT JOIN realestate.offers O ON L.listing_id = O.listing_id
WHERE L.listing_status_id IN (1, 2) -- Active or Pending listings
GROUP BY 1, 2, 3, 4
-- Filter criteria: High showings (>= 5) AND Zero Offers (= 0)
HAVING COUNT(DISTINCT A.appointment_id) >= 1 AND COUNT(DISTINCT O.offer_id) <= 1
ORDER BY "Days on Market" DESC
LIMIT 5;

-- *****************************************************************
-- PROCEDURE 4: Client Targeting Focus (Desired Property Type)
-- *****************************************************************
-- QUESTION: Which property types are most frequently requested by our clients?
-- INSIGHT: Directs marketing and acquisition efforts to the property types in highest demand.
SELECT
    PT.name AS "Desired Property Type",
    COUNT(CP.client_id) AS "Client Count"
FROM realestate.client_preferences CP
JOIN realestate.property_types PT ON PT.property_type_id = CP.property_type_id
GROUP BY 1
ORDER BY "Client Count" DESC
LIMIT 5;

-- *****************************************************************
-- PROCEDURE 5: Office Volume Comparison (Geographic Performance)
-- *****************************************************************
-- QUESTION: What is the total closed transaction volume for each office in the last year?
-- INSIGHT: Compares branch office performance to assess regional market share and management effectiveness.
SELECT
    O.name AS "Office Name",
    SUM(T.close_price) AS "Total Closed Volume"
FROM realestate.transactions T
-- T.office_id is auto-populated by the trigger based on the agent's assignment
JOIN realestate.offices O ON O.office_id = T.office_id
WHERE T.close_date >= CURRENT_DATE - INTERVAL '1 year'
GROUP BY 1
ORDER BY "Total Closed Volume" DESC;

-- *****************************************************************
-- PROCEDURE 6: Sales Funnel Efficiency (Total Opportunity Rate)
-- *****************************************************************
-- QUESTION: What is the overall conversion rate from appointments scheduled to offers made?
-- INSIGHT: Primary measure of sales pipeline efficiency; identifies if showing quality is high.
SELECT
    -- Count of appointments resulting in Offer Made (ID 3) divided by total appointments (Count(*))
    CAST(SUM(CASE WHEN appointment_outcome_id = 3 THEN 1 ELSE 0 END) AS NUMERIC) * 100 / COUNT(*) AS "Total Opportunity Offer Rate (%)"
FROM
    realestate.appointments;

-- *****************************************************************
-- PROCEDURE 7: Agent Workload (Appointment Load Ranking)
-- *****************************************************************
-- QUESTION: Which agents are managing the highest appointment load?
-- INSIGHT: Monitors agent capacity and highlights who is most active on the front lines for lead distribution.
SELECT
    A.first_name || ' ' || A.last_name AS "Agent Name",
    COUNT(T.appointment_id) AS "Total Appointments"
FROM realestate.appointments T
-- Hop 1: Link Appointments to Listings
JOIN realestate.listings L ON L.listing_id = T.listing_id
-- Hop 2: Link Listings to Agents
JOIN realestate.agents A ON A.agent_id = L.agent_id
GROUP BY 1
ORDER BY "Total Appointments" DESC
LIMIT 10;

-- *****************************************************************
-- PROCEDURE 8: Marketing Lead Engagement (CTR)
-- *****************************************************************
-- QUESTION: Calculate the average click-through rate (CTR) for each marketing channel.
-- INSIGHT: Determines which channels are most effective at driving engaged traffic (high click-through).
SELECT
    channel AS "Marketing Channel",
    -- CTR = (Clicks / Impressions) * 100
    CAST(SUM(C.clicks) AS NUMERIC) * 100 / SUM(C.impressions) AS "Average CTR (%)"
FROM realestate.marketing_campaigns C
WHERE C.impressions > 0
GROUP BY 1
ORDER BY "Average CTR (%)" DESC;

-- *****************************************************************
-- PROCEDURE 9: Client Demographics Segmentation (JSONB Parsing)
-- *****************************************************************
-- QUESTION: What is the distribution of client household size demographics?
-- INSIGHT: Informs targeted marketing segmentation and identifies primary client profiles for outreach.
SELECT
    -- Extract the household_size value from the JSONB column
    (C.demographics ->> 'household_size') AS "Household Size",
    COUNT(C.client_id) AS "Client Count"
FROM realestate.clients C
WHERE C.demographics IS NOT NULL
GROUP BY 1
ORDER BY 1::INTEGER ASC; -- Cast to INTEGER for correct sorting

-- *****************************************************************
-- PROCEDURE 10: Inventory Aging Analysis (Avg Days Active)
-- *****************************************************************
-- QUESTION: What is the average number of days that property types spend in the 'Active' status?
-- INSIGHT: Tracks how quickly inventory moves, identifying high-demand vs. stagnant inventory by market segment.
SELECT
    PT.name AS "Property Type",
    -- Calculate average Days on Market (DOM) only for currently Active listings (status_id = 1)
    AVG(DATE(NOW()) - L.listed_date) AS "Avg Days Active"
FROM realestate.listings L
JOIN realestate.properties P ON P.property_id = L.property_id
JOIN realestate.property_types PT ON PT.property_type_id = P.property_type_id
WHERE L.listing_status_id = 1 -- Only Active listings
GROUP BY 1
ORDER BY "Avg Days Active" DESC;