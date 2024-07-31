defmodule ReqChronicle do
  @moduledoc """
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

  # Help

  You can adjust the configuration options to enable/disable logging or persistence, change log levels, or provide custom body handlers as needed.
  Remember to ensure that your Repo module is properly configured and that you have the necessary database setup for Ecto to work correctly.
  This setup will allow you to start using ReqChronicle to log and persist your HTTP requests and responses made through the Req library.

  """
  alias ReqChronicle.Options

  defmacro __using__(opts) do
    quote do
      @opts Options.validate(unquote(opts))

      @spec attach_chronicle(Req.Request.t()) :: Req.Request.t()
      def attach_chronicle(req) do
        ReqChronicle.attach_req_steps(req, @opts)
      end
    end
  end

  @doc """
  Attaches the Chronicle middleware to the request.
  """
  @spec attach_chronicle(req, keyword()) :: req when req: Req.Request.t()
  def attach_chronicle(req, opts) do
    options = Options.validate(opts)
    attach_req_steps(req, options)
  end

  @doc """
  Attaches the request steps to the request.

  WARNING:
  This function is not intended to be called directly. Use `attach/2` instead.
  No validation is performed on the options passed into this function.
  """
  def attach_req_steps(req, options) do
    req
    |> Req.Request.register_options([:chronicle])
    |> Req.Request.merge_options(chronicle: options)
    |> maybe_attach_request_logger()
    |> maybe_attach_response_logger()
    |> maybe_attach_request_persistence()
    |> maybe_attach_response_persistence()
  end

  defp maybe_attach_request_logger(request) do
    if should_log_requests?(request) do
      Req.Request.append_request_steps(request, chronicle_request_logging: &ReqChronicle.Logger.log_request/1)
    else
      request
    end
  end

  defp maybe_attach_response_logger(request) do
    if should_log_responses?(request) do
      Req.Request.prepend_response_steps(request, chronicle_response_logging: &ReqChronicle.Logger.log_response/1)
    else
      request
    end
  end

  defp maybe_attach_request_persistence(request) do
    if should_persist_requests?(request) do
      Req.Request.append_request_steps(request,
        chronicle_request_persistence: &ReqChronicle.Persistence.persist_request/1
      )
    else
      request
    end
  end

  defp maybe_attach_response_persistence(request) do
    if should_persist_responses?(request) do
      Req.Request.prepend_response_steps(request,
        chronicle_response_persistence: &ReqChronicle.Persistence.persist_response/1
      )
    else
      request
    end
  end

  defp should_log_requests?(request), do: get_in(request.options, [:chronicle, :logging, :requests])
  defp should_log_responses?(request), do: get_in(request.options, [:chronicle, :logging, :responses])
  defp should_persist_requests?(request), do: get_in(request.options, [:chronicle, :persistence, :requests, :enabled])
  defp should_persist_responses?(request), do: get_in(request.options, [:chronicle, :persistence, :responses, :enabled])
end
