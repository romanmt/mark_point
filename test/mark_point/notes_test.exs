defmodule MarkPoint.NotesTest do
  use ExUnit.Case, async: false
  alias MarkPoint.Notes

  # Get the test-specific DETS file path
  @test_file Application.compile_env(:mark_point, :dets)[:file_path]

  setup do
    # Make sure the DETS file doesn't exist at the start of each test
    File.rm(@test_file)
    File.mkdir_p!(Path.dirname(@test_file))

    # Initialize the test DETS table
    Notes.init()

    on_exit(fn ->
      # Close and delete the test DETS table
      Notes.close()
      File.rm(@test_file)
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

  test "delete_note/1 deletes a note by id" do
    title = "Test Note for Delete"
    content = "Test content for delete"

    {:ok, note_id} = Notes.create_note(title, content)

    # Verify the note exists
    assert {:ok, _note} = Notes.get_note(note_id)

    # Delete the note
    assert :ok = Notes.delete_note(note_id)

    # Verify the note no longer exists
    assert {:error, :not_found} = Notes.get_note(note_id)
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
