defmodule ReqChronicle.OptionsTest do
  use ExUnit.Case, async: true

  alias ReqChronicle.Options

  describe "validate/1" do
    test "validates correct options" do
      opts = [
        persistence: [
          requests: [
            enabled: true,
            schema: MyApp.RequestSchema
          ],
          responses: [
            enabled: true,
            schema: MyApp.ResponseSchema
          ],
          repo: MyApp.Repo
        ],
        logging: [
          requests: true,
          responses: true,
          level: :info
        ]
      ]

      assert validated = Options.validate(opts)

      assert validated[:persistence][:requests][:enabled]
      assert validated[:persistence][:requests][:schema] == MyApp.RequestSchema
      assert validated[:persistence][:responses][:enabled]
      assert validated[:persistence][:responses][:schema] == MyApp.ResponseSchema
      assert validated[:persistence][:repo] == MyApp.Repo
      assert validated[:logging][:requests]
      assert validated[:logging][:responses]
    end

    test "raises error when repo is missing and persistence is enabled" do
      opts = [
        persistence: [
          requests: [
            enabled: true,
            schema: MyApp.RequestSchema
          ],
          responses: [
            enabled: true,
            schema: MyApp.ResponseSchema
          ]
        ],
        logging: [
          requests: true,
          responses: true,
          level: :info
        ]
      ]

      assert_raise ArgumentError, "You must provide a Repo module for storing requests and responses", fn ->
        Options.validate(opts)
      end
    end

    test "raises error when request schema is missing and request persistence is enabled" do
      opts = [
        persistence: [
          requests: [
            enabled: true
          ],
          responses: [
            enabled: true,
            schema: MyApp.ResponseSchema
          ],
          repo: MyApp.Repo
        ],
        logging: [
          requests: true,
          responses: true,
          level: :info
        ]
      ]

      assert_raise ArgumentError, "You must provide a schema for storing requests", fn ->
        Options.validate(opts)
      end
    end

    test "raises error when response schema is missing and response persistence is enabled" do
      opts = [
        persistence: [
          requests: [
            enabled: true,
            schema: MyApp.RequestSchema
          ],
          responses: [
            enabled: true
          ],
          repo: MyApp.Repo
        ],
        logging: [
          requests: true,
          responses: true,
          level: :info
        ]
      ]

      assert_raise ArgumentError, "You must provide a schema for storing responses", fn ->
        Options.validate(opts)
      end
    end

    test "accepts valid custom body handlers" do
      opts = [
        persistence: [
          requests: [
            enabled: true,
            schema: MyApp.RequestSchema,
            body_handler: {MyModule, :my_function, []}
          ],
          responses: [
            enabled: true,
            schema: MyApp.ResponseSchema
          ],
          repo: MyApp.Repo
        ],
        logging: [
          requests: true,
          responses: true,
          level: :info
        ]
      ]

      validated = Options.validate(opts)
      assert validated[:persistence][:requests][:body_handler] == {MyModule, :my_function, []}
    end

    test "uses default values when not provided" do
      opts = [
        persistence: [
          requests: [
            schema: MyApp.RequestSchema
          ],
          responses: [
            schema: MyApp.ResponseSchema
          ],
          repo: MyApp.Repo
        ],
        logging: [
          level: :info
        ]
      ]

      validated = Options.validate(opts)

      assert validated[:persistence][:requests][:enabled] == true
      assert validated[:persistence][:responses][:enabled] == true
      assert validated[:logging][:requests] == true
      assert validated[:logging][:responses] == true
      assert validated[:logging][:level] == :info
    end
  end
end
