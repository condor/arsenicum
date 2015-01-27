module Arsenicum::Backend
  class ActiveRecord

    attr_reader   :auto_retry
    alias_method  :auto_retry?, :auto_retry

    def put
    end

    def pick_blocking?
      false
    end

    def pick
      job =
          if auto_retry?
            Job.first
          else
            Job.undone.first
          end
      job.with_lock do
        return unless job.undone?
        job.processing!
      end
      job
    end

    def pick_failure
      job = Job.failed.first
      job.with_lock do
        return if job.processing?
        job.processing!
      end
      job
    end

    def handle_success(job)
      job.destroy
    end

    def handle_failure(job, cause)
      job.with_lock do
        job.save_failure! cause: cause
      end
    end

    class Job < ActiveRecord::Base
      self.table_name = 'arsenicum_jobs'

      STATE_VALUES = {undone: 0, processing: 40, failed: 99}

      if ActiveRecord::VERSION::MAJOR >= 4 && ActiveRecord::VERSION::MINOR >= 1
        enum state: STATE_VALUES
      else
        STATE_VALUES.each do |state, state_value|
          scope state, -> { where(state: state_value) }
          eval <<-STATEMENT, __FILE__, __LINE__ + 1
          def #{state}?
            state == #{state_value}
          end
          STATEMENT
        end
      end

      default_scope -> { order(queued_at: :asc) }

      def save_failure!(cause:)
        job.update_attributes! state: STATE_VALUES[:failed], cause: exception_to_s(cause), raw_cause: Marshal.dump(cause)
      end

      def exception_to_s(exception)
        [exception.to_s, exception.backtrace.map{|bt|"at\t#{bt}"}].tap(&:flatten).join("\n")
      end
    end
  end
end
