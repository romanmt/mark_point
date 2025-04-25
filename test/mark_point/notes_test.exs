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

  # Helper to clear all notes
  defp clear_all_notes do
    for note <- Notes.list_notes() do
      Notes.delete_note(note.id)
    end
  end

  test "create_note/2 creates a note with valid data" do
    clear_all_notes()

    title = "Test Note"
    content = "This is a test note with *markdown*"

    assert {:ok, note_id} = Notes.create_note(title, content)
    assert is_integer(note_id)
  end

  test "get_note/1 retrieves a note by id" do
    clear_all_notes()

    title = "Test Note for Get"
    content = "Test content for get"

    {:ok, note_id} = Notes.create_note(title, content)

    assert {:ok, note} = Notes.get_note(note_id)
    assert note.id == note_id
    assert note.title == title
    assert note.content == content
  end

  test "delete_note/1 deletes a note by id" do
    clear_all_notes()

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
    clear_all_notes()

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

  test "notes are created with incremental order values" do
    clear_all_notes()

    {:ok, note1_id} = Notes.create_note("First Note", "Content 1")
    {:ok, note2_id} = Notes.create_note("Second Note", "Content 2")
    {:ok, note3_id} = Notes.create_note("Third Note", "Content 3")

    {:ok, note1} = Notes.get_note(note1_id)
    {:ok, note2} = Notes.get_note(note2_id)
    {:ok, note3} = Notes.get_note(note3_id)

    assert note1.order == 1
    assert note2.order == 2
    assert note3.order == 3
  end

  test "list_notes/0 returns notes sorted by order" do
    clear_all_notes()

    # Create notes in a specific order
    {:ok, note1_id} = Notes.create_note("Note 1", "Content 1") # order 1
    {:ok, _note2_id} = Notes.create_note("Note 2", "Content 2") # order 2
    {:ok, note3_id} = Notes.create_note("Note 3", "Content 3") # order 3

    # Reorder them (note3 first, note1 last)
    Notes.update_note_order(note3_id, 1)
    Notes.update_note_order(note1_id, 3)

    # Get the sorted notes
    notes = Notes.list_notes()

    # Extract titles in order
    titles = Enum.map(notes, & &1.title)

    # Verify the order of notes
    assert Enum.at(titles, 0) == "Note 3"
    assert Enum.at(titles, 1) == "Note 2"
    assert Enum.at(titles, 2) == "Note 1"
  end

  test "update_note_order/2 updates a note's order" do
    clear_all_notes()

    {:ok, note_id} = Notes.create_note("Test Note", "Content")
    {:ok, note} = Notes.get_note(note_id)

    # The order should be 1 (first note)
    assert note.order == 1

    # Update the order to 100
    {:ok, updated_note} = Notes.update_note_order(note_id, 100)
    assert updated_note.order == 100

    # Verify the change persisted
    {:ok, retrieved_note} = Notes.get_note(note_id)
    assert retrieved_note.order == 100
  end
end
