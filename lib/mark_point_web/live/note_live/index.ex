defmodule MarkPointWeb.NoteLive.Index do
  use MarkPointWeb, :live_view

  alias MarkPoint.Notes
  alias MarkPointWeb.NoteLive.FormComponent

  @impl true
  def mount(_params, _session, socket) do
    notes = Notes.list_notes()
    {:ok, assign(socket, :notes, notes)}
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

      <%= if @live_action in [:new] do %>
        <.modal id="note-modal" show on_cancel={JS.navigate(~p"/notes")}>
          <.live_component
            module={FormComponent}
            id="new-note"
            title="New Note"
            action={@live_action}
            note={@note}
            navigate={~p"/notes"}
          />
        </.modal>
      <% end %>

      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        <%= for note <- @notes do %>
          <div class="border p-4 rounded shadow-sm hover:shadow-md transition-shadow">
            <h2 class="text-xl font-semibold mb-2"><%= note.title %></h2>
            <div class="text-sm text-gray-500 mb-2">
              Created: <%= Calendar.strftime(note.created_at, "%Y-%m-%d %H:%M") %>
            </div>
            <.link navigate={~p"/notes/#{note.id}"} class="text-blue-500 hover:text-blue-700">
              View Note
            </.link>
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
