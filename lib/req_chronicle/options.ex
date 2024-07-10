defmodule ReqChronicle.Options do
  @moduledoc """
  Defines options for ReqChronicle, using Nimble Options.
  """

  body_handler_definition = [
    type: :mfa,
    default: {Kernel, :inspect, []},
    doc:
      "An MFA tuple that handles request abd response bodies before persistence. The function must accept a request or response as it's first argument, and return a string."
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

      # TODO: Need to get this to work nicely with tests
      # unless Code.loaded?(repo_module) do
      #   raise ArgumentError, "The Repo module you provided is not loaded"
      # end
    end

    if validated_options[:persistence][:requests][:enabled] && !validated_options[:persistence][:requests][:schema] do
      raise ArgumentError, "You must provide a schema for storing requests"
    end

    if validated_options[:persistence][:responses][:enabled] && !validated_options[:persistence][:responses][:schema] do
      raise ArgumentError, "You must provide a schema for storing responses"
    end

    validated_options
  end
end
