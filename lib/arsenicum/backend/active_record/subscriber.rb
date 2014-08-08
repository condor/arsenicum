class Arsenicum::Backend::ActiveRecord
  class Subscriber < Arsenicum::Backend::Subscriber
    include Arsenicum::Serializer

    def self.blocking?
      false
    end

    def pick
      Arsenicum::ActiveRecord::Model::Queue.transaction do
        while record = Arsenicum::ActiveRecord::Model::Queue.incomplete.order(created_at: :desc).first
          begin
            record = Arsenicum::ActiveRecord::Model::Queue.lock(true).incomplete.find(record)
          rescue ActiveRecord::RecordNotFound
            next
          end
          return Arsenicum::Request.new \
            target: restore_object(record.target), method_name: record.method_name,
            arguments: restore_object(record.arguments), timestamp: record.timestamp, id: record.id
        end
      end
    end

    def complete(request)
      Arsenicum::ActiveRecord::Model::Queue.transaction do
        record = Arsenicum::ActiveRecord::Model::Queue.lock(true).find(request.id)
        record.update_attributes! processing: false, complete: true
      end
    end
  end
end
