defmodule MarkPoint.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # Initialize DETS for notes storage
    case MarkPoint.Notes.init() do
      {:ok, _} -> :ok
      {:error, reason} ->
        IO.warn("Failed to initialize notes storage: #{reason}")
    end

    children = [
      MarkPointWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:mark_point, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: MarkPoint.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: MarkPoint.Finch},
      # Start a worker by calling: MarkPoint.Worker.start_link(arg)
      # {MarkPoint.Worker, arg},
      # Start to serve requests, typically the last entry
      MarkPointWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MarkPoint.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    MarkPointWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  @impl true
  def stop(_state) do
    # Ensure DETS is properly closed on application shutdown
    MarkPoint.Notes.close()
    :ok
  end
end
