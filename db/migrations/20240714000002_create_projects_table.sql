-- migrate:up
create table projects (
  id serial primary key,
  number integer NOT NULL,
  title text,
  closed text,
  url text,
  created_at timestamp without time zone NOT NULL,
  updated_at timestamp without time zone NOT NULL
);

-- migrate:down
drop table projects;
