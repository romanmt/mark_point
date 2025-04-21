defmodule MarkPointWeb.NoteLive.IndexTest do
  use MarkPointWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  alias MarkPoint.Notes

  # Get the test-specific DETS file path
  @test_file Application.compile_env(:mark_point, :dets)[:file_path]

  setup do
    # Make sure the DETS file doesn't exist at the start of each test
    File.rm(@test_file)
    File.mkdir_p!(Path.dirname(@test_file))

    # Initialize the test DETS table
    Notes.init()

    # Create test notes
    {:ok, note1_id} = Notes.create_note("Test Note 1", "Content for test note 1")
    {:ok, note2_id} = Notes.create_note("Test Note 2", "Content for test note 2")

    on_exit(fn ->
      # Close and delete the test DETS table
      Notes.close()
      File.rm(@test_file)
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

  test "deletes a note", %{conn: conn, note1_id: note1_id} do
    # First, verify that the note exists
    assert {:ok, _} = Notes.get_note(note1_id)

    {:ok, view, _html} = live(conn, ~p"/notes")

    # Click the trash icon to show the confirmation dialog
    assert view
           |> element("button[phx-click='show_delete_confirmation'][phx-value-id='#{note1_id}']")
           |> render_click()

    # Click the Delete button in the confirmation dialog
    assert view
           |> element("#delete-confirmation button.bg-red-500", "Delete")
           |> render_click()

    # Verify note is gone from database with a brief wait for processing
    Process.sleep(100)
    assert {:error, :not_found} = Notes.get_note(note1_id)
  end
end
