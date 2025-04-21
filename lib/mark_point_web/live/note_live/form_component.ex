defmodule MarkPointWeb.NoteLive.FormComponent do
  use MarkPointWeb, :live_component

  alias MarkPoint.Notes

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h2 class="text-lg font-semibold mb-4"><%= @title %></h2>
      <.form
        for={@form}
        id="note-form"
        phx-target={@myself}
        phx-submit="save"
      >
        <div class="space-y-4">
          <div>
            <.input
              field={@form[:title]}
              type="text"
              label="Title"
              required
              placeholder="Enter note title"
            />
          </div>
          <div>
            <.input
              field={@form[:content]}
              type="textarea"
              label="Content (Markdown)"
              required
              placeholder="Enter note content using Markdown"
              rows="10"
            />
          </div>
          <%= if @note && Map.has_key?(@note, :id) do %>
            <input type="hidden" name="note_id" value={@note[:id]} />
          <% end %>
          <div class="flex justify-end">
            <.button type="submit" phx-disable-with="Saving...">
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
