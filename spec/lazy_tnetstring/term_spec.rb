require 'spec_helper'

module LazyTNetstring
  describe Term do

    describe '#value' do
      subject { LazyTNetstring::Term.new('01234567489', 2, 3).value }
      it { should == '234' }
    end

  end
end
