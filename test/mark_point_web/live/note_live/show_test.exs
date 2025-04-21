defmodule MarkPointWeb.NoteLive.ShowTest do
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

    # Create a test note with markdown content
    markdown_content = """
    # Heading 1

    This is a paragraph with **bold** and *italic* text.

    ## Heading 2

    - List item 1
    - List item 2

    ```elixir
    defmodule Test do
      def hello do
        "world"
      end
    end
    ```

    > This is a blockquote
    """

    {:ok, note_id} = Notes.create_note("Markdown Test Note", markdown_content)

    on_exit(fn ->
      # Close and delete the test DETS table
      Notes.close()
      File.rm(@test_file)
    end)

    %{note_id: note_id}
  end

  test "displays note with rendered markdown", %{conn: conn, note_id: note_id} do
    {:ok, _view, html} = live(conn, ~p"/notes/#{note_id}")

    # Test that the note title is displayed
    assert html =~ "Markdown Test Note"

    # Test that markdown is rendered properly
    assert html =~ "<h1>"
    assert html =~ "<h2>"
    assert html =~ "<strong>bold</strong>"
    assert html =~ "<em>italic</em>"
    assert html =~ "<ul>"
    assert html =~ "List item 1"
    assert html =~ "<pre><code class=\"elixir\">"
    assert html =~ "<blockquote>"
  end

  test "shows error for non-existent note", %{conn: conn} do
    # Try to access a note that doesn't exist
    non_existent_id = 999999

    # Use follow_redirect to handle the redirect
    assert {:error, {:live_redirect, %{to: "/notes", flash: %{"error" => "Note not found"}}}} =
      live(conn, ~p"/notes/#{non_existent_id}")

    # Connect to the redirected page
    {:ok, _view, html} = live(conn, ~p"/notes")
    assert html =~ "Notes"
  end

  test "navigate back to index", %{conn: conn, note_id: note_id} do
    {:ok, view, _html} = live(conn, ~p"/notes/#{note_id}")

    # Click the "Back to Notes" link
    assert view
           |> element("a", "Back to Notes")
           |> render_click()

    # Check that we're redirected to the index page
    assert_redirect(view, ~p"/notes")
  end

  test "deletes a note", %{conn: conn, note_id: note_id} do
    # First, verify that the note exists
    assert {:ok, _} = Notes.get_note(note_id)

    {:ok, view, _html} = live(conn, ~p"/notes/#{note_id}")

    # Click the trash icon to show the confirmation dialog
    assert view
           |> element("button[phx-click='show_delete_confirmation']")
           |> render_click()

    # Click the Delete button in the confirmation dialog using a more specific selector
    assert view
           |> element("#delete-confirmation button.bg-red-500", "Delete")
           |> render_click()

    # Check that we're redirected to the notes list
    assert_redirect(view, ~p"/notes")

    # Verify note is gone from database with a brief wait for processing
    Process.sleep(100)
    assert {:error, :not_found} = Notes.get_note(note_id)
  end
end
