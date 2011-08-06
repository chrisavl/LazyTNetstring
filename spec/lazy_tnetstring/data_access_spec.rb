require 'spec_helper'

module LazyTNetstring
  describe DataAccess do

    describe '#new' do
      subject           { data_access }
      let(:data_access) { LazyTNetstring::DataAccess.new(data) }

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

        it { should be_an LazyTNetstring::DataAccess }
        its(:data)   { should == data }
        its(:offset) { should == 0 }
      end

      context 'for a hash' do
        let(:data) { TNetstring.dump({'key' => 'value', 'another' => 'value'}) }

        it { should be_an LazyTNetstring::DataAccess }
        its(:data)   { should == data }
        its(:offset) { should == 0 }
      end

      context 'with parent' do
        let(:parent)      { mock('parent DataAccess') }
        let(:data)        { TNetstring.dump({}) }
        let(:data_access) { LazyTNetstring::DataAccess.new(data, 0, parent) }

        it "should add itself to the parent's children" do
          parent.should_receive(:add_child).with(data_access)
        end
      end

      context 'with scope' do
        let(:scope)       { 'outer-key' }
        let(:data)        { TNetstring.dump({}) }
        let(:data_access) { LazyTNetstring::DataAccess.new(data, 0, nil, scope) }

        its(:scope) { should == scope }
      end
    end

    describe '#[]' do
      subject   { LazyTNetstring::DataAccess.new(data)[key]}
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

        it { should be_an LazyTNetstring::DataAccess }
        its(:scoped_data) { should == TNetstring.dump({ 'inner' => 'value'}) }

        it 'should provide access to the inner hash' do
          subject['inner'].should == 'value'
        end
      end
    end

    describe '#[]=(key, new_value)' do
      subject           { data_access[key] = new_value }
      let(:data_access) { LazyTNetstring::DataAccess.new(data) }
      let(:data)        { TNetstring.dump({key => old_value}) }
      let(:key)         { 'foo' }
      let(:old_value)   { 'bar' }
      let(:new_value)   { 'baz' }

      it { should equal(new_value) }

      context 'whithout changing the length' do
        it 'should update the value in its data' do
          subject
          data_access.data.should == data.sub('bar', 'baz')
        end
      end

      context "when changing the length of a top level key's value" do
        let(:data)      { TNetstring.dump({key => old_value}) }
        let(:new_value) { 'x' * 100 }
        let(:new_data)  { TNetstring.dump({key => new_value}) }

        it 'should update the value in its data and adjust lengths accordingly' do
          subject
          data_access.data.should == new_data
          data_access[key].should == new_value
        end
      end

      context "when changing the length of a nested key's value" do
        let(:data)      { TNetstring.dump('outer' => {key => old_value}) }
        let(:new_value) { 'x' * 100 }
        let(:new_data)  { TNetstring.dump('outer' => {key => new_value}) }

        it 'should update the value in its data and adjust lengths accordingly' do
          data_access['outer'][key] = new_value
          data_access.data.should == new_data
          data_access['outer'][key].should == new_value
        end
      end

      context "when changing the a nested key's value without changing the length" do
        let(:data)      { TNetstring.dump('outer' => {key => old_value}) }
        let(:new_value) { 'x' * old_value.length }
        let(:new_data)  { TNetstring.dump('outer' => {key => new_value}) }

        it 'should update the value in its data and adjust lengths accordingly' do
          data_access['outer'][key] = new_value
          data_access.data.should == new_data
          data_access['outer'][key].should == new_value
        end
      end

      context "when changing multiple values on different levels" do
        let(:data)      { TNetstring.dump(key => old_value, 'outer' => {key => old_value}) }
        let(:new_value) { 'x' * 100 }
        let(:new_data)  { TNetstring.dump(key => new_value, 'outer' => {key => new_value}) }

        it 'should update the values in its data and adjust lengths accordingly' do
          data_access['outer'][key] = new_value
          data_access[key] = new_value
          data_access.data.should == new_data
          data_access[key].should == new_value
          data_access['outer'][key].should == new_value
        end
      end

      context "when changing multiple values on different levels while re-using scoped data_accesses" do
        let(:data)      { TNetstring.dump({
                            'key1' => old_value,
                            'outer' => {
                              'key1' => old_value,
                              'key2' => old_value
                            },
                            'key2' => old_value
                          })}
        let(:new_value) { 'x' * 100 }
        let(:new_data)  { TNetstring.dump({
                            'key1' => new_value,
                            'outer' => {
                              'key1' => new_value,
                              'key2' => new_value
                            },
                            'key2' => new_value
                          })}

        it 'should update the values in its data and adjust lengths accordingly' do
          scoped_data_access = data_access['outer']
          scoped_data_access['key1'] = new_value
          scoped_data_access['key2'] = new_value
          data_access['key1'] = new_value
          data_access['key2'] = new_value
          data_access.data.should == new_data
          data_access['key1'].should == new_value
          data_access['key2'].should == new_value
          data_access['outer']['key1'].should == new_value
          data_access['outer']['key2'].should == new_value
        end
      end

      context "when changing multiple interleaved values on different levels while re-using scoped data_accesses" do
        let(:data)      { TNetstring.dump({
                            'key1' => old_value,
                            'outer' => {
                              'key1' => old_value,
                              'key2' => old_value
                            },
                            'key2' => old_value
                          })}
        let(:new_value) { 'x' * 100 }
        let(:new_data)  { TNetstring.dump({
                            'key1' => new_value,
                            'outer' => {
                              'key1' => new_value,
                              'key2' => new_value
                            },
                            'key2' => new_value
                          })}

        it 'should update the values in its data and adjust lengths accordingly' do
          scoped_data_access = data_access['outer']
          data_access['key1'] = new_value
          scoped_data_access['key1'] = new_value
          data_access['key2'] = new_value
          scoped_data_access['key2'] = new_value
          data_access.data.should == new_data
          data_access['key1'].should == new_value
          data_access['key2'].should == new_value
          data_access['outer']['key1'].should == new_value
          data_access['outer']['key2'].should == new_value
        end
      end
    end

  end
end
