defmodule ReqChronicle.Options do
  @moduledoc """
  Defines options for ReqChronicle, using Nimble Options.
  """

  body_handler_definition = [
    type: :mfa,
    default:
      {Kernel, :inspect,
       [
         [
           limit: :infinity,
           pretty: true,
           printable_limit: :infinity
         ]
       ]},
    doc:
      "An MFA tuple that handles request and response bodies before persistence. The function must accept a request or response as it's first argument, and return a string."
  ]

  schema_definition = [
    type: :atom,
    required: false,
    doc: "The schema to use for storing requests or responses."
  ]

  logging_definition = [
    requests: [
      type: :boolean,
      default: true,
      doc: "Whether to log requests."
    ],
    responses: [
      type: :boolean,
      default: true,
      doc: "Whether to log responses."
    ],
    level: [
      type: :atom,
      default: :info,
      doc: "The log level to use. Can be one of :debug, :info, :warn, :error"
    ]
  ]

  persistence_definition = [
    requests: [
      type: :non_empty_keyword_list,
      required: true,
      doc: "Options for persisting requests",
      keys: [
        enabled: [
          type: :boolean,
          default: true,
          doc: "Whether to persist requests."
        ],
        schema: schema_definition,
        body_handler: body_handler_definition
      ]
    ],
    responses: [
      type: :non_empty_keyword_list,
      required: true,
      doc: "Options for persisting responses",
      keys: [
        enabled: [
          type: :boolean,
          default: true,
          doc: "Whether to persist responses."
        ],
        schema: schema_definition,
        body_handler: body_handler_definition
      ]
    ],
    repo: [
      type: :atom,
      required: false,
      doc: "The Repo module to use for storing requests and responses."
    ],
    persistence_callback: [
      type: :mod_arg,
      required: false,
      doc: ~s(
        An module argument that is called instead of default persistence. Its arguments will be the configured repo,
        schema, record, andd parameters and should return the inserted record with an ID.
      )
    ]
  ]

  definition = [
    persistence: [
      type: :non_empty_keyword_list,
      required: true,
      doc: "Options for persisting requests and responses.",
      keys: persistence_definition
    ],
    logging: [
      type: :non_empty_keyword_list,
      required: true,
      doc: "Options for logging requests and responses.",
      keys: logging_definition
    ]
  ]

  @definition NimbleOptions.new!(definition)

  @doc false
  def definition, do: @definition

  @doc false
  def validate(opts), do: validate(opts, @definition)

  def validate(opts, definition) do
    validated_options = NimbleOptions.validate!(opts, definition)

    if validated_options[:persistence][:requests][:enabled] || validated_options[:persistence][:responses][:enabled] do
      repo_module = validated_options[:persistence][:repo]

      unless repo_module do
        raise ArgumentError, "You must provide a Repo module for storing requests and responses"
      end

      # Check that the repo module has actually been compiled in the Application
      case Code.ensure_compiled(repo_module) do
        {:module, _} -> :ok
        _ -> raise ArgumentError, "The Repo module you provided is not loaded"
      end
    end

    if validated_options[:persistence][:requests][:enabled] && !validated_options[:persistence][:requests][:schema] do
      raise ArgumentError, "You must provide a schema for storing requests"
    end

    if validated_options[:persistence][:responses][:enabled] && !validated_options[:persistence][:responses][:schema] do
      raise ArgumentError, "You must provide a schema for storing responses"
    end

    if validated_options[:persistence][:responses][:enabled] && !validated_options[:persistence][:requests][:enabled] do
      raise ArgumentError, "You must enable request persistence to enable response persistence"
    end

    validated_options
  end
end
