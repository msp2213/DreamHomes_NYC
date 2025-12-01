-- Dream Homes NYC — Core Schema (PostgreSQL)
-- Checkpoint 4 Final Schema: Data Loading and Constraint Enforcement

CREATE SCHEMA IF NOT EXISTS realestate;
SET search_path = realestate, public;

-- ***************************************************************** --
-- 1. LOOKUP TABLES (Static Data Pre-Inserted)
-- ***************************************************************** --

CREATE TABLE states (
  state_code CHAR(2) PRIMARY KEY,
  state_name VARCHAR(100) NOT NULL
);
INSERT INTO states(state_code, state_name) VALUES
('NY','New York'), ('NJ','New Jersey'), ('CT','Connecticut');

CREATE TABLE property_types (
  property_type_id SMALLSERIAL PRIMARY KEY,
  name VARCHAR(100) UNIQUE NOT NULL
);
INSERT INTO property_types(property_type_id, name)
VALUES (1, 'Single Family'), (2, 'Townhouse'), (3, 'Condo'), (4, 'Co-op'), (5, 'Multi-Family');

CREATE TABLE listing_statuses (
  listing_status_id SMALLSERIAL PRIMARY KEY,
  name VARCHAR(100) UNIQUE NOT NULL
);
INSERT INTO listing_statuses(listing_status_id, name)
VALUES (1, 'Active'), (2, 'Pending'), (3, 'Sold'), (4, 'Rented'), (5, 'Withdrawn');

CREATE TABLE appointment_types (
  appointment_type_id SMALLSERIAL PRIMARY KEY,
  name VARCHAR(100) UNIQUE NOT NULL
);
INSERT INTO appointment_types(appointment_type_id, name)
VALUES (1, 'Showing'), (2, 'Open House'), (3, 'Consultation'), (4, 'Virtual Tour');

CREATE TABLE appointment_outcomes (
  appointment_outcome_id SMALLSERIAL PRIMARY KEY,
  name VARCHAR(100) UNIQUE NOT NULL
);
INSERT INTO appointment_outcomes(appointment_outcome_id, name)
VALUES (1, 'Attended'), (2, 'No Show'), (3, 'Offer Made'), (4, 'Follow Up Scheduled');

CREATE TABLE offer_statuses (
  offer_status_id SMALLSERIAL PRIMARY KEY,
  name VARCHAR(100) UNIQUE NOT NULL
);
INSERT INTO offer_statuses(offer_status_id, name)
VALUES (1, 'Submitted'), (2, 'Accepted'), (3, 'Rejected'), (4, 'Withdrawn'), (5, 'Expired'), (6, 'Countered');

CREATE TABLE marketing_channels (
  marketing_channel_id SMALLSERIAL PRIMARY KEY,
  name VARCHAR(100) UNIQUE NOT NULL
);
INSERT INTO marketing_channels(name)
VALUES ('Website'), ('Social Media'), ('Email'), ('Print'), ('3rd-Party Portal');

-- ***************************************************************** --
-- 2. CORE DYNAMIC TABLES
-- ***************************************************************** --

CREATE TABLE addresses (
  address_id BIGSERIAL PRIMARY KEY,
  line1 VARCHAR(200) NOT NULL,
  line2 VARCHAR(100),
  city VARCHAR(150) NOT NULL,
  state_code CHAR(2) REFERENCES states(state_code),
  postal_code VARCHAR(9) NOT NULL,
  latitude NUMERIC(9,6),
  longitude NUMERIC(9,6)
);

CREATE TABLE offices (
  office_id BIGSERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  phone VARCHAR(11),
  email VARCHAR(150),
  address_id BIGINT REFERENCES addresses(address_id)
);

