-- migrate:up
create table issues (
  id serial primary key,
  number integer NOT NULL,
  title text,
  points integer,
  status text,
  state text,
  url text,
  data jsonb,
  closed_at timestamp without time zone,
  created_at timestamp without time zone NOT NULL,
  updated_at timestamp without time zone NOT NULL
);

-- migrate:down
drop table issues;
