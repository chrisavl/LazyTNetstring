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
      it { should be_a Location }
      its(:offset) { should == 5 }
      its(:length) { should == key.length }
    end
  end
  
  # find_key where value equals key name
  # find_key omits sub-hashes
  # find_key can find beyond nested hashes
  
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