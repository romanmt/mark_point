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
      <div class="fixed inset-0 bg-gray-900 bg-opacity-75 transition-opacity" phx-click={@on_cancel}></div>
      <div class="bg-white rounded-lg shadow-xl p-6 z-10 max-w-md w-full mx-4 transform transition-all">
        <div class="flex items-center mb-5">
          <div class="bg-red-100 rounded-full p-2 mr-3">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 text-red-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
            </svg>
          </div>
          <h3 class="text-xl font-bold text-gray-900">
            <%= render_slot(@title) || "Confirm Action" %>
          </h3>
        </div>
        <div class="mb-6 text-gray-600 pl-11">
          <%= render_slot(@content) || "Are you sure you want to proceed with this action?" %>
        </div>
        <div class="flex justify-end space-x-3">
          <button
            phx-click={@on_cancel}
            class="px-4 py-2 text-gray-700 bg-gray-100 border border-gray-300 rounded-md hover:bg-gray-200 transition-colors duration-200 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-gray-500"
          >
            <%= render_slot(@cancel_button) || "Cancel" %>
          </button>
          <button
            phx-click={@on_confirm}
            class="px-4 py-2 text-white bg-red-500 rounded-md hover:bg-red-700 transition-colors duration-200 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500"
          >
            <%= render_slot(@confirm_button) || "Confirm" %>
          </button>
        </div>
      </div>
    </div>
    """
  end
end
