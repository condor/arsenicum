require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))
require 'yaml'

describe Arsenicum::Configuration do

  describe 'initialize and accessor' do

    context 'without args' do
      subject{Arsenicum::Configuration.new}

      specify{subject.is_a? Hash}
      specify{expect(subject).to be_empty}
    end

    context 'with hash arg' do
      subject {
        Arsenicum::Configuration.new test1: 1, 'test2' => 3
      }
      specify{expect(subject.test1).to eq(1)}
      specify{expect(subject.test2).to eq(3)}
      specify 'accessor without the key given on initialization gives empty configuration' do
        expect(subject.test3).to be_kind_of(Arsenicum::Configuration)
      end
    end

    context 'with multi-level hash' do
      subject {
        Arsenicum::Configuration.new test1: 1,
            test2: {
                test3: 40
            }
      }
      specify{expect(subject.test1).to eq(1)}
      specify{expect(subject.test2).to be_kind_of(Arsenicum::Configuration)}
      specify{expect(subject.test2.test3).to eq(40)}
    end

  end

  context :merge do
    let(:base_object) {Arsenicum::Configuration.new test1: 1, test2: {test3: 40}}

    context 'simple merging' do
      subject{base_object.merge test4: 1}
      specify{expect(subject.object_id).not_to eq(base_object.object_id)}
      specify{expect(subject.test1).to eq(base_object.test1)}
      specify{expect(subject.test2).to eq(base_object.test2)}
      specify{expect(subject.test2.test3).to eq(base_object.test2.test3)}
      specify{expect(subject.test4).to eq(1)}
    end

    context 'simple overwriting' do
      subject{base_object.merge test1: 2}
      specify{expect(subject.object_id).not_to eq(base_object.object_id)}
      specify{expect(subject.test1).to eq(2)}
      specify{expect(subject.test2).to eq(base_object.test2)}
      specify{expect(subject.test2.test3).to eq(base_object.test2.test3)}
    end

    context 'deep overwriting' do
      subject{base_object.merge test2: {test4: 50}}
      specify{expect(subject.object_id).not_to eq(base_object.object_id)}
      specify{expect(subject.test1).to eq(1)}
      specify{expect(subject.test2).not_to eq(base_object.test2)}
      specify('merged value case'){
        expect(subject.test2.test3).to eq(base_object.test2.test3)
      }
      specify{expect(subject.test2.test4).to eq(50)}
    end
  end

end
