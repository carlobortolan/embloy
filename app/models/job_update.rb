class JobUpdate
  include Mongoid::Document
  include Mongoid::Timestamps

  field :job_id, type: Integer
  field :user_id, type: Integer
  field :trigger_type, type: String
  field :update_message, type: String
  field :successor, type: JobUpdate
  field :timestamp, type: DateTime

  enum trigger_type: {
    clock_triggered: 1,
    externally_triggered: 2
  }

  after_initialize :setup_change_stream
end
