require 'spec_helper'

module LazyTNetstring
  describe Term do
    let(:value)  { 'foo' }
    let(:type)   { ',' }
    let(:size)   { value.to_s.length }
    let(:data)   { "#{size}:#{value}#{type}" }
    let(:offset) { size.to_s.length+1 }
    let(:term)   { LazyTNetstring::Term.new(data, offset, size) }

    describe '#new' do
      subject { term }

      its(:data)   { should equal(data) }
      its(:offset) { should == offset }
      its(:length) { should == size }
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
    end

  end
end
