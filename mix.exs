defmodule PlaylistrMusic.Mixfile do
  use Mix.Project

  def project do
    [app: :playlistr_music,
     version: "0.1.0",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [ 
      # applications: [:neo4j_sips], mod: {Neo4j.Sips.Application, []},
      applications: [:bolt_sips], 
      extra_applications: [:logger], mod: {Bolt.Sips.Application, [
          url: "localhost:7687",
          basic_auth: [username: "neo4j", password: "Password12"]
        ]}
      # extra_applications: [:logger], mod:
      #   {Bolt.Sips.Application, [url: 'localhost', pool_size: 15]}
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [{:bolt_sips, "~> 0.3"},
     {:poison, "~> 3.1.0"}
    #  {:neo4j_sips, "~> 0.2"}
    ]
  end
end
