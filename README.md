# ReqChronicle

A plugin for the Elixir Req library.

ReqChronicle aims to provide mechanisms for recording and logging requests and responses made using Req.

# Installation

## Add ReqChronicle to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:req_chronicle, "~> 0.1.0"}
  ]
end
```

## Add migrations for ReqChronicle tables:

```elixir
mix ecto.gen.migration add_chronicle_indexes
```

```elixir
defmodule MyApp.Repo.Migrations.AddChronicleIndexes do
  use Ecto.Migration

  def change do
    create table(:chronicle_requests, primary_key: false) do
      add :id, :uuid, null: false, default: fragment("gen_random_uuid()"), primary_key: true

      add :url, :string, null: false
      add :method, :string, null: false
      add :headers, :map, null: false
      add :body, :text, null: false, default: ""
      add :query_params, :map, null: true

      timestamps()
    end

    create table(:chronicle_responses, primary_key: false) do
      add :id, :uuid, null: false, default: fragment("gen_random_uuid()"), primary_key: true
      add :request_id, references(:chronicle_requests, type: :uuid), null: false

      add :status, :string, null: false
      add :headers, :map, null: false
      add :body, :text, null: false, default: ""

      timestamps()
    end

    # Optional (but recommended) indexes
    create index(:chronicle_requests, [:url])
    create index(:chronicle_requests, [:inserted_at])
    create index(:chronicle_responses, [:request_id])
    create index(:chronicle_responses, [:inserted_at])
  end
end
```

# Configuration

Create a module to use ReqChronicle, for example:

```elixir
defmodule YourApp.ApiClient do
  use ReqChronicle,
    persistence: [
      requests: [
        enabled: true,
        schema: YourApp.ChronicleRequest
      ],
      responses: [
        enabled: true,
        schema: YourApp.ChronicleResponse
      ],
      repo: YourApp.Repo
    ],
    logging: [
      requests: true,
      responses: true,
      level: :info
    ]

  def make_request(url) do
    Req.new()
    |> attach_chronicle()
    |> Req.get(url: url)
  end
end
```

# Usage

Use the configured module to make HTTP requests:

```elixir
YourApp.ApiClient.make_request("https://api.example.com/data")
```

This will make the request using Req, and ReqChronicle will log and persist the request and response based on your configuration.

## Changing default persistence

ReqChronicle will use the provided schema to store the request and response data synchronously if persistence is enabled. As a consequence, the database can become a bottleneck if a large number of requests are made in a short period of time.

ReqChronicle provides a `:persistence_callback` option that is called instead of the default persistence logic. This persistence callback options should be a tuple with the module and function name to call, such as `{YourApp.Chronicle, :do_persist}`.

```elixir
  use ReqChronicle,
    persistence: [
      requests: [
        enabled: true,
        schema: YourApp.ChronicleRequest
      ],
      responses: [
        enabled: true,
        schema: YourApp.ChronicleResponse
      ],
      repo: YourApp.Repo,
      persistence_callback: {YourApp.Chronicle, :do_persist}
    ],
```

This will call the function with the following arguments:

- The repo module (e.g. `YourApp.Repo`).
- The schema (e.g. `YourApp.ChronicleRequest` or `YourApp.ChronicleResponse`).
- The parameters associated with the schema.

This function should return the ID of the newly created record. However, if the persistence is asynchronous, it is strongly advised that the ID be generated beforehand.

# Help

You can adjust the configuration options to enable/disable logging or persistence, change log levels, or provide custom body handlers as needed.
Remember to ensure that your Repo module is properly configured and that you have the necessary database setup for Ecto to work correctly.
This setup will allow you to start using ReqChronicle to log and persist your HTTP requests and responses made through the Req library.


Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/req_chronicle>.
