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
      subject         { LazyTNetstring::DataAccess.new(data) }
      let(:data)      { TNetstring.dump({key => old_value}) }
      let(:key)       { 'foo' }
      let(:old_value) { 'bar' }
      let(:new_value) { 'baz' }

      context 'for single value updates' do
        before( :each ) do
          subject[key] = new_value
        end

        context 'whithout changing the length' do
          its(:data) { should == data.sub('bar', 'baz') }
        end

        context "when changing the length of a top level key's value" do
          let(:data)      { TNetstring.dump({key => old_value}) }
          let(:new_value) { 'x' * 100 }
          let(:new_data)  { TNetstring.dump({key => new_value}) }

          it 'should update the value in its data and adjust lengths accordingly' do
            subject.data.should == new_data
            subject[key].should == new_value
          end
        end
      end

      context "when changing the length of a nested key's value" do
        let(:data)      { TNetstring.dump('outer' => {key => old_value}) }
        let(:new_value) { 'x' * 100 }
        let(:new_data)  { TNetstring.dump('outer' => {key => new_value}) }

        it 'should update the value in its data and adjust lengths accordingly' do
          subject['outer'][key] = new_value
          subject.data.should == new_data
          subject['outer'][key].should == new_value
        end
      end

      context "when changing the a nested key's value without changing the length" do
        let(:data)      { TNetstring.dump('outer' => {key => old_value}) }
        let(:new_value) { 'x' * old_value.length }
        let(:new_data)  { TNetstring.dump('outer' => {key => new_value}) }

        it 'should update the value in its data and adjust lengths accordingly' do
          subject['outer'][key] = new_value
          subject.data.should == new_data
          subject['outer'][key].should == new_value
        end
      end

      context "when changing multiple values on different levels" do
        let(:data)      { TNetstring.dump(key => old_value, 'outer' => {key => old_value}) }
        let(:new_value) { 'x' * 100 }
        let(:new_data)  { TNetstring.dump(key => new_value, 'outer' => {key => new_value}) }

        it 'should update the values in its data and adjust lengths accordingly' do
          subject['outer'][key] = new_value
          subject[key] = new_value
          subject.data.should == new_data
          subject[key].should == new_value
          subject['outer'][key].should == new_value
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
          scoped_data_access = subject['outer']
          scoped_data_access['key1'] = new_value
          scoped_data_access['key2'] = new_value
          subject['key1'] = new_value
          subject['key2'] = new_value
          subject.data.should == new_data
          subject['key1'].should == new_value
          subject['key2'].should == new_value
          subject['outer']['key1'].should == new_value
          subject['outer']['key2'].should == new_value
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
          scoped_data_access = subject['outer']
          subject['key1'] = new_value
          scoped_data_access['key1'] = new_value
          subject['key2'] = new_value
          scoped_data_access['key2'] = new_value
          subject.data.should == new_data
          subject['key1'].should == new_value
          subject['key2'].should == new_value
          subject['outer']['key1'].should == new_value
          subject['outer']['key2'].should == new_value
        end
      end
    end

  end
end
