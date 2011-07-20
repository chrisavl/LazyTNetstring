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
    let(:data) { TNetstring.dump({'key1' => 'value1', 'key2' => 'key3', 'key3' => {'subkey1' => 1, 'subkey2' => 2}}) }
=begin
69:4:key1,6:value1,4:key2,4:key3,4:key3,28:7:subkey1,1:1#7:subkey2,1:2#}}
=end

    context 'for unknown key' do
      let(:key) { 'unknown' }
      it 'rejects key access' do
        expect { subject }.to raise_error(KeyNotFoundError)
      end
    end
    
    context 'for known key' do
      let(:key) { 'key2' }
      its(:offset) { should == 21 }
      its(:length) { should == key.length }
    end
    
    context 'where value equals key name' do
      let(:key) { 'key3' }
      its(:offset) { should == 35 }
      its(:length) { should == 4 }
    end
    
    # context 'for key in nested hash' do
    #   let(:key) { 'subkey1' }
    #   it 'rejects key access' do
    #     expect { s }.to raise_error
    #   end
    # end
  end
  
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
    subject { Term.new('01234567489', 2, 3).value }
    it { should == '234' }
  end
end
