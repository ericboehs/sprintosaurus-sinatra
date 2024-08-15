-- migrate:up
create table issues_sprints (
  issue_id integer NOT NULL,
  sprint_id integer NOT NULL,
  FOREIGN KEY (issue_id) REFERENCES issues (id),
  FOREIGN KEY (sprint_id) REFERENCES sprints (id),
  created_at timestamp without time zone NOT NULL,
  updated_at timestamp without time zone NOT NULL
);

-- migrate:down
drop table issues_sprints;
