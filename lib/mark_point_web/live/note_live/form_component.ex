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
    changeset = %{title: "", content: ""}

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("save", %{"title" => title, "content" => content}, socket) do
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
      "title" => Map.get(attrs, :title, ""),
      "content" => Map.get(attrs, :content, "")
    })

    assign(socket, form: form)
  end
end
