-- migrate:up
ALTER TABLE issues ADD COLUMN project_id INTEGER;
CREATE INDEX idx_issues_project_id ON issues (project_id);

-- migrate:down
DROP INDEX IF EXISTS idx_issues_project_id;
ALTER TABLE issues DROP COLUMN project_id;
