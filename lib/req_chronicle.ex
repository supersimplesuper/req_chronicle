defmodule ReqChronicle do
  @moduledoc """
  A plugin for the Elixir Req library.

  ReqChronicle aims to provide mechanisms for recording and logging requests and responses made using Req.

  # Installation

  # Configuration

  # Usage

  # Help

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
