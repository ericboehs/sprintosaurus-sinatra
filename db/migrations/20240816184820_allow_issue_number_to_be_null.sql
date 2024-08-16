-- migrate:up
ALTER TABLE issues ALTER COLUMN number DROP NOT NULL;

-- migrate:down
ALTER TABLE issues ALTER COLUMN number SET NOT NULL;
