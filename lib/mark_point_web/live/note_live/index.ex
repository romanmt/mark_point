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
    <div class="mx-auto max-w-5xl px-4 py-8">
      <div class="flex justify-between items-center mb-8 border-b pb-4">
        <h1 class="text-3xl font-bold text-gray-800">Notes</h1>
        <.link patch={~p"/notes/new"} class="bg-indigo-600 hover:bg-indigo-700 text-white py-2 px-4 rounded-md transition-colors duration-200 flex items-center gap-2 shadow-sm">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
          </svg>
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

      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <%= for note <- @notes do %>
          <div class="bg-white border border-gray-200 rounded-lg shadow-sm hover:shadow-md transition-all duration-200 overflow-hidden flex flex-col">
            <div class="p-5 flex-grow">
              <h2 class="text-xl font-semibold mb-3 text-gray-800 line-clamp-1"><%= note[:title] || "Untitled" %></h2>
              <div class="text-sm text-gray-500 mb-4 flex items-center">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                </svg>
                <%= if Map.has_key?(note, :created_at), do: Calendar.strftime(note.created_at, "%Y-%m-%d %H:%M"), else: "-" %>
              </div>
            </div>
            <div class="border-t bg-gray-50 px-5 py-3 flex justify-between items-center">
              <div class="flex space-x-2">
                <.link navigate={~p"/notes/#{note[:id] || 0}"} class="text-indigo-600 hover:text-indigo-800 flex items-center gap-1 text-sm font-medium">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                  </svg>
                  View
                </.link>
              </div>
              <div class="flex space-x-3">
                <.link patch={~p"/notes/#{note[:id] || 0}/edit"} class="text-indigo-600 hover:text-indigo-800">
                  <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                  </svg>
                </.link>
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
          </div>
        <% end %>
      </div>

      <%= if Enum.empty?(@notes) do %>
        <div class="text-center py-16 bg-gray-50 rounded-lg border border-gray-200 mt-4">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-12 w-12 mx-auto text-gray-400 mb-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
          </svg>
          <p class="text-gray-600 font-medium">No notes yet</p>
          <p class="text-gray-500 mt-1">Click "New Note" to create one</p>
        </div>
      <% end %>
    </div>
    """
  end
end
