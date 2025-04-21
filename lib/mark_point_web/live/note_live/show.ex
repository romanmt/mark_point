defmodule MarkPointWeb.NoteLive.Show do
  use MarkPointWeb, :live_view

  alias MarkPoint.Notes

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    case Notes.get_note(String.to_integer(id)) do
      {:ok, note} ->
        {:ok, assign(socket, :note, note)}
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
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-3xl">
      <div class="mb-4">
        <.link navigate={~p"/notes"} class="text-blue-500 hover:text-blue-700">
          &larr; Back to Notes
        </.link>
      </div>

      <div class="bg-white rounded-lg shadow-md p-6">
        <h1 class="text-2xl font-bold mb-2"><%= @note.title %></h1>

        <div class="text-sm text-gray-500 mb-6">
          <div>Created: <%= Calendar.strftime(@note.created_at, "%Y-%m-%d %H:%M") %></div>
          <div>Updated: <%= Calendar.strftime(@note.updated_at, "%Y-%m-%d %H:%M") %></div>
        </div>

        <div class="prose max-w-none">
          <%= raw Earmark.as_html!(@note.content) %>
        </div>
      </div>
    </div>
    """
  end
end
