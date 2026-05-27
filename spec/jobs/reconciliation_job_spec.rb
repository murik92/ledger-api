require 'rails_helper'

RSpec.describe ReconciliationJob, type: :job do
  before(:each) do
    Wallet.delete_all
    Entry.delete_all
    LedgerTransaction.delete_all
    AuditLog.delete_all
    Account.delete_all
  end

  it 'runs reconciliation successfully' do
    expect {
      ReconciliationJob.new.perform
    }.not_to raise_error
  end
end
