defmodule MarkPoint.Notes do
  @moduledoc """
  The Notes context.
  Handles creation, storage, and retrieval of notes using DETS.
  """

  @table_name :notes

  # Get the DETS file path from configuration based on environment
  defp dets_file_path do
    Application.get_env(:mark_point, :dets)[:file_path]
  end

  @doc """
  Initializes the DETS table for notes.
  """
  def init do
    File.mkdir_p!(Path.dirname(dets_file_path()))

    case :dets.open_file(@table_name, [type: :set, file: String.to_charlist(dets_file_path())]) do
      {:ok, @table_name} ->
        {:ok, @table_name}
      {:error, reason} ->
        # Try to repair the file if it's corrupted
        case reason do
          {:premature_eof, _} ->
            # Try to delete and recreate the file
            File.rm(dets_file_path())
            init()
          _ ->
            {:error, "Failed to open DETS table: #{inspect(reason)}"}
        end
    end
  end

  @doc """
  Creates a new note with the given title and content.
  Returns {:ok, note_id} on success, {:error, reason} on failure.
  """
  def create_note(title, content) do
    note_id = generate_id()

    # Get the highest order value and add 1, or start at 0 if no notes exist
    highest_order = get_highest_order() || 0

    note = %{
      id: note_id,
      title: title,
      content: content,
      order: highest_order + 1,
      created_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now()
    }

    case :dets.insert(@table_name, {note_id, note}) do
      :ok ->
        # Sync to disk to prevent corruption
        :dets.sync(@table_name)
        # Broadcast note creation to all clients
        Phoenix.PubSub.broadcast(MarkPoint.PubSub, "notes", {:note_created, note})
        {:ok, note_id}
      {:error, reason} ->
        {:error, "Failed to create note: #{inspect(reason)}"}
    end
  end

  # Helper function to get the highest order value from existing notes
  defp get_highest_order do
    case :dets.match_object(@table_name, {:_, :_}) do
      {:error, _reason} -> nil
      notes when is_list(notes) and notes == [] -> nil
      notes when is_list(notes) ->
        notes
        |> Enum.map(fn {_, note} -> Map.get(note, :order, 0) end)
        |> Enum.max(fn -> 0 end)
    end
  end

  @doc """
  Updates an existing note with the given title and content.
  Returns {:ok, note} on success, {:error, reason} on failure.
  """
  def update_note(id, title, content) do
    case get_note(id) do
      {:ok, note} ->
        updated_note = %{
          note |
          title: title,
          content: content,
          updated_at: DateTime.utc_now()
        }

        case :dets.insert(@table_name, {id, updated_note}) do
          :ok ->
            # Sync to disk to prevent corruption
            :dets.sync(@table_name)
            # Broadcast note update to all clients
            Phoenix.PubSub.broadcast(MarkPoint.PubSub, "notes", {:note_updated, updated_note})
            {:ok, updated_note}
          {:error, reason} ->
            {:error, "Failed to update note: #{inspect(reason)}"}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Gets a note by ID.
  Returns {:ok, note} on success, {:error, reason} on failure.
  """
  def get_note(id) do
    case :dets.lookup(@table_name, id) do
      [{^id, note}] -> {:ok, note}
      [] -> {:error, :not_found}
      {:error, reason} -> {:error, "Failed to get note: #{inspect(reason)}"}
    end
  end

  @doc """
  Deletes a note by ID.
  Returns :ok on success, {:error, reason} on failure.
  """
  def delete_note(id) do
    # Get the note before deleting it for the broadcast
    note_to_delete = case get_note(id) do
      {:ok, note} -> note
      _ -> nil
    end

    case :dets.delete(@table_name, id) do
      :ok ->
        # Sync to disk to prevent corruption
        :dets.sync(@table_name)
        # Broadcast note deletion to all clients if we have the note
        if note_to_delete do
          Phoenix.PubSub.broadcast(MarkPoint.PubSub, "notes", {:note_deleted, note_to_delete})
        end
        :ok
      {:error, reason} ->
        {:error, "Failed to delete note: #{inspect(reason)}"}
    end
  end

  @doc """
  Lists all notes.
  Returns a list of notes sorted by order.
  """
  def list_notes do
    case :dets.match_object(@table_name, {:_, :_}) do
      {:error, reason} ->
        # Handle error case, return empty list and log the error
        require Logger
        Logger.error("Failed to list notes: #{inspect(reason)}")
        []
      notes when is_list(notes) ->
        notes
        |> Enum.map(fn {_, note} -> note end)
        |> Enum.sort_by(fn note -> Map.get(note, :order, 0) end, :asc)
    end
  end

  # Generates a unique ID for a note.
  defp generate_id do
    System.unique_integer([:positive, :monotonic])
  end

  @doc """
  Ensures the DETS table is properly closed on application shutdown.
  """
  def close do
    # Always sync before closing to prevent corruption
    :dets.sync(@table_name)
    :dets.close(@table_name)
  end

  @doc """
  Repairs the DETS file if it's corrupted.
  """
  def repair do
    # Try to close the table first
    _ = :dets.close(@table_name)

    # Since :dets.repair_file/2 isn't available, we'll use a simpler approach
    # by deleting and recreating the file if it exists
    if File.exists?(dets_file_path()) do
      # Create a backup before deleting, just in case
      backup_path = "#{dets_file_path()}_backup_#{System.system_time(:second)}"
      _ = File.cp(dets_file_path(), backup_path)

      # Delete and recreate
      File.rm(dets_file_path())
    end

    # Initialize a new DETS file
    init()
  end

  @doc """
  Updates the order of a note.
  Returns {:ok, updated_note} on success, {:error, reason} on failure.
  """
  def update_note_order(id, new_order) when is_integer(new_order) do
    case get_note(id) do
      {:ok, note} ->
        updated_note = Map.put(note, :order, new_order)

        case :dets.insert(@table_name, {id, updated_note}) do
          :ok ->
            # Sync to disk to prevent corruption
            :dets.sync(@table_name)
            # Broadcast note order update to all clients
            Phoenix.PubSub.broadcast(MarkPoint.PubSub, "notes", {:note_order_updated, updated_note})
            {:ok, updated_note}
          {:error, reason} ->
            {:error, "Failed to update note order: #{inspect(reason)}"}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end
end
