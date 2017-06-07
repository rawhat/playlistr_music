config :bolt_sips, Bolt,
  hostname: 'localhost',
  basic_auth: [username: "neo4j", password: "Password12"],
  port: 7687,
  pool_size: 10,
  max_overflow: 5