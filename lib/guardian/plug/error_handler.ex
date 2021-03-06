defmodule Guardian.Plug.ErrorHandler do
  @moduledoc """
  A default error handler that can be used for failed authentication
  """

  @callback unauthenticated(Plug.t, Map.t) :: Plug.t
  @callback unauthorized(Plug.t, Map.t) :: Plug.t

  import Plug.Conn

  def unauthenticated(conn, _params) do
    respond(conn, response_type(conn), 401, "Unauthenticated")
  end

  def unauthorized(conn, _params) do
    respond(conn, response_type(conn), 403, "Unauthorized")
  end

  defp respond(conn, :json, status, msg) do
    try do
      conn
      |> configure_session(drop: true)
      |> put_resp_content_type("application/json")
      |> send_resp(status, Poison.encode!(%{errors: [msg]}))
    rescue ArgumentError ->
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(status, Poison.encode!(%{errors: [msg]}))
    end
  end

  defp respond(conn, :html, status, msg) do
    try do
      conn
      |> configure_session(drop: true)
      |> put_resp_content_type("text/plain")
      |> send_resp(status, msg)
    rescue ArgumentError ->
      conn
      |> put_resp_content_type("text/plain")
      |> send_resp(status, msg)
    end
  end

  defp response_type(conn) do
    accept = accept_header(conn)
    cond do
      Regex.match?(~r/json/, accept) -> :json
      true -> :html
    end
  end

  defp accept_header(conn)  do
    value = conn
      |> get_req_header("accept")
      |> List.first

    value || ""
  end
end
