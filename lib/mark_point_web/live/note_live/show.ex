defmodule MarkPointWeb.NoteLive.Show do
  use MarkPointWeb, :live_view

  alias MarkPoint.Notes
  alias MarkPointWeb.ConfirmationComponent
  alias MarkPointWeb.NoteLive.FormComponent

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    case Notes.get_note(String.to_integer(id)) do
      {:ok, note} ->
        {:ok, assign(socket, note: note, show_delete_confirmation: false)}
      {:error, :not_found} ->
        {:ok,
          socket
          |> put_flash(:error, "Note not found")
          |> push_navigate(to: ~p"/notes")}
      {:error, reason} ->
        {:ok,
          socket
          |> put_flash(:error, "Error loading note: #{reason}")
          |> push_navigate(to: ~p"/notes")}
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :show, _params) do
    socket
    |> assign(:page_title, "View Note")
  end

  defp apply_action(socket, :edit, _params) do
    socket
    |> assign(:page_title, "Edit Note")
  end

  @impl true
  def handle_event("show_delete_confirmation", _, socket) do
    {:noreply, assign(socket, show_delete_confirmation: true)}
  end

  @impl true
  def handle_event("cancel_delete", _, socket) do
    {:noreply, assign(socket, show_delete_confirmation: false)}
  end

  @impl true
  def handle_event("delete_note", _, socket) do
    id = socket.assigns.note.id

    case Notes.delete_note(id) do
      :ok ->
        {:noreply,
         socket
         |> put_flash(:info, "Note deleted successfully")
         |> push_navigate(to: ~p"/notes")}

      {:error, reason} ->
        {:noreply,
         socket
         |> put_flash(:error, "Error deleting note: #{reason}")
         |> assign(:show_delete_confirmation, false)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-3xl">
      <div class="mb-4 flex justify-between items-center">
        <.link navigate={~p"/notes"} class="text-blue-500 hover:text-blue-700">
          &larr; Back to Notes
        </.link>

        <div class="flex space-x-2">
          <.link
            patch={~p"/notes/#{@note.id}/edit/from_show"}
            class="bg-blue-500 hover:bg-blue-700 text-white py-1 px-3 rounded flex items-center gap-1"
          >
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
            </svg>
            <span>Edit</span>
          </.link>

          <button
            phx-click="show_delete_confirmation"
            class="bg-red-500 hover:bg-red-700 text-white py-1 px-3 rounded flex items-center gap-1"
          >
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
            </svg>
            <span>Delete</span>
          </button>
        </div>
      </div>

      <%= if @live_action == :edit do %>
        <.modal id="note-modal" show on_cancel={JS.patch(~p"/notes/#{@note.id}")}>
          <.live_component
            module={FormComponent}
            id={@note.id}
            title="Edit Note"
            action={@live_action}
            note={@note}
            navigate={~p"/notes/#{@note.id}"}
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

      <div class="bg-white rounded-lg shadow-md p-6">
        <h1 class="text-2xl font-bold mb-2"><%= @note.title %></h1>

        <div class="text-sm text-gray-500 mb-6">
          <div>Created: <%= Calendar.strftime(@note.created_at, "%Y-%m-%d %H:%M") %></div>
          <div>Updated: <%= Calendar.strftime(@note.updated_at, "%Y-%m-%d %H:%M") %></div>
        </div>

        <div class="prose prose-sm sm:prose lg:prose-lg xl:prose-xl mx-auto">
          <%= raw Earmark.as_html!(@note.content) %>
        </div>
      </div>
    </div>
    """
  end
end
