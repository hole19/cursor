require 'spec_helper'

describe Cursor::Configuration do
  subject(:config) { Cursor.config }

  shared_examples_for 'a configuration parameter' do
    context 'by default' do
      it { expect(config.public_send(config_name)).to eq default_value }
    end

    context 'configured via config block' do
      before do
        Cursor.configure { |c| c.public_send("#{config_name}=", test_value) }
      end

      it { expect(config.public_send(config_name)).to eq test_value }

      after do
        Cursor.configure { |c| c.public_send("#{config_name}=", default_value) }
      end
    end
  end

  describe 'default_per_page' do
    it_behaves_like 'a configuration parameter' do
      let(:config_name)   { :default_per_page }
      let(:default_value) { 25 }
      let(:test_value)    { 17 }
    end
  end

  describe 'max_per_page' do
    it_behaves_like 'a configuration parameter' do
      let(:config_name)   { :max_per_page }
      let(:default_value) { nil }
      let(:test_value)    { 100 }
    end
  end

  describe 'before_param_name' do
    it_behaves_like 'a configuration parameter' do
      let(:config_name)   { :before_param_name }
      let(:default_value) { :before }
      let(:test_value)    { :test }
    end
  end

  describe 'after_param_name' do
    it_behaves_like 'a configuration parameter' do
      let(:config_name)   { :after_param_name }
      let(:default_value) { :after }
      let(:test_value)    { :test }
    end
  end

  describe 'since_param_name' do
    it_behaves_like 'a configuration parameter' do
      let(:config_name)   { :since_param_name }
      let(:default_value) { :since }
      let(:test_value)    { :test }
    end
  end

  describe 'default_paginate_by' do
    it_behaves_like 'a configuration parameter' do
      let(:config_name)   { :default_paginate_by }
      let(:default_value) { :id }
      let(:test_value)    { :test }
    end
  end
end
