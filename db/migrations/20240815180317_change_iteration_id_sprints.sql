-- migrate:up
ALTER TABLE sprints ALTER COLUMN iteration_id TYPE text USING iteration_id::text;

-- migrate:down
ALTER TABLE sprints ALTER COLUMN iteration_id TYPE integer USING iteration_id::integer;
