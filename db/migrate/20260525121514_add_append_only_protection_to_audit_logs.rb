class AddAppendOnlyProtectionToAuditLogs < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL
      CREATE OR REPLACE FUNCTION prevent_audit_logs_modification()
      RETURNS trigger AS $$
      BEGIN
        RAISE EXCEPTION 'audit_logs is append-only';
      END;
      $$ LANGUAGE plpgsql;
    SQL

    execute <<~SQL
      CREATE TRIGGER prevent_audit_logs_update
      BEFORE UPDATE ON audit_logs
      FOR EACH ROW
      EXECUTE FUNCTION prevent_audit_logs_modification();
    SQL

    execute <<~SQL
      CREATE TRIGGER prevent_audit_logs_delete
      BEFORE DELETE ON audit_logs
      FOR EACH ROW
      EXECUTE FUNCTION prevent_audit_logs_modification();
    SQL
  end

  def down
    execute <<~SQL
      DROP TRIGGER IF EXISTS prevent_audit_logs_update
      ON audit_logs;
    SQL

    execute <<~SQL
      DROP TRIGGER IF EXISTS prevent_audit_logs_delete
      ON audit_logs;
    SQL

    execute <<~SQL
      DROP FUNCTION IF EXISTS
      prevent_audit_logs_modification();
    SQL
  end
end
