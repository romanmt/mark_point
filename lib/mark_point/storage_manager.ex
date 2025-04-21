defmodule MarkPoint.StorageManager do
  @moduledoc """
  Provides maintenance functions for the DETS storage.
  These functions can be run from the console to repair or manage data.
  """

  require Logger
  alias MarkPoint.Notes

  # Get the DETS file path from configuration based on environment
  defp dets_file_path do
    Application.get_env(:mark_point, :dets)[:file_path]
  end

  @doc """
  Repairs the DETS file and attempts to recover data.
  This will create a backup of the current file before attempting repair.
  Returns :ok on success, {:error, reason} on failure.

  Example:
      MarkPoint.StorageManager.repair_storage()
  """
  def repair_storage do
    Logger.info("Starting DETS file repair...")

    # Create a manual backup first
    backup_name = "manual_repair_#{System.system_time(:second)}"
    _ = create_named_backup(backup_name)

    Logger.info("Created backup before repair at #{dets_file_path()}_backup_#{backup_name}")

    # Now attempt repair
    result = Notes.repair()
    Logger.info("DETS file repair completed with result: #{inspect(result)}")
    result
  end

  @doc """
  Creates a backup of the DETS file.
  Returns :ok on success, {:error, reason} on failure.

  Example:
      MarkPoint.StorageManager.backup()
  """
  def backup do
    timestamp = DateTime.utc_now() |> DateTime.to_iso8601() |> String.replace(~r/[^\w]/, "_")
    create_named_backup(timestamp)
  end

  @doc """
  Creates a backup with a specific name.
  """
  def create_named_backup(name) do
    backup_path = "#{dets_file_path()}_backup_#{name}"

    Logger.info("Creating backup at #{backup_path}...")

    # Close DETS to ensure data is written
    Notes.close()

    # Copy the file
    result = case File.cp(dets_file_path(), backup_path) do
      :ok ->
        # Reopen DETS
        Notes.init()
        Logger.info("Backup created successfully")
        :ok
      {:error, reason} = error ->
        # Reopen DETS even if backup fails
        Notes.init()
        Logger.error("Backup failed: #{inspect(reason)}")
        error
    end

    result
  end

  @doc """
  Restores from a backup file.
  Takes the backup file path as an argument.
  Returns :ok on success, {:error, reason} on failure.

  Example:
      MarkPoint.StorageManager.restore("priv/notes_backup_2023_05_01_12_30_45")
  """
  def restore(backup_path) do
    Logger.info("Restoring from backup #{backup_path}...")

    # Close DETS
    Notes.close()

    # Copy the backup file over the current file
    result = case File.cp(backup_path, dets_file_path()) do
      :ok ->
        Notes.init()
        Logger.info("Restore completed successfully")
        :ok
      {:error, reason} = error ->
        Notes.init()
        Logger.error("Restore failed: #{inspect(reason)}")
        error
    end

    result
  end

  @doc """
  Lists all available backups.
  Returns a list of backup file paths.

  Example:
      MarkPoint.StorageManager.list_backups()
  """
  def list_backups do
    Path.wildcard("#{dets_file_path()}_backup_*")
  end

  @doc """
  Deletes backups older than the specified number of days.
  Returns the number of backups deleted.

  Example:
      MarkPoint.StorageManager.cleanup_old_backups(7) # Deletes backups older than 7 days
  """
  def cleanup_old_backups(days) do
    now = DateTime.utc_now()
    seconds_threshold = days * 24 * 60 * 60

    list_backups()
    |> Enum.filter(fn path ->
      case File.stat(path) do
        {:ok, %{mtime: mtime}} ->
          mtime_datetime = NaiveDateTime.from_erl!(mtime) |> DateTime.from_naive!("Etc/UTC")
          diff_seconds = DateTime.diff(now, mtime_datetime)
          diff_seconds > seconds_threshold
        _ ->
          false
      end
    end)
    |> Enum.map(fn path ->
      Logger.info("Deleting old backup: #{path}")
      File.rm(path)
    end)
    |> Enum.count()
  end
end
