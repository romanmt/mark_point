defmodule MarkPointWeb.NoteLive.Index do
  use MarkPointWeb, :live_view

  alias MarkPoint.Notes
  alias MarkPointWeb.NoteLive.FormComponent
  alias MarkPointWeb.ConfirmationComponent

  @impl true
  def mount(_params, _session, socket) do
    notes = Notes.list_notes()
    {:ok, assign(socket, notes: notes, show_delete_confirmation: false, note_to_delete: nil)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Notes")
    |> assign(:note, nil)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Note")
    |> assign(:note, %{})
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    case Notes.get_note(String.to_integer(id)) do
      {:ok, note} ->
        socket
        |> assign(:page_title, "Edit Note")
        |> assign(:note, note)
      {:error, _reason} ->
        socket
        |> put_flash(:error, "Note not found")
        |> push_navigate(to: ~p"/notes")
    end
  end

  @impl true
  def handle_event("show_delete_confirmation", %{"id" => id}, socket) do
    {:noreply, assign(socket, show_delete_confirmation: true, note_to_delete: id)}
  end

  @impl true
  def handle_event("cancel_delete", _, socket) do
    {:noreply, assign(socket, show_delete_confirmation: false, note_to_delete: nil)}
  end

  @impl true
  def handle_event("delete_note", _, socket) do
    id = String.to_integer(socket.assigns.note_to_delete)

    case Notes.delete_note(id) do
      :ok ->
        notes = Notes.list_notes()

        {:noreply,
         socket
         |> put_flash(:info, "Note deleted successfully")
         |> assign(:notes, notes)
         |> assign(:show_delete_confirmation, false)
         |> assign(:note_to_delete, nil)}

      {:error, reason} ->
        {:noreply,
         socket
         |> put_flash(:error, "Error deleting note: #{reason}")
         |> assign(:show_delete_confirmation, false)
         |> assign(:note_to_delete, nil)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-4xl">
      <div class="flex justify-between items-center mb-6">
        <h1 class="text-2xl font-bold">Notes</h1>
        <.link patch={~p"/notes/new"} class="bg-blue-500 hover:bg-blue-700 text-white py-2 px-4 rounded">
          New Note
        </.link>
      </div>

      <%= if @live_action in [:new, :edit] do %>
        <.modal id="note-modal" show on_cancel={JS.navigate(~p"/notes")}>
          <.live_component
            module={FormComponent}
            id={@note && Map.get(@note, :id, "new-note") || "new-note"}
            title={@page_title}
            action={@live_action}
            note={@note || %{}}
            navigate={~p"/notes"}
          />
        </.modal>
      <% end %>

      <ConfirmationComponent.confirmation
        id="delete-confirmation"
        show={@show_delete_confirmation}
        on_confirm={JS.push("delete_note")}
        on_cancel={JS.push("cancel_delete")}
      >
        <:title>Confirm Deletion</:title>
        <:content>Are you sure you want to delete this note? This action cannot be undone.</:content>
        <:confirm_button>Delete</:confirm_button>
        <:cancel_button>Cancel</:cancel_button>
      </ConfirmationComponent.confirmation>

      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        <%= for note <- @notes do %>
          <div class="border p-4 rounded shadow-sm hover:shadow-md transition-shadow">
            <h2 class="text-xl font-semibold mb-2"><%= note[:title] || "Untitled" %></h2>
            <div class="text-sm text-gray-500 mb-2">
              Created: <%= if Map.has_key?(note, :created_at), do: Calendar.strftime(note.created_at, "%Y-%m-%d %H:%M"), else: "-" %>
            </div>
            <div class="flex justify-between items-center">
              <div class="flex space-x-2">
                <.link navigate={~p"/notes/#{note[:id] || 0}"} class="text-blue-500 hover:text-blue-700">
                  View
                </.link>
                <.link patch={~p"/notes/#{note[:id] || 0}/edit"} class="text-blue-500 hover:text-blue-700">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                  </svg>
                </.link>
              </div>
              <button
                phx-click="show_delete_confirmation"
                phx-value-id={note[:id] || 0}
                class="text-red-500 hover:text-red-700"
              >
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                </svg>
              </button>
            </div>
          </div>
        <% end %>
      </div>

      <%= if Enum.empty?(@notes) do %>
        <div class="text-center py-8 text-gray-500">
          <p>No notes yet. Click "New Note" to create one.</p>
        </div>
      <% end %>
    </div>
    """
  end
end
