require 'spec_helper'

module LazyTNetstring
  describe Parser do

    describe '#new' do
      subject { LazyTNetstring::Parser.new(data) }

      context 'for anything but a hash' do
        let(:data) { TNetstring.dump(1) }

        it 'rejects initialization' do
          expect { subject }.to raise_error
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
      subject { LazyTNetstring::Parser.new(data)[key]}
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
        let(:key) { 'outer' }

        it { should be_an LazyTNetstring::Parser }
        its(:hash_data) { should == TNetstring.dump({ 'inner' => 'value'}) }

        it 'should provide access to the inner hash' do
          subject['inner'].should == 'value'
        end
      end
    end

    describe '#find_key' do
      subject { LazyTNetstring::Parser.new(data).send(:find_key, key) }
      let(:data) {
        TNetstring.dump({'key1' => 'value1',
                         'key2' => 'key3',
                         'key3' => {'subkey1' => 1, 'subkey2' => 2},
                         'key4' => 'value4'
                        })
      }
      # data will hold the following tnetstring (WARNING: this relies on
      # Ruby 1.9 ordered hash semantics):
=begin
85:4:key1,6:value1,4:key2,4:key3,4:key3,28:7:subkey1,1:1#7:subkey2,1:2#}4:key4,6:value4,}
=end

      context 'for unknown key' do
        let(:key) { 'unknown' }
        it 'raises KeyNotFoundError' do
          expect { subject }.to raise_error(LazyTNetstring::KeyNotFoundError)
        end
      end

      context 'for known key' do
        let(:key) { 'key2' }
        its(:offset) { should == 21 }
      end

      context 'where value equals key name' do
        let(:key) { 'key3' }
        its(:offset) { should == 35 }
      end

      context 'for a key that is only known in a nested hash' do
        let(:key) { 'subkey1' }
        it 'raises KeyNotFoundError' do
          expect { subject }.to raise_error(LazyTNetstring::KeyNotFoundError)
        end
      end

      context 'for key after nested hash' do
        let(:key) { 'key4' }
        its(:offset) { should == 74 }
      end
    end

    describe '#next_term' do
      subject { LazyTNetstring::Parser.new(data).send(:next_term, offset) }
      let(:data) { TNetstring.dump({'key_longer_than_10_chars' => 'value1',
                                    'key2' => {'subkey1' => 1, 'subkey2' => 2},
                                    'key3' => 'foobar'}) }
      # data will hold the following tnetstring (WARNING: this relies on
      # Ruby 1.9 ordered hash semantics):
=begin
92:24:key_longer_than_10_chars,6:value1,4:key2,28:7:subkey1,1:1#7:subkey2,1:2#}4:key3,6:foobar,}
=end

      context 'for first term' do
        let(:offset) { 3 }
        it { should be_a LazyTNetstring::Term }
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

      context 'for term after nested hash' do
        let(:offset) { 79 }
        its(:offset) { 81 }
        its(:length) { 4 }
      end
    end

  end
end
