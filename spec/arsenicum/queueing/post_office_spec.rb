require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'spec_helper'))
require 'yaml'

class SampleA;end
class SampleB;end
class Default;end

describe Arsenicum::Queueing::PostOffice do

  subject do
    yaml_path = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'config/post_office_spec.yml'))
    yaml_values = YAML.load(File.read(yaml_path, encoding: 'UTF-8'))
    Arsenicum::Configuration.new(yaml_values['development']).post_office
  end

  describe :deliver_to do
    shared_examples_for :correct_delivery do
      let(:result){subject.queues[queue_name].poll}
      let(:request_object){Arsenicum::Queueing::Request.new request[:target], request[:method], request[:arguments]}

      before{subject.post request_object}

      specify{expect(result).to include(:message_id)}
      specify{expect(result[:message_body]).to eq(request_object.serialize)}
    end

    describe 'class method invocation' do
      context do
        let(:request){
          {
              target: SampleB,
              method: :hoge2,
              arguments: [1]
          }
        }
        let(:queue_name){:sample01}
        it_should_behave_like :correct_delivery
      end
      context '' do
        let(:request){
          {
              target: SampleB,
              method: :hoge1,
              arguments: [1]
          }
        }
        let(:queue_name){:sample_b}
        it_should_behave_like :correct_delivery
      end
      context do
        let(:request){
          {
              target: SampleA,
              method: :hoge1,
              arguments: [1]
          }
        }
        let(:queue_name){:sample_a}
        it_should_behave_like :correct_delivery
      end
      context 'fallback to default' do
        let(:request){
          {
              target: Default,
              method: :hoge1,
              arguments: [1]
          }
        }
        let(:queue_name){:default}
        it_should_behave_like :correct_delivery
      end
    end

    describe 'instance method invocation' do
      context do
        let(:request){
          {
              target: SampleB.new,
              method: :hoge2,
              arguments: [1]
          }
        }
        let(:queue_name){:sample02}
        it_should_behave_like :correct_delivery
      end
      context '' do
        let(:request){
          {
              target: SampleB.new,
              method: :hoge1,
              arguments: [1]
          }
        }
        let(:queue_name){:sample_b}
        it_should_behave_like :correct_delivery
      end
      context do
        let(:request){
          {
              target: SampleA.new,
              method: :hoge1,
              arguments: [1]
          }
        }
        let(:queue_name){:sample01}
        it_should_behave_like :correct_delivery
      end
      context 'fallback to default' do
        let(:request){
          {
              target: Default.new,
              method: :hoge1,
              arguments: [1]
          }
        }
        let(:queue_name){:default}
        it_should_behave_like :correct_delivery
      end
    end
  end
end
