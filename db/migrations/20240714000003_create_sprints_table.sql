-- migrate:up
CREATE TABLE sprints (
  id serial primary key,
  iteration_id integer,
  title text,
  start_date date,
  duration integer,
  project_id integer,
  created_at timestamp without time zone NOT NULL,
  updated_at timestamp without time zone NOT NULL,
  CONSTRAINT fk_project
    FOREIGN KEY(project_id) 
    REFERENCES projects(id)
);

-- migrate:down
drop table sprints;