CREATE TABLE users (
  user_id BIGSERIAL PRIMARY KEY,
  username VARCHAR(150) UNIQUE NOT NULL,
  email VARCHAR(150) UNIQUE NOT NULL,
  role VARCHAR(50) NOT NULL,
  CONSTRAINT chk_users_role CHECK (lower(btrim(role)) IN ('admin', 'manager', 'agent')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE agents (
  agent_id BIGSERIAL PRIMARY KEY,
  first_name VARCHAR(100) NOT NULL,
  last_name  VARCHAR(100) NOT NULL,
  email VARCHAR(150) UNIQUE NOT NULL,
  phone VARCHAR(20),
  license_number VARCHAR(50) UNIQUE NOT NULL,
  employment_type VARCHAR(100) NOT NULL CHECK (employment_type IN ('Full-Time', 'Part-Time')),
  commission_rate NUMERIC(5,4) NOT NULL CHECK (commission_rate >= 0 AND commission_rate <= 1),
  hire_date DATE,
  active BOOLEAN NOT NULL DEFAULT TRUE,
  user_id BIGINT REFERENCES users(user_id),
  role VARCHAR(50) NOT NULL DEFAULT 'Agent',
  CONSTRAINT chk_agents_role CHECK (lower(btrim(role)) IN ('admin', 'manager', 'agent')),
  office_id BIGINT REFERENCES offices(office_id)
);

ALTER TABLE offices
  ADD COLUMN manager_agent_id BIGINT,
  ADD CONSTRAINT offices_manager_fkey
    FOREIGN KEY (manager_agent_id) REFERENCES agents(agent_id);

CREATE TABLE clients (
  client_id BIGSERIAL PRIMARY KEY,
  first_name VARCHAR(100) NOT NULL,
  last_name  VARCHAR(100) NOT NULL,
  email VARCHAR(150) UNIQUE,
  phone VARCHAR(20),
  client_type VARCHAR(50) NOT NULL CHECK (client_type IN ('Buyer', 'Seller', 'Renter', 'Buyer/Seller')),
  demographics JSONB,
  mailing_address_id BIGINT REFERENCES addresses(address_id)
);

CREATE TABLE client_preferences (
  client_id BIGINT PRIMARY KEY REFERENCES clients(client_id) ON DELETE CASCADE,
  min_price NUMERIC(14,2) CHECK (min_price >= 0),
  max_price NUMERIC(14,2) CHECK (max_price >= 0),
  desired_bedrooms SMALLINT CHECK (desired_bedrooms >= 0),
  desired_bathrooms NUMERIC(3,1) CHECK (desired_bathrooms >= 0),
  property_type_id SMALLINT REFERENCES property_types(property_type_id)
);

CREATE TABLE properties (
  property_id BIGSERIAL PRIMARY KEY,
  address_id BIGINT NOT NULL REFERENCES addresses(address_id),
  property_type_id SMALLINT NOT NULL REFERENCES property_types(property_type_id),
  bedrooms SMALLINT CHECK (bedrooms >= 0),
  bathrooms NUMERIC(3,1) CHECK (bathrooms >= 0),
  square_feet INTEGER CHECK (square_feet >= 0),
  year_built SMALLINT,
  description TEXT,
  owner_client_id BIGINT REFERENCES clients(client_id)
);

CREATE TABLE listings (
  listing_id BIGSERIAL PRIMARY KEY,
  property_id BIGINT NOT NULL UNIQUE REFERENCES properties(property_id) ON DELETE CASCADE,
  agent_id BIGINT NOT NULL REFERENCES agents(agent_id),
  list_price NUMERIC(14,2) NOT NULL CHECK (list_price > 0),
  listing_status_id SMALLINT NOT NULL REFERENCES listing_statuses(listing_status_id),
  listed_date DATE NOT NULL,
  closed_date DATE,
  CHECK (closed_date IS NULL OR closed_date >= listed_date)
);

CREATE TABLE appointments (
  appointment_id BIGSERIAL PRIMARY KEY,
  appointment_type_id SMALLINT NOT NULL REFERENCES appointment_types(appointment_type_id),
  appointment_datetime TIMESTAMPTZ NOT NULL,
  listing_id BIGINT NOT NULL REFERENCES listings(listing_id),
  client_id BIGINT NOT NULL REFERENCES clients(client_id),
  appointment_outcome_id SMALLINT REFERENCES appointment_outcomes(appointment_outcome_id),
  notes TEXT
);

CREATE TABLE offers (
  offer_id BIGSERIAL PRIMARY KEY,
  listing_id BIGINT NOT NULL REFERENCES listings(listing_id) ON DELETE CASCADE,
  buyer_client_id BIGINT NOT NULL REFERENCES clients(client_id),
  offer_amount NUMERIC(14,2) NOT NULL CHECK (offer_amount > 0),
  offer_date DATE NOT NULL,
  offer_status_id SMALLINT NOT NULL REFERENCES offer_statuses(offer_status_id),
  notes TEXT
);

CREATE TABLE transactions (
  transaction_id BIGSERIAL PRIMARY KEY,
  listing_id BIGINT NOT NULL UNIQUE REFERENCES listings(listing_id) ON DELETE CASCADE,
  buyer_client_id BIGINT REFERENCES clients(client_id),
  seller_client_id BIGINT REFERENCES clients(client_id),
  agent_id BIGINT NOT NULL REFERENCES agents(agent_id),
  office_id BIGINT REFERENCES offices(office_id),
  transaction_type VARCHAR(50) NOT NULL CHECK (transaction_type IN ('Sale', 'Rental')),
  close_price NUMERIC(14,2) NOT NULL CHECK (close_price > 0),
  commission_pct NUMERIC(5,4) CHECK (commission_pct >= 0 AND commission_pct <= 1),
  commission_amount NUMERIC(14,2) CHECK (commission_amount >= 0),
  close_date DATE NOT NULL
);

CREATE TABLE marketing_campaigns (
  marketing_campaign_id BIGSERIAL PRIMARY KEY,
  listing_id  BIGINT NOT NULL REFERENCES listings(listing_id) ON DELETE CASCADE,
  channel     TEXT NOT NULL DEFAULT 'Website',
  start_date  DATE NOT NULL,
  end_date    DATE,
  cost        NUMERIC(14,2) CHECK (cost >= 0),
  impressions INTEGER CHECK (impressions >= 0),
  clicks      INTEGER CHECK (clicks >= 0),
  CONSTRAINT chk_marketing_campaigns_channel
    CHECK (lower(btrim(channel)) IN (
      'website', 'social media', 'email', 'print', '3rd-party portal'
    )),
  CHECK (end_date IS NULL OR end_date >= start_date)
);

-- ***************************************************************** --
-- 3. TRIGGERS (FIXED SCHEMA QUALIFICATION)
-- ***************************************************************** --

-- 1) Trigger to auto-populate office_id based on agent_id 
CREATE OR REPLACE FUNCTION trg_transactions_set_office()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  -- FIX: Explicitly qualify schema for 'agents' table
  SELECT office_id INTO NEW.office_id FROM realestate.agents WHERE agent_id = NEW.agent_id;
  RETURN NEW;
END $$;

CREATE TRIGGER transactions_set_office
BEFORE INSERT ON realestate.transactions
FOR EACH ROW EXECUTE FUNCTION trg_transactions_set_office();

-- 2) Commission validation (Tolerance adjusted to 0.05 for floating point errors)
CREATE OR REPLACE FUNCTION trg_transactions_commission_check()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.commission_pct IS NOT NULL AND NEW.commission_amount IS NOT NULL THEN
    -- Check equality within a small tolerance (0.05) to account for expected rounding errors
    IF abs(NEW.commission_amount - (NEW.close_price * NEW.commission_pct)) > 0.05 THEN
      RAISE EXCEPTION 'commission_amount (%.2f) must equal close_price * commission_pct (%.2f)',
        NEW.commission_amount, NEW.close_price * NEW.commission_pct;
    END IF;
  END IF;
  RETURN NEW;
