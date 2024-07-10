defmodule ReqChronicle.Logger do
  @moduledoc """
  Handles logging for ReqChronicle
  """

  require Logger

  @doc """
  Logs the request.
  """
  @spec log_request(Req.Request.t()) :: Req.Request.t()
  def log_request(request) do
    Logger.info(">>> Chronicle -- Request: #{inspect(request)}")
    request
  end

  @doc """
  Logs the response.
  """
  @spec log_response({request, response}) :: {request, response} when request: Req.Request.t(), response: Req.Response.t()
  def log_response({request, response}) do
    Logger.info(">>> Chronicle -- Response: #{inspect(response)}")
    {request, response}
  end
end
