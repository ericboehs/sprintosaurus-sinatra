-- migrate:up
ALTER TABLE issues_sprints ADD COLUMN id SERIAL PRIMARY KEY;
ALTER TABLE issues_sprints ADD COLUMN removed_at TIMESTAMP;

-- migrate:down
ALTER TABLE issues_sprints DROP COLUMN removed_at;
ALTER TABLE issues_sprints DROP COLUMN id;
