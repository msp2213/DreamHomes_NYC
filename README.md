# Dream Homes NYC Database Project
This is project submission for group 1 - Fall 2025
This repository contains the full PostgreSQL database schema, synthetic data generation scripts, data loading pipeline, and final Metabase dashboards for the Dream Homes NYC real estate project. The system is designed to provide dual access: high-level Strategic Overview for executives and a granular Analyst Workbench for technical users.

## Project Setup and Data Loading
This step creates the PostgreSQL database and all necessary tables, constraints, functions, and analytical views.

A. Database Creation
  1. Open pgAdmin or your preferred PostgreSQL client.
  2. Create a new database named dream_homes.

B. Run Schema:
  1. Execute the entire contents of final_core_schema.sql against the new database.
     This creates the realestate schema, 15+ tables, foreign keys, triggers, and the two analytical views (v_agent_quarterly_performance and v_property_margin_candidates)."

The conceptual and logical database design is detailed in the attached Entity Relationship Diagram: [ERD - Final Schema.pdf]

## Synthetic Data Generation Pipeline
The data loading requires following a strict dependency order to satisfy foreign key constraints. This pipeline generates all transactional, personnel, and property data.
Order,Colab File,Purpose (Input/Output)
  1. 01_core_setup.ipynb -- Generates the foundational addresses.csv (150 unique addresses).
  2. 02_people_org.ipynb -- Generates Personnel tables (offices, users, agents, clients), relying on the addresses.csv file.
  3. 03_property_prep.ipynb -- Generates Inventory tables (client_preferences, properties), relying on client_ids and address_ids from previous steps.
  4. 04_activity_gen.ipynb -- Generates all final Transactional tables (listings, appointments, offers, transactions, marketing_campaigns), relying on primary keys from all previous files.
  5. 05_lookup_tables.ipynb -- Generates static Lookup Tables (listing_statuses, appointment_types, etc.).

## Inserting Data into PostgreSQL
After generating all CSVs, the final script loads the data in the correct dependency order.
  - File: Data_loading_SQL.ipynb
  - Reminder: Before running, update the OUTPUT_DIR variable within the file to the local path where your simulated CSV files are saved. Then, execute the script to bulk-insert all data into the realestate schema.

## Metabase Dashboard Access
The visualization layer is organized into two primary user experiences.

  1. Executive Dashboard
  - Description: This is the top-level access point, containing the following two tabs:
  - A. Strategic Overview (C-Level Summary): This tab delivers high-level financial KPIs and long-term strategic insights (Volume, Commission, Pricing Trends).
  - B. Operational Deep Dive (Manager/COO View): This tab provides process efficiency and resource allocation metrics, including funnel conversion and agent workload analysis.

  2. Analyst Workbench (Technical Views Collection)
  - A. Agent Activity
  - B. Client Overview
  - C. Offer & Listing Activity
  - D. Property Distribution Activity
  - E. User Activity Log

## 10 Analytical Procedures
The file 10 analytical procedures.sql contains the following complex queries, demonstrating proficiency by utilizing multi-table joins, JSON parsing, and conditional aggregation:
1. "Agent Commission Leaderboard
  - Q: Who are our top revenue-generating agents, and how do they rank in the current market cycle?
  - Talent Management: Dynamically identifies top performers using commission as the metric, guiding quarterly bonuses, incentives, and allocation of premium resources.

2. Pricing Strategy Insight (Margin Analysis)
  -  Q: Which property types are we systematically over- or under-pricing relative to the final close price?,
  -  Pricing Optimization: Provides direct feedback on listing price accuracy. If the average margin is positive (selling above list), prices may be too low; if negative, pricing models require adjustment.

3. Operational Risk Watchlist
  - Q: Which active listings have high showing activity (>=5) but have generated zero offers?
  - Risk Intervention: Creates an immediate, actionable list for managers to review. These listings are ""at-risk"" of expiring or becoming stale, necessitating a price drop or new marketing campaign.
  
4. Client Targeting Focus
  - Q: Which specific property types are our clients requesting most frequently right now?
  - Acquisition Strategy: Guides agents and acquisition teams on where market demand is highest, allowing them to focus efforts on sourcing new inventory that matches existing buyer preferences.

5. Office Volume Comparison
  - Q: How is each branch office performing in total transaction volume over the last 12 months?
  - Regional Market Assessment: Assesses the relative success of regional offices and pinpoints where management or resources need to be strengthened to capture market share

6. Sales Funnel Efficiency (Conversion Rate)
  - Q: What percentage of all scheduled appointments ultimately result in an offer being made?
  - Process Monitoring: Measures the overall health and conversion quality of the sales funnel. This KPI is used by managers to coach agents on showing effectiveness.

7. Agent Workload
  - Q: How is the current appointment workload distributed across our team of agents?
  - Resource Allocation: Identifies agents with either extreme workloads (potential burnout) or low activity (needs new leads/training), enabling balanced distribution.

8. Marketing Lead Engagement (CTR)
  - Q: Which marketing channels provide the highest click-through rate (CTR) on average?
  - Marketing ROI: Directly measures the quality of digital campaigns. Guides marketing budgets to the channels that successfully engage leads (Clicks/Impressions).
    
9. Client Demographics Segmentation
  - Q: What is the distribution of client household sizes in our database for targeted outreach?
  - Client Profiling: Uses a capability unique to PostgreSQL by parsing semi-structured data (JSONB) to group clients by key demographic fields.
    
10. Inventory Aging Analysis
  - Q: What is the average number of days each property type spends in the 'Active' status?
  - Pipeline Speed: Establishes benchmarks for expected Days on Market (DOM) by segment, flagging properties that linger significantly longer than the average for proactive review.
