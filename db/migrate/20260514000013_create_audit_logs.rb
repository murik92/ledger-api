class CreateAuditLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :audit_logs do |t|
      t.string :action, null: false
      t.string :entity_type, null: false
      t.bigint :entity_id, null: false

      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :audit_logs, :action
    add_index :audit_logs, [:entity_type, :entity_id]
  end
end