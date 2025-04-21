defmodule MarkPointWeb.NoteLive.IndexTest do
  use MarkPointWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  alias MarkPoint.Notes

  setup do
    # Set up a test DETS table and create some test notes
    test_file = "priv/test_notes"
    File.rm(test_file)
    File.mkdir_p!(Path.dirname(test_file))

    # Open the test DETS table
    :dets.open_file(:notes, [type: :set, file: String.to_charlist(test_file)])

    # Create test notes
    {:ok, note1_id} = Notes.create_note("Test Note 1", "Content for test note 1")
    {:ok, note2_id} = Notes.create_note("Test Note 2", "Content for test note 2")

    on_exit(fn ->
      # Close and delete the test DETS table
      :dets.close(:notes)
      File.rm(test_file)
    end)

    %{note1_id: note1_id, note2_id: note2_id}
  end

  test "lists all notes", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/notes")

    # Test that the page renders correctly
    assert html =~ "Notes"
    assert html =~ "Test Note 1"
    assert html =~ "Test Note 2"
  end

  test "shows new note modal", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/notes")

    # Click the "New Note" button
    assert view
           |> element("a", "New Note")
           |> render_click() =~ "New Note"

    # Check that we're on the new note form
    assert_patch(view, ~p"/notes/new")

    # Check that the form has the expected fields
    assert view
           |> form("#note-form")
           |> render() =~ "Title"

    assert view
           |> form("#note-form")
           |> render() =~ "Content (Markdown)"
  end

  test "creates a new note", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/notes/new")

    # Submit the form with valid data
    assert view
           |> form("#note-form", %{
             "title" => "New Test Note",
             "content" => "This is a **test** note with markdown"
           })
           |> render_submit()

    # Check that we're redirected back to the index page
    assert_redirect(view, ~p"/notes")

    # Follow the redirect and check the note is displayed
    {:ok, _view, html} = live(conn, ~p"/notes")
    assert html =~ "New Test Note"
  end
end
