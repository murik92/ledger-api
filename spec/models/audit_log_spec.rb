require 'rails_helper'

RSpec.describe AuditLog, type: :model do
  it 'is valid with valid attributes' do
    audit_log = AuditLog.new(
      action: "transfer_created",
      entity_type: "LedgerTransaction",
      entity_id: 1
    )

    expect(audit_log).to be_valid
  end

  it 'is invalid without action' do
    audit_log = AuditLog.new(
      entity_type: "LedgerTransaction",
      entity_id: 1
    )

    expect(audit_log).not_to be_valid
  end

  it 'is invalid without entity_type' do
    audit_log = AuditLog.new(
      action: "transfer_created",
      entity_id: 1
    )

    expect(audit_log).not_to be_valid
  end

  it 'is invalid without entity_id' do
    audit_log = AuditLog.new(
      action: "transfer_created",
      entity_type: "LedgerTransaction"
    )

    expect(audit_log).not_to be_valid
  end
end
