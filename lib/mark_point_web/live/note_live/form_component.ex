defmodule MarkPointWeb.NoteLive.FormComponent do
  use MarkPointWeb, :live_component

  alias MarkPoint.Notes

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-white p-6 rounded-lg">
      <h2 class="text-xl font-bold text-gray-800 mb-6 pb-2 border-b"><%= @title %></h2>
      <.form
        for={@form}
        id="note-form"
        phx-target={@myself}
        phx-submit="save"
        class="space-y-6"
      >
        <div class="space-y-4">
          <div>
            <.input
              field={@form[:title]}
              type="text"
              label="Title"
              required
              placeholder="Enter note title"
              class="w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring focus:ring-indigo-200 focus:ring-opacity-50"
            />
          </div>
          <div>
            <.input
              field={@form[:content]}
              type="textarea"
              label="Content (Markdown)"
              required
              placeholder="Enter note content using Markdown"
              rows="12"
              class="w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring focus:ring-indigo-200 focus:ring-opacity-50 font-mono"
            />
            <p class="mt-1 text-sm text-gray-500">
              Supports Markdown formatting: **bold**, _italic_, `code`, [links](url), and more.
            </p>
          </div>
          <%= if @note && Map.has_key?(@note, :id) do %>
            <input type="hidden" name="note_id" value={@note[:id]} />
          <% end %>
          <div class="flex justify-end pt-4">
            <.button type="submit" class="bg-indigo-600 hover:bg-indigo-700 text-white py-2 px-4 rounded-md transition-colors duration-200" phx-disable-with="Saving...">
              Save Note
            </.button>
          </div>
        </div>
      </.form>
    </div>
    """
  end

  @impl true
  def update(%{note: note} = assigns, socket) do
    changeset = if note && Map.has_key?(note, :id) do
      # Editing existing note
      %{
        id: note.id,
        title: note.title,
        content: note.content
      }
    else
      # Creating new note
      %{title: "", content: ""}
    end

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("save", %{"note_id" => id, "title" => title, "content" => content}, socket) do
    # Update existing note
    id = String.to_integer(id)
    case Notes.update_note(id, title, content) do
      {:ok, _updated_note} ->
        {:noreply,
         socket
         |> put_flash(:info, "Note updated successfully")
         |> push_navigate(to: socket.assigns.navigate)}

      {:error, reason} ->
        {:noreply,
         socket
         |> put_flash(:error, "Error updating note: #{reason}")
         |> assign_form(%{id: id, title: title, content: content})}
    end
  end

  @impl true
  def handle_event("save", %{"title" => title, "content" => content}, socket) do
    # Create new note
    case Notes.create_note(title, content) do
      {:ok, _note_id} ->
        {:noreply,
         socket
         |> put_flash(:info, "Note created successfully")
         |> push_navigate(to: socket.assigns.navigate)}

      {:error, reason} ->
        {:noreply,
         socket
         |> put_flash(:error, "Error creating note: #{reason}")
         |> assign_form(%{title: title, content: content})}
    end
  end

  defp assign_form(socket, attrs) do
    form = to_form(%{
      "id" => Map.get(attrs, :id, nil),
      "title" => Map.get(attrs, :title, ""),
      "content" => Map.get(attrs, :content, "")
    })

    assign(socket, form: form)
  end
end