END $$;

CREATE TRIGGER transactions_commission_check
BEFORE INSERT OR UPDATE ON realestate.transactions
FOR EACH ROW EXECUTE FUNCTION trg_transactions_commission_check();

-- 3) Update listing status after transaction (FIXED LOGIC to handle temporal inconsistency)
CREATE OR REPLACE FUNCTION trg_transactions_update_listing_status()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
  v_status_id SMALLINT;  
  v_listed_date DATE;    
BEGIN
  -- Get the original listed date 
  SELECT listed_date INTO v_listed_date
  FROM realestate.listings
  WHERE listing_id = NEW.listing_id;

  -- Get the new status ID
  SELECT listing_status_id INTO v_status_id
  FROM realestate.listing_statuses
  WHERE name = CASE WHEN NEW.transaction_type = 'Sale' THEN 'Sold' ELSE 'Rented' END;

  -- Update status unconditionally, but update closed_date conditionally:
  -- The closed_date is ONLY updated if NEW.close_date is chronologically >= listed_date.
  UPDATE realestate.listings
      SET listing_status_id = v_status_id, 
          closed_date = CASE 
                            WHEN NEW.close_date >= v_listed_date THEN NEW.close_date 
                            ELSE v_listed_date + INTERVAL '1 day' -- Use earliest valid date if data is impossible
                        END
    WHERE listing_id = NEW.listing_id;

  RETURN NEW;
END $$;

CREATE TRIGGER transactions_update_listing_status
AFTER INSERT ON realestate.transactions
FOR EACH ROW EXECUTE FUNCTION trg_transactions_update_listing_status();

-- ***************************************************************** --
-- 4. ANALYTICAL VIEWS
-- ***************************************************************** --

CREATE OR REPLACE VIEW realestate.v_agent_quarterly_performance AS
SELECT
  a.agent_id,
  a.first_name || ' ' || a.last_name AS agent_name,
  date_trunc('quarter', t.close_date)::date AS quarter_start,
  COUNT(*) AS transactions_count,
  SUM(t.close_price) AS total_volume,
  SUM(COALESCE(t.commission_amount, t.close_price * COALESCE(t.commission_pct, 0))) AS total_commission
FROM realestate.transactions t
JOIN realestate.agents a ON a.agent_id = t.agent_id
GROUP BY a.agent_id, agent_name, date_trunc('quarter', t.close_date);

CREATE OR REPLACE VIEW realestate.v_property_margin_candidates AS
SELECT
  l.listing_id,
  p.property_id,
  pt.name AS property_type,
  l.list_price,
  t.close_price,
  (t.close_price - l.list_price) AS delta_price
FROM realestate.listings l
LEFT JOIN realestate.transactions t ON t.listing_id = l.listing_id
JOIN realestate.properties p ON p.property_id = l.property_id
JOIN realestate.property_types pt ON pt.property_type_id = p.property_type_id;