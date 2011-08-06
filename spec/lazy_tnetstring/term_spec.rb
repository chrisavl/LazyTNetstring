require 'spec_helper'

module LazyTNetstring
  describe Term do
    let(:value) { 'foo' }
    let(:type)  { ',' }
    let(:size)  { value.to_s.length }
    let(:data)  { "#{size}:#{value}#{type}" }
    let(:term)  { LazyTNetstring::Term.new(data, 0) }

    describe '#new' do
      subject { term }

      its(:data)         { should equal(data) }
      its(:value_length) { should == size }

      context 'for non-tnetstring compliant data' do
        let(:data) { '12345' }

        it 'rejects initialization' do
          expect { subject }.to raise_error(LazyTNetstring::InvalidTNetString)
        end
      end

    end

    describe '#value' do
      subject { term.value }

      context 'for String values' do
        let(:value) { 'foo' }
        let(:type)  { ',' }

        it { should == 'foo' }
      end

      context 'for Integer values' do
        let(:value) { 4711 }
        let(:type)  { '#' }

        it { should == 4711 }
      end

      context 'for Boolean values' do
        let(:type)  { '!' }

        context 'when true' do
          let(:value) { 'true' }
          it { should be_true }
        end

        context 'when false' do
          let(:value) { 'false' }
          it { should be_false }
        end

        context 'when undefined' do
          let(:value) { 'something' }

          it 'raises InvalidTNetString' do
            expect { subject }.to raise_error(LazyTNetstring::InvalidTNetString)
          end
        end
      end

      context 'for Null values' do
        let(:type)  { '~' }
        let(:value) { '' }

        it { should be_nil }
      end

      context 'for List values' do
        let(:type)  { ']' }
        let(:value) { '3:one,2:23#4:true!' }

        it { should == ['one', 23, true] }
      end

      context 'for Dictionary values' do
        let(:type)  { '}' }
        let(:value) { '3:key,5:value' }

        it { should be_a LazyTNetstring::DataAccess }
      end

      context 'for undefined types' do
        let(:type)  { '/' }

        it 'raises InvalidTNetString' do
          expect { subject }.to raise_error(LazyTNetstring::InvalidTNetString)
        end
      end
    end

    describe 'raw_value' do
      subject { term.raw_value }

      it { should == value }
    end

    describe 'value=(new_value)' do
      subject { term }
      let(:new_value) { 1234567890 }
      before( :each ) do
        subject.value = new_value
      end

      its(:value) { should == new_value }
      its(:raw_value) { should == new_value.to_s }
      its(:value_length) { should == 10 }
      its(:value_offset) { should == 3 }
      its(:length) { should == TNetstring.dump(new_value).length }
    end

    describe 'value_length=(new_length)' do
      subject          { term }
      let(:data)       { '1:x,' }
      let(:new_value)  { 'x' * 100 }
      let(:new_length) { 100 }
      before( :each ) do
        subject
        data[2,1] = new_value
        subject.value_length = new_length
      end

      its(:value) { should == new_value }
      its(:raw_value) { should == new_value }
      its(:value_length) { should == 100 }
      its(:value_offset) { should == 4 }
      its(:length) { should == TNetstring.dump(new_value).length }
    end

  end
end
