require 'spec_helper'

module LazyTNetstring
  describe Parser do

    describe '#new' do
      subject { LazyTNetstring::Parser.new(data) }

      context 'for non-tnetstring compliant data' do
        let(:data) { '12345}' }

        it 'rejects initialization' do
          expect { subject }.to raise_error(LazyTNetstring::InvalidTNetString)
        end
      end

      context 'for anything but a hash at the top level' do
        let(:data) { TNetstring.dump(1) }

        it 'rejects initialization' do
          expect { subject }.to raise_error(LazyTNetstring::UnsupportedTopLevelDataStructure)
        end
      end

      context 'for an empty hash' do
        let(:data) { TNetstring.dump({}) }

        it { should be_an LazyTNetstring::Parser }
        its(:data)   { should == data }
        its(:offset) { should == 0 }
        its(:length) { should == data.length }
      end

      context 'for a hash' do
        let(:data) { TNetstring.dump({'key' => 'value', 'another' => 'value'}) }

        it { should be_an LazyTNetstring::Parser }
        its(:data)   { should == data }
        its(:offset) { should == 0 }
        its(:length) { should == data.length }
      end
    end

    describe '#[]' do
      subject   { LazyTNetstring::Parser.new(data)[key]}
      let(:key) { 'foo' }

      context 'for empty hash' do
        let(:data) { TNetstring.dump({}) }
        it { should be_nil }
      end

      context 'for unknown keys' do
        let(:data) { TNetstring.dump({'baz' => 'bar'}) }
        it { should be_nil }
      end

      context 'for known keys' do
        let(:data) { TNetstring.dump({'foo' => 'bar'}) }
        it { should == 'bar' }
      end

      context 'for nested hash' do
        let(:data) { TNetstring.dump({'outer' => { 'inner' => 'value'} }) }
        let(:key)  { 'outer' }

        it { should be_an LazyTNetstring::Parser }
        its(:scoped_data) { should == TNetstring.dump({ 'inner' => 'value'}) }

        it 'should provide access to the inner hash' do
          subject['inner'].should == 'value'
        end
      end
    end

    describe '#[]=(key, new_value)' do
      subject         { parser[key] = new_value }
      let(:parser)    { LazyTNetstring::Parser.new(data) }
      let(:data)      { TNetstring.dump({key => old_value}) }
      let(:key)       { 'foo' }
      let(:old_value) { 'bar' }
      let(:new_value) { 'baz' }

      it { should equal(new_value) }

      context 'whithout changing the length' do
        it 'should update the value in its data' do
          subject
          parser.data.should == data.sub('bar', 'baz')
        end
      end

      context 'when changing the length' do
        let(:data)      { TNetstring.dump({key => old_value}) }
        let(:new_value) { 'quux' }
        let(:new_data)  { TNetstring.dump({key => new_value}) }

        it 'should update the value in its data and adjust lengths accordingly' do
          subject
          parser.data.should == new_data
          parser.length.should == new_data.length
        end
      end
    end

  end
end
