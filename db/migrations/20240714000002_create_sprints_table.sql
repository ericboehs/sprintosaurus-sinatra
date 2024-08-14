-- migrate:up
CREATE TABLE sprints (
  id serial primary key,
  iteration_id integer,
  title text,
  start_date timestamp without time zone,
  duration integer,
  created_at timestamp without time zone NOT NULL,
  updated_at timestamp without time zone NOT NULL
);

-- migrate:down
drop table sprints;
