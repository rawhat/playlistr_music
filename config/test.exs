config :bolt_sips, Bolt,
  hostname: 'localhost',
  port: 7687,
  basic_auth: [Username: "neo4j", password: "Password12"]
  pool_size: 5,
  max_overflow: 1