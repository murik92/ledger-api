require 'rails_helper'

RSpec.describe ReconciliationJob, type: :job do
  it 'runs reconciliation successfully' do
    expect {
      ReconciliationJob.new.perform
    }.not_to raise_error
  end
end
