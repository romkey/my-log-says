# frozen_string_literal: true

# Creates docker_containers for tracking log import state per container.
class CreateDockerContainers < ActiveRecord::Migration[8.1]
  # rubocop:disable Metrics/MethodLength
  def change
    create_table :docker_containers do |t|
      t.string :docker_id, null: false
      t.string :name, null: false
      t.string :image
      t.string :state
      t.boolean :active, null: false, default: true
      t.string :import_status, null: false, default: 'idle'
      t.text :import_error
      t.datetime :last_imported_at
      t.datetime :log_cursor_at

      t.timestamps
    end

    add_index :docker_containers, :docker_id, unique: true
    add_index :docker_containers, :name
    add_index :docker_containers, :active
    add_index :docker_containers, :import_status
  end
  # rubocop:enable Metrics/MethodLength
end
