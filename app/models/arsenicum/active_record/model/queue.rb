module Arsenicum::ActiveRecord::Model
  class Queue < ActiveRecord::Base
    set_table_name :arsenicum_queues

    default_scope -> {where(abondoned: false)}
    scope :incomplete, -> { where(completed_at: nil) }

    class << self
      def pick
        ActiveRecord::Base.transaction do
          order(updated_at: :asc).incomplete.lock(true).first.try(:tap) do |record|
            record.update_attributes! processing: true, trial_count: record.trial_count + 1
          end
        end
      end

      def finish(queue_id, success)
        ActiveRecord::Base.transaction do
          record = self.class.lock(true).find(queue_id)
          if success
            record.update_attributes! completed_at: Time.current
          else
            record.failed_at =  Time.current
            record.abondoned = (record.trial_count >= limit) # TODO implement limit correctly
            record.save!
          end
        end
      end
    end
  end
end