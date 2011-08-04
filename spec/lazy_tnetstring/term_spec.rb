require 'spec_helper'

module LazyTNetstring
  describe Term do
    let(:value)  { 'foo' }
    let(:type)   { ',' }
    let(:size)   { value.to_s.length }
    let(:data)   { "#{size}:#{value}#{type}" }
    let(:term)   { LazyTNetstring::Term.new(data, 0) }

    describe '#new' do
      subject { term }

      its(:data)   { should equal(data) }
      its(:length) { should == size }

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

        it { should be_a LazyTNetstring::Parser }
      end

      context 'for undefined types' do
        let(:type)  { '/' }

        it 'raises InvalidTNetString' do
          expect { subject }.to raise_error(LazyTNetstring::InvalidTNetString)
        end
      end
    end

  end
end
