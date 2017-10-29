require 'spec_helper'

if defined? ActiveRecord

  describe Cursor::ActiveRecordModelExtension do
    before do
      Cursor.configure do |config|
        config.page_method_name = :per_page_cursor
      end
      class Comment < ActiveRecord::Base; end
    end

    subject { Comment }
    it { should respond_to(:per_page_cursor) }
    it { should_not respond_to(:page) }

    after do
      Cursor.configure do |config|
        config.page_method_name = :page
      end
    end
  end

  shared_examples_for 'the first after page' do
    its(:size) { should eq(25) }
    its('first.name') { should == 'user001' }
  end

  shared_examples_for 'the first before page' do
    its(:size) { should eq(25) }
    its('first.name') { should == 'user100' }
  end

  shared_examples_for 'blank page' do
    its(:size) { should eq(0) }
  end

  shared_examples_for 'pagination for first before page' do
    it { expect_pagination('before', 76, 100, 100) }
  end

  shared_examples_for 'pagination for first after page' do
    it { expect_pagination('after', 25, 1, 25) }
  end

  def expect_pagination direction, next_cursor, prev_cursor, since_cursor
    reverse_direction = (['after', 'before'] - [direction]).first

    if next_cursor == 0
      expect(subject.key?(:next_url)).to be false
    else
      expect(subject[:next_url]).to    include("#{direction}=#{next_cursor}")
      expect(subject[:next_url].scan(direction).length).to   eq(1)
      expect(subject[:next_url]).to_not    include(reverse_direction, 'since')
    end

    if prev_cursor == 0
      expect(subject.key?(:prev_url)).to be false
    else
      expect(subject[:prev_url]).to    include("#{reverse_direction}=#{prev_cursor}")
      expect(subject[:prev_url].scan(reverse_direction).length).to    eq(1)
      expect(subject[:prev_url]).to_not    include(direction, 'since')
    end

    if since_cursor == 0
      expect(subject.key?(:refresh_url)).to be false
    else
      expect(subject[:refresh_url]).to include("since=#{since_cursor}")
      expect(subject[:refresh_url].scan('since').length).to eq(1)
      expect(subject[:refresh_url]).to_not include('before', 'after')
    end
  end

  describe Cursor::ActiveRecordExtension do
    it 'returns no after cursor when there are no records' do
      params = User.page(after: 0).pagination('http://example.com')
      expect(params.key?(:next_url)).to    be false
      expect(params.key?(:prev_url)).to    be false
      expect(params.key?(:refresh_url)).to be false
      expect(params[:next_cursor]).to  be_nil
      expect(params[:prev_cursor]).to  be_nil
      expect(params[:since_cursor]).to be_nil
    end

    it 'returns no before cursor when there are no records' do
      params = User.page(before: 0).pagination('http://example.com')
      expect(params.key?(:next_url)).to    be false
      expect(params.key?(:prev_url)).to    be false
      expect(params.key?(:refresh_url)).to be false
      expect(params[:next_cursor]).to  be_nil
      expect(params[:prev_cursor]).to  be_nil
      expect(params[:since_cursor]).to be_nil
    end
  end

  describe Cursor::ActiveRecordExtension do
    before :all do
      [User, GemDefinedModel, Device].each do |m|
        1.upto(100) { |i| m.create! name: "user#{'%03d' % i}", age: (i / 10) }
      end
    end
    after :all do
      [User, GemDefinedModel, Device].each(&:delete_all)
    end

    [User, Admin, GemDefinedModel, Device].each do |model_class|
      context "for #{model_class}" do
        describe '#page' do
          context 'page 1 after' do
            subject { model_class.page(after: 0) }
            it_should_behave_like 'the first after page'
          end

          context 'page 1 before' do
            subject { model_class.page(before: 101) }
            it_should_behave_like 'the first before page'
          end

          context 'page 1 since' do
            subject { model_class.page(since: 50) }
            it_should_behave_like 'the first before page'
          end

          context 'page 2 after' do
            subject { model_class.page(after: 25) }
            its(:size) { should eq(25) }
            its('first.name') { should == 'user026' }
          end

          context 'page 2 before' do
            subject { model_class.page(before: 75) }
            its(:size) { should eq(25) }
            its('first.name') { should == 'user074' }
          end

          context 'page without an argument' do
            subject { model_class.page }
            it_should_behave_like 'the first before page'
          end

          context 'after page < -1' do
            subject { model_class.page(after: -1) }
            it_should_behave_like 'the first after page'
          end

          context 'after page > max page' do
            subject { model_class.page(after: 1000) }
            it_should_behave_like 'blank page'
          end

          context 'before page < 0' do
            subject { model_class.page(before: 0) }
            it_should_behave_like 'blank page'
          end

          context 'before page > max page' do
            subject { model_class.page(before: 1000) }
            it_should_behave_like 'the first before page'
          end

          context 'before > since' do
            subject { model_class.page(before: 50, since: 44) }
            its(:size) { should eq(5) }
            its('first.name') { should == 'user049' }
          end

          context 'after > since' do
            subject { model_class.page(after: 50, since: 44) }
            its(:size) { should eq(25) }
            its('first.name') { should == 'user051' }
          end

          context 'after < since' do
            subject { model_class.page(after: 50, since: 95) }
            its(:size) { should eq(5) }
            its('first.name') { should == 'user096' }
          end

          context 'before <= since' do
            subject { model_class.page(before: 50, since: 50) }
            it_should_behave_like 'blank page'
          end

          describe 'ensure #order_values is preserved' do
            subject { model_class.order('id').page }
            its('order_values.uniq') { should == ["#{model_class.table_name}.id desc"] }
          end
        end

        describe '#per' do
          context 'default page per 5' do
            subject { model_class.page.per(5) }
            its(:size) { should eq(5) }
            its('first.name') { should == 'user100' }
          end

          context 'default page per nil (using default)' do
            subject { model_class.page.per(nil) }
            its(:size) { should eq(model_class.default_per_page) }
          end
        end

        describe '#next_cursor' do
          context 'after 1st page' do
            subject { model_class.page(after: 0) }
            its(:next_cursor) { should == 25 }
          end

          context 'after middle page' do
            subject { model_class.page(after: 50) }
            its(:next_cursor) { should == 75 }
          end

          context 'after last page' do
            subject { model_class.page(after: 75) }
            its(:next_cursor) { should == 100 }
          end

          context 'before 1st page' do
            subject { model_class.page }
            its(:next_cursor) { should == 76 }
          end

          context 'before middle page' do
            subject { model_class.page(before: 50) }
            its(:next_cursor) { should == 25 }
          end

          context 'before last page' do
            subject { model_class.page(before: 26) }
            its(:next_cursor) { should == 1 }
          end
        end

        describe '#prev_cursor' do
          context 'after 1st page' do
            subject { model_class.page(after: 0) }
            its(:prev_cursor) { should == 1 }
          end

          context 'after middle page' do
            subject { model_class.page(after: 50) }
            its(:prev_cursor) { should == 51 }
          end

          context 'before 1st page' do
            subject { model_class.page }
            its(:prev_cursor) { should == 100 }
          end

          context 'before middle page' do
            subject { model_class.page(before: 50) }
            its(:prev_cursor) { should == 49 }
          end
        end

        describe '#since_cursor' do
          context 'after 1st page' do
            subject { model_class.page(after: 0) }
            its(:since_cursor) { should == 25 }
          end

          context 'after middle page' do
            subject { model_class.page(after: 50) }
            its(:since_cursor) { should == 75 }
          end

          context 'before 1st page' do
            subject { model_class.page }
            its(:since_cursor) { should == 100 }
          end

          context 'before middle page' do
            subject { model_class.page(before: 50) }
            its(:since_cursor) { should == 49 }
          end
        end

        context 'before page with since' do
          subject { model_class.page(before: 26, since: 20) }
          its(:next_cursor)  { should be_nil }
          its(:since_cursor) { should == 25 }
        end

        context 'after page with since' do
          subject { model_class.page(after: 26, since: 50) }
          its(:next_cursor)  { should == 75 }
          its(:since_cursor) { should == 75 }
        end

        describe '#pagination' do
          context 'before' do
            subject { model_class.page.pagination('http://example.com') }
            it_should_behave_like 'pagination for first before page'
          end

          context 'after' do
            subject { model_class.page(after: 0).pagination('http://example.com') }
            it_should_behave_like 'pagination for first after page'
          end

          context 'since' do
            subject { model_class.page(since: 0).pagination('http://example.com?after=10&before=10') }
            it_should_behave_like 'pagination for first before page'
          end

          context 'before with existing before query param' do
            subject { model_class.page(before: 101).pagination('http://example.com?before=10') }
            it_should_behave_like 'pagination for first before page'
          end

          context 'before with existing after query param' do
            subject { model_class.page(before: 101).pagination('http://example.com?after=10') }
            it_should_behave_like 'pagination for first before page'
          end

          context 'after with existing after query param' do
            subject { model_class.page(after: 0).pagination('http://example.com?after=10') }
            it_should_behave_like 'pagination for first after page'
          end

          context 'after with existing before query param' do
            subject { model_class.page(after: 0).pagination('http://example.com?before=10') }
            it_should_behave_like 'pagination for first after page'
          end

          context 'before with query params' do
            subject { model_class.page.pagination('http://example.com?a[]=one&a[]=two') }
            it_should_behave_like 'pagination for first before page'
            specify { expect(subject[:next_url]).to include('a[]=one&a[]=two') }
          end
        end
      end
    end
  end
end
