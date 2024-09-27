-- migrate:up
ALTER TABLE issues ADD COLUMN github_node_id TEXT;
CREATE UNIQUE INDEX idx_issues_github_node_id ON issues (github_node_id);

-- migrate:down
DROP INDEX IF EXISTS idx_issues_github_node_id;
ALTER TABLE issues DROP COLUMN IF EXISTS github_node_id;
