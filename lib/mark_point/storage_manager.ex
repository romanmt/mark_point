defmodule MarkPoint.StorageManager do
  @moduledoc """
  Provides maintenance functions for the DETS storage.
  These functions can be run from the console to repair or manage data.
  """

  require Logger
  alias MarkPoint.Notes

  @dets_file_path "priv/notes"

  @doc """
  Repairs the DETS file and attempts to recover data.
  Returns :ok on success, {:error, reason} on failure.

  Example:
      MarkPoint.StorageManager.repair_storage()
  """
  def repair_storage do
    Logger.info("Starting DETS file repair...")
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
    backup_path = "#{@dets_file_path}_backup_#{timestamp}"

    Logger.info("Creating backup at #{backup_path}...")

    # Close DETS to ensure data is written
    Notes.close()

    # Copy the file
    result = case File.cp(@dets_file_path, backup_path) do
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
    result = case File.cp(backup_path, @dets_file_path) do
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
    Path.wildcard("#{@dets_file_path}_backup_*")
  end
end
