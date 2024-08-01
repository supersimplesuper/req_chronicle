defmodule ReqChronicleTest do
  use ExUnit.Case, async: true

  alias ReqChronicleTest.TestRepo

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass}
  end

  defmodule TestSchema do
    @moduledoc false
    use Ecto.Schema

    import Ecto.Changeset

    embedded_schema do
      field(:url, :string)
      field(:body, :string)
      field(:headers, {:array, :string})
    end

    def changeset(model, attrs) do
      model
      |> cast(attrs, [:url, :body, :headers])
      |> validate_required([:url, :body])
    end
  end

  defmodule TestRepo do
    def insert!(_), do: %{id: 1}
  end

  describe "attach/2" do
    test "attaches request and response logging when enabled", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/test", fn conn ->
        Plug.Conn.resp(conn, 200, "OK")
      end)

      opts = [
        persistence: [
          requests: [enabled: false],
          responses: [enabled: false],
          repo: ReqChronicleTest.TestRepo
        ],
        logging: [
          requests: true,
          responses: true,
          level: :info
        ]
      ]

      opts = ReqChronicle.Options.validate(opts)

      req = Req.new(url: "http://localhost:#{bypass.port}/test")
      req = ReqChronicle.attach_chronicle(req, opts)

      assert Enum.any?(req.request_steps, fn {name, _} -> name == :chronicle_request_logging end)
      assert Enum.any?(req.response_steps, fn {name, _} -> name == :chronicle_response_logging end)

      Req.get!(req)
    end

    test "attaches request and response persistence when enabled", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/test", fn conn ->
        Plug.Conn.resp(conn, 200, "OK")
      end)

      opts = [
        persistence: [
          requests: [enabled: true, schema: TestSchema],
          responses: [enabled: true, schema: TestSchema],
          repo: TestRepo
        ],
        logging: [
          requests: false,
          responses: false
        ]
      ]

      opts = ReqChronicle.Options.validate(opts)

      req = Req.new(url: "http://localhost:#{bypass.port}/test")
      req = ReqChronicle.attach_chronicle(req, opts)

      assert Enum.any?(req.request_steps, fn {name, _} -> name == :chronicle_request_persistence end)
      assert Enum.any?(req.response_steps, fn {name, _} -> name == :chronicle_response_persistence end)

      Req.get!(req)
    end

    test "does not attach when disabled", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/test", fn conn ->
        Plug.Conn.resp(conn, 200, "OK")
      end)

      opts = [
        persistence: [
          requests: [enabled: false],
          responses: [enabled: false],
          repo: MyApp.Repo
        ],
        logging: [
          requests: false,
          responses: false
        ]
      ]

      req = Req.new(url: "http://localhost:#{bypass.port}/test")
      req = ReqChronicle.attach_chronicle(req, opts)

      refute Enum.any?(req.request_steps, fn {name, _} -> String.starts_with?(to_string(name), "chronicle_") end)
      refute Enum.any?(req.response_steps, fn {name, _} -> String.starts_with?(to_string(name), "chronicle_") end)

      Req.get!(req)
    end
  end

  describe "__using__/1" do
    defmodule TestModule do
      @moduledoc false
      use ReqChronicle,
        persistence: [
          requests: [enabled: true, schema: ReqChronicleTest.TestSchema],
          responses: [enabled: true, schema: ReqChronicleTest.TestSchema],
          repo: ReqChronicleTest.TestRepo
        ],
        logging: [
          requests: true,
          responses: true
        ]

      defmodule Repo do
        def insert!(_schema), do: %{id: 1}
      end
    end

    test "defines attach/2 function" do
      assert function_exported?(TestModule, :attach_chronicle, 1)
    end

    test "attach function works correctly", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/test", fn conn ->
        Plug.Conn.resp(conn, 200, "OK")
      end)

      req = Req.new(url: "http://localhost:#{bypass.port}/test")
      req = TestModule.attach_chronicle(req)

      assert Enum.any?(req.request_steps, fn {name, _} -> String.starts_with?(to_string(name), "chronicle_") end)
      assert Enum.any?(req.response_steps, fn {name, _} -> String.starts_with?(to_string(name), "chronicle_") end)

      Req.get!(req)
    end
  end
end
