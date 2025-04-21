defmodule MarkPoint.Notes do
  @moduledoc """
  The Notes context.
  Handles creation, storage, and retrieval of notes using DETS.
  """

  @table_name :notes
  @dets_file_path "priv/notes"

  @doc """
  Initializes the DETS table for notes.
  """
  def init do
    File.mkdir_p!(Path.dirname(@dets_file_path))

    case :dets.open_file(@table_name, [type: :set, file: String.to_charlist(@dets_file_path)]) do
      {:ok, @table_name} ->
        {:ok, @table_name}
      {:error, reason} ->
        {:error, "Failed to open DETS table: #{inspect(reason)}"}
    end
  end

  @doc """
  Creates a new note with the given title and content.
  Returns {:ok, note_id} on success, {:error, reason} on failure.
  """
  def create_note(title, content) do
    note_id = generate_id()
    note = %{
      id: note_id,
      title: title,
      content: content,
      created_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now()
    }

    case :dets.insert(@table_name, {note_id, note}) do
      :ok -> {:ok, note_id}
      {:error, reason} -> {:error, "Failed to create note: #{inspect(reason)}"}
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
  Lists all notes.
  Returns a list of notes.
  """
  def list_notes do
    :dets.match_object(@table_name, {:_, :_})
    |> Enum.map(fn {_, note} -> note end)
    |> Enum.sort(fn a, b ->
      DateTime.compare(a.updated_at, b.updated_at) == :gt
    end)
  end

  @doc """
  Generates a unique ID for a note.
  """
  defp generate_id do
    System.unique_integer([:positive, :monotonic])
  end

  @doc """
  Ensures the DETS table is properly closed on application shutdown.
  """
  def close do
    :dets.close(@table_name)
  end
end
