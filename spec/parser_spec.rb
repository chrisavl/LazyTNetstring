require 'spec_helper'
require 'parser'
require 'tnetstring'

describe Parser do
  
  describe '#new' do
    subject { Parser.new(data) }
    
    context 'for anything but a hash' do
      let(:data) { TNetstring.dump(1) }
      
      it 'rejects initialization' do
        expect { should }.to raise_error
      end
    end
    
    context 'for an empty hash' do
      let(:data) { TNetstring.dump({}) }
      it { should be_an Parser }
    end
    
    context 'for a hash' do
      let(:data) { TNetstring.dump({'key' => 'value', 'another' => 'value'}) }
      it { should be_an Parser }
    end
  end
  
  describe '#find_key' do
    subject { Parser.new(data).find_key(key) }
    let(:data) { TNetstring.dump({'key1' => 'value1', 'key2' => {'subkey1' => 1, 'subkey2' => 2}}) }
    
    context 'for unknown key' do
      let(:key) { 'unknown' }
      it 'rejects key access' do
        expect { should }.to raise_error
      end
    end
    
    context 'for known key' do
      let(:key) { 'key1' }
      it { should be_a Term }
      its(:offset) { should == 5 }
      its(:length) { should == key.length }
    end
  end
  
  # find_key where value equals key name
  # find_key omits sub-hashes
  # find_key can find beyond nested hashes
  
  describe '#next_term' do
    subject { Parser.new(data).next_term(offset) }
    let(:data) { TNetstring.dump({'key_longer_than_10_chars' => 'value1', 'key2' => {'subkey1' => 1, 'subkey2' => 2}}) }
=begin
76:24:key_longer_than_10_chars,6:value1,4:key2,28:7:subkey1,1:1#7:subkey2,1:2#}}
=end
    
    context 'for first term' do
      let(:offset) { 3 }
      it { should be_a Term }
      its(:offset) { should == 6 }
      its(:length) { should == 24 }
    end
    
    context 'for second term' do
      let(:offset) { 31 }
      its(:offset) { should == 33 }
      its(:length) { should == 6 }
    end
    
    context 'for third term' do
      let(:offset) { 40 }
      its(:offset) { 42 }
      its(:length) { 4 }
    end
  end
  
  describe '#[]' do
    subject { Parser.new(data)[key]}
    let(:key) { 'foo' }
    
    context 'for empty hash' do
      let(:data) { TNetstring.dump({}) }      
      it 'rejects key access' do
        expect { should }.to raise_error
      end
    end
    
    context 'for simple hash' do
      let(:data) { TNetstring.dump({'foo' => 'bar'}) }
      it { should == 'bar' }
    end
    
    # context 'for nested hash' do
    #   let(:data) { TNetstring.dump({'outer' => { 'inner' => 'value'} }) }
    #   let(:key) { 'outer' }
    #   
    #   it { should be_an Parser }
    # end
    
    # provides correct data type of leaf elements
  end
  
end

describe Term do
  
  describe '#value' do
    subject { Term.new(2, 3).value('01234567489') }
    it { should == '234' }
  end
end
