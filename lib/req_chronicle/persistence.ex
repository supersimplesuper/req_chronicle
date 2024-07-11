defmodule ReqChronicle.Persistence do
  @moduledoc """
  Provides mechanisms for persisting requests and responses.
  """

  @type schema_id :: non_neg_integer() | Ecto.UUID.t()
  @type body_handler :: (iodata() | Enumerable.t() | nil -> String.t())

  @type request_params :: %{
          url: String.t(),
          method: String.t(),
          headers: map(),
          body: String.t(),
          query_params: map()
        }

  @type response_params :: %{
          status_code: String.t(),
          headers: map(),
          body: String.t(),
          request_id: schema_id()
        }

  @doc """
  Persists a request to the configured persistence layer.
  """
  @spec persist_request(Req.Request.t()) :: Req.Request.t()
  def persist_request(%Req.Request{} = request) do
    schema = request_schema(request)
    repo = persistence_repo(request)
    body_handler = request_body_handler(request)
    params = build_request_params(request, body_handler)

    # Build a changeset and insert the schema into the provided Repo
    inserted_request = schema |> schema.changeset(params) |> repo.insert!()

    # Return the request
    # We put the inserted request ID into the private fields of the request so that it can be accessed
    # when handling the response.
    Req.Request.put_private(request, :chronicle_request_id, inserted_request.id)
  end

  @doc """
  Persists a response to the configured persistence layer.
  """
  @spec persist_response({req, res}) :: {req, res} when req: Req.Request.t(), res: Req.Response.t()
  def persist_response({request, response}) do
    schema = response_schema(request)
    repo = persistence_repo(request)

    # We need the request ID to associate the response with the request
    request_id = Req.Request.get_private(request, :chronicle_request_id)

    body_handler = response_body_handler(request)
    params = build_response_params(response, body_handler, request_id)

    _inserted_response = schema |> schema.changeset(params) |> repo.insert!()

    {request, response}
  end

  @spec request_body_handler(Req.Request.t()) :: (iodata() | Enumerable.t() | nil -> String.t())
  def request_body_handler(request) do
    {m, f, a} = request |> request_options() |> Keyword.get(:body_handler)
    fn b -> apply(m, f, [b | a]) end
  end

  @spec response_body_handler(Req.Request.t()) :: (iodata() | Enumerable.t() | nil -> String.t())
  def response_body_handler(request) do
    {m, f, a} = request |> response_options() |> Keyword.get(:body_handler)
    fn b -> apply(m, f, [b | a]) end
  end

  @spec build_request_params(Req.Request.t(), body_handler()) :: request_params()
  def build_request_params(request, body_handler) do
    url = URI.to_string(request.url)
    method = Atom.to_string(request.method)
    headers = Map.new(request.headers)
    body = body_handler.(request.body)
    query_params = request |> Req.Request.get_option(:params, %{}) |> Map.new()

    %{
      url: url,
      method: method,
      headers: headers,
      body: body,
      query_params: query_params
    }
  end

  @spec build_response_params(Req.Response.t(), body_handler(), schema_id()) :: response_params()
  def build_response_params(response, body_handler, request_id) do
    status_code = Integer.to_string(response.status)
    headers = Map.new(response.headers)
    body = body_handler.(response.body)

    %{
      status_code: status_code,
      headers: headers,
      body: body,
      request_id: request_id
    }
  end

  defp persistence_repo(request), do: request |> persistence_options() |> Keyword.get(:repo)
  defp request_schema(request), do: request |> request_options() |> Keyword.get(:schema)
  defp response_schema(request), do: request |> response_options() |> Keyword.get(:schema)
  defp persistence_options(request), do: get_in(request.options, [:chronicle, :persistence])
  defp request_options(request), do: get_in(request.options, [:chronicle, :persistence, :requests])
  defp response_options(request), do: get_in(request.options, [:chronicle, :persistence, :responses])
end
