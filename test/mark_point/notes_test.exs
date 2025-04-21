defmodule MarkPoint.NotesTest do
  use ExUnit.Case, async: false
  alias MarkPoint.Notes

  setup do
    # Set up a test DETS table
    test_file = "priv/test_notes"
    File.rm(test_file)
    File.mkdir_p!(Path.dirname(test_file))

    # Open the test DETS table
    :dets.open_file(:notes, [type: :set, file: String.to_charlist(test_file)])

    on_exit(fn ->
      # Close and delete the test DETS table
      :dets.close(:notes)
      File.rm(test_file)
    end)

    :ok
  end

  test "create_note/2 creates a note with valid data" do
    title = "Test Note"
    content = "This is a test note with *markdown*"

    assert {:ok, note_id} = Notes.create_note(title, content)
    assert is_integer(note_id)
  end

  test "get_note/1 retrieves a note by id" do
    title = "Test Note for Get"
    content = "Test content for get"

    {:ok, note_id} = Notes.create_note(title, content)

    assert {:ok, note} = Notes.get_note(note_id)
    assert note.id == note_id
    assert note.title == title
    assert note.content == content
  end

  test "list_notes/0 returns all notes" do
    # Create a few test notes
    Notes.create_note("Note 1", "Content 1")
    Notes.create_note("Note 2", "Content 2")
    Notes.create_note("Note 3", "Content 3")

    notes = Notes.list_notes()

    assert length(notes) >= 3
    assert Enum.any?(notes, fn note -> note.title == "Note 1" end)
    assert Enum.any?(notes, fn note -> note.title == "Note 2" end)
    assert Enum.any?(notes, fn note -> note.title == "Note 3" end)
  end
end
