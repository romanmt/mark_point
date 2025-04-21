defmodule MarkPoint.BackupScheduler do
  @moduledoc """
  A GenServer that periodically backs up the DETS database.
  """
  use GenServer
  require Logger
  alias MarkPoint.StorageManager

  # Backup interval in milliseconds (default: 1 hour)
  @backup_interval 60 * 60 * 1000

  # How many days to keep backups before cleanup (default: 7 days)
  @backup_retention_days 7

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    # Schedule the first backup after 5 minutes
    Process.send_after(self(), :create_backup, 5 * 60 * 1000)

    # Also schedule cleanup of old backups after 10 minutes
    Process.send_after(self(), :cleanup_old_backups, 10 * 60 * 1000)

    {:ok, %{last_backup: nil, last_cleanup: nil}}
  end

  @impl true
  def handle_info(:create_backup, state) do
    Logger.info("Running scheduled backup...")
    result = StorageManager.backup()

    new_state = case result do
      :ok -> %{state | last_backup: DateTime.utc_now()}
      _ -> state
    end

    # Schedule the next backup
    Process.send_after(self(), :create_backup, @backup_interval)
    {:noreply, new_state}
  end

  @impl true
  def handle_info(:cleanup_old_backups, state) do
    Logger.info("Running scheduled backup cleanup...")
    deleted_count = StorageManager.cleanup_old_backups(@backup_retention_days)
    Logger.info("Deleted #{deleted_count} old backups")

    # Schedule the next cleanup (once a day)
    Process.send_after(self(), :cleanup_old_backups, 24 * 60 * 60 * 1000)

    {:noreply, %{state | last_cleanup: DateTime.utc_now()}}
  end

  @doc """
  Get the timestamp of the last successful backup.
  """
  def last_backup do
    GenServer.call(__MODULE__, :last_backup)
  end

  @doc """
  Get the timestamp of the last backup cleanup.
  """
  def last_cleanup do
    GenServer.call(__MODULE__, :last_cleanup)
  end

  @impl true
  def handle_call(:last_backup, _from, state) do
    {:reply, state.last_backup, state}
  end

  @impl true
  def handle_call(:last_cleanup, _from, state) do
    {:reply, state.last_cleanup, state}
  end

  @doc """
  Manually trigger a backup.
  """
  def backup_now do
    GenServer.cast(__MODULE__, :backup_now)
  end

  @doc """
  Manually trigger a cleanup of old backups.
  """
  def cleanup_now do
    GenServer.cast(__MODULE__, :cleanup_now)
  end

  @impl true
  def handle_cast(:backup_now, state) do
    Logger.info("Running manual backup...")
    result = StorageManager.backup()

    new_state = case result do
      :ok -> %{state | last_backup: DateTime.utc_now()}
      _ -> state
    end

    {:noreply, new_state}
  end

  @impl true
  def handle_cast(:cleanup_now, state) do
    Logger.info("Running manual backup cleanup...")
    deleted_count = StorageManager.cleanup_old_backups(@backup_retention_days)
    Logger.info("Deleted #{deleted_count} old backups")

    {:noreply, %{state | last_cleanup: DateTime.utc_now()}}
  end
end
