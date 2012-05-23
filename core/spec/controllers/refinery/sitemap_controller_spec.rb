require 'spec_helper'

module Refinery
  describe SitemapController do
    before (:each) do
      @request.env['HTTP_ACCEPT'] = 'application/xml'
    end

    it "should show a valid xml answer with i18n enabled" do
      Refinery.stub(:i18n_enabled?) { true }
      Refinery::I18n.stub(:frontend_locales) { :en }
      
      get :index

      response.should be_success
    end

    it "should show a valid xml answer with i18n disabled" do
      Refinery.stub(:i18n_enabled?) { false }

      get :index

      response.should be_success
    end

  end
end
