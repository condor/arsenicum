require 'date'

require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'spec_helper'))

describe Arsenicum::Queueing::Serializer do
  subject{Object.new.extend(Arsenicum::Queueing::Serializer)}

  describe [:serialize_object, :restore_object] do

    shared_examples_for :serialize_restore do
      specify{expect(subject.restore_object subject.serialize_object worker).to eq(worker)}
    end

    context :target_is_raw do
      shared_examples_for :raw_object do
        specify{expect(subject.serialize_object worker).to eq({type: 'raw', value: worker.inspect})}
        it_should_behave_like :serialize_restore
      end

      context :target_is_integer do
        let(:worker){1}
        it_should_behave_like :raw_object
      end

      context :target_is_float do
        let(:worker){1.3}
        it_should_behave_like :raw_object
      end

      context :target_is_string do
        let(:worker){"string"}
        it_should_behave_like :raw_object
      end

      context :target_is_true do
        let(:worker){true}
        it_should_behave_like :raw_object
      end

      context :target_is_false do
        let(:worker){false}
        it_should_behave_like :raw_object
      end

      context :target_is_nil do
        let(:worker){nil}
        it_should_behave_like :raw_object
      end

    end

    context :time_like do
      shared_examples_for :date_time do
        let(:worker){target_type.now}
        specify{expect(subject.serialize_object worker).to eq({type: 'datetime', value: worker.strftime('%Y-%m-%dT%H:%M:%S %Z %z')})}
        specify{expect(subject.restore_object(subject.serialize_object worker).to_i).to eq(worker.to_time.to_i)}
      end

      context :target_is_datetime do
        let(:target_type){DateTime}
        it_should_behave_like :date_time
      end

      context :target_is_time do
        let(:target_type){Time}
        it_should_behave_like :date_time
      end
    end
  end
end