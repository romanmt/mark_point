defmodule MarkPointWeb.ConfirmationComponent do
  use Phoenix.Component

  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :on_confirm, :any, required: true
  attr :on_cancel, :any, default: %{}
  slot :title
  slot :content
  slot :confirm_button
  slot :cancel_button

  def confirmation(assigns) do
    ~H"""
    <div
      id={@id}
      class="fixed inset-0 z-50 flex items-center justify-center"
      style={if @show, do: "display: flex;", else: "display: none;"}
    >
      <div class="fixed inset-0 bg-gray-900 opacity-50" phx-click={@on_cancel}></div>
      <div class="bg-white rounded-lg shadow-lg p-6 z-10 max-w-md w-full mx-4">
        <div class="mb-4 text-lg font-semibold">
          <%= render_slot(@title) || "Confirm Action" %>
        </div>
        <div class="mb-6">
          <%= render_slot(@content) || "Are you sure you want to proceed with this action?" %>
        </div>
        <div class="flex justify-end space-x-3">
          <button
            phx-click={@on_cancel}
            class="px-4 py-2 text-gray-700 bg-gray-200 rounded hover:bg-gray-300"
          >
            <%= render_slot(@cancel_button) || "Cancel" %>
          </button>
          <button
            phx-click={@on_confirm}
            class="px-4 py-2 text-white bg-red-500 rounded hover:bg-red-600"
          >
            <%= render_slot(@confirm_button) || "Confirm" %>
          </button>
        </div>
      </div>
    </div>
    """
  end
end
